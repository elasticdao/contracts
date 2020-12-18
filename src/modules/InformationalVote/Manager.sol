// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './models/Ballot.sol';
import './models/Settings.sol';
import './models/Vote.sol';

import '../../interfaces/IElasticToken.sol';
import '../../libraries/ElasticMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for interacting with informational votes
/// @dev ElasticDAO network contracts can read/write from this contract
contract InformationalVoteManager {
  address public ballotModelAddress;
  address public settingsModelAddress;
  address public voteModelAddress;
  bool public initialized;

  event CreateVote(uint256 index);

  constructor(
    address _ballotModelAddress,
    address _settingsModelAddress,
    address _voteModelAddress
  ) {
    ballotModelAddress = _ballotModelAddress;
    initialized = false;
    settingsModelAddress = _settingsModelAddress;
    voteModelAddress = _voteModelAddress;
  }

  /**
   * @dev Initializes the InformationalVote Manager
   * @param _votingTokenAddress - the address of the voting Token
   * @param _hasPenalty - whether the vote has a penalty or not
   * @param _settings - an array of all the vote related settings
   */
  function initialize(
    address _votingTokenAddress,
    bool _hasPenalty,
    uint256[10] memory _settings
  ) external {
    require(initialized == false, 'ElasticDAO: Informational Vote Manager already initialized.');
    InformationalVoteSettings settingsContract = InformationalVoteSettings(settingsModelAddress);
    InformationalVoteSettings.Instance memory settings;
    settings.managerAddress = address(this);
    settings.votingTokenAddress = _votingTokenAddress;
    settings.hasPenalty = _hasPenalty;
    settings.approval = _settings[0];
    settings.counter = 0;
    settings.maxSharesPerTokenHolder = _settings[1];
    settings.minBlocksForPenalty = _settings[2];
    settings.minDurationInBlocks = _settings[3];
    settings.minPenaltyInShares = _settings[4];
    settings.minRewardInShares = _settings[5];
    settings.minSharesToCreate = _settings[6];
    settings.penalty = _settings[7];
    settings.quorum = _settings[8];
    settings.reward = _settings[9];
    settingsContract.serialize(settings);
    initialized = true;
  }

  /**
   * @dev Applies penalties to @param _addressesToPenalize
   * @param _index - ID of the specific vote
   * @param _addressesToPenalize - An array of all the addresses to be penalized
   *
   * The function does the following checks:
   *   Whether the @param _index is a valid vote ID
   *   Whether the vote has already passed or not
   *   Whether the vote is currently active
   *   Whether the vote has reached quoroum or not
   *   Whether the InformationalVote has a penalty or not
   *
   * Penalization -
   *   VotePenalty - The penalty on the vote
   *   balanceOfInShares - The amount of shares owned by a specific address
   *   DeltaLambda - The change in the number of shares
   *   Delatalambda = balanceOfInShares * VotePenalty
   *
   *   Summary of penalization - Delatalambda is calculated, and those many shares are burnt
   *                             for the specific account
   *
   * Summary:  If the vote has a valid ID, isApproved, isActive, has NOT reached quoroum,
   *           has a penalty on it then the @param _addressesToPenalize are penalized
   *
   */
  function applyPenalty(uint256 _index, address[] memory _addressesToPenalize) external {
    InformationalVoteSettings.Instance memory settings = _getSettings();
    require(_voteExists(_index, settings), 'ElasticDAO: Invalid vote id.');
    InformationalVote.Instance memory vote = _getVote(_index, settings);
    require(vote.isApproved == false, 'ElasticDAO: Cannot penalize a vote that passed.');
    require(vote.isActive == false, 'ElasticDAO: Cannot penalize an active vote.');
    require(
      vote.hasReachedQuorum == false,
      'ElasticDAO: Cannot penalize a vote that has reached quorum.'
    );
    require(vote.hasPenalty, 'ElasticDAO: This vote has no penalty.');
    InformationalVoteBallot ballotContract = InformationalVoteBallot(ballotModelAddress);
    IElasticToken tokenContract = IElasticToken(vote.votingTokenAddress);

    for (uint256 i = 0; i < _addressesToPenalize.length; i = SafeMath.add(i, 1)) {
      if (ballotContract.exists(_addressesToPenalize[i], settings, vote) == false) {
        InformationalVoteBallot.Instance memory ballot;
        ballot.voter = _addressesToPenalize[i];
        ballot.settings = settings;
        ballot.vote = vote;
        ballot.wasPenalized = true;
        uint256 deltaLambda = ElasticMath.wmul(
          tokenContract.balanceOfInShares(_addressesToPenalize[i]),
          vote.penalty
        );
        ballot.lambda = deltaLambda;
        ballotContract.serialize(ballot);
        tokenContract.burnShares(_addressesToPenalize[i], deltaLambda);
      }
    }
  }

  /**
   * @dev casts the vote ballot
   * @param _index - the ID of the vote
   * @param _yna - YesNoAbstain value - 0 for Yes, 1 for No, 2 for abstain
   * votingLambda - The current number of shares the voter has
   * lambdaAtStartingBlock - the number of shares the voter has on vote creation
   *
   * Essentially, by comparing lambdaAtStartingBlock and votingLambda,
   * a voter is only allowed to vote with the number of shares they had when the vote was created,
   * and if the number of shares exceeds the maximum number of shares per token holder,
   * voter can only vote with the maximum number of shares per token holder,
   */
  function castBallot(uint256 _index, uint256 _yna) external {
    InformationalVoteSettings.Instance memory settings = _getSettings();
    require(_voteExists(_index, settings), 'ElasticDAO: Invalid vote id.');
    InformationalVote.Instance memory vote = _getVote(_index, settings);
    require(vote.isActive, 'ElasticDAO: InformationalVote is not active or has ended.');
    require(_voteNotExpired(vote), 'ElasticDAO: InformationalVote is not active or has ended.');
    require(_yna < 3, 'ElasticDAO: Invalid _yna value. Use 0 for yes, 1 for no, 2 for abstain.');
    IElasticToken tokenContract = IElasticToken(vote.votingTokenAddress);

    uint256 votingLambda = tokenContract.balanceOfInShares(msg.sender);
    uint256 lambdaAtStartingBlock = tokenContract.balanceOfInSharesAt(
      msg.sender,
      vote.startOnBlock
    );
    if (lambdaAtStartingBlock < votingLambda) {
      votingLambda = lambdaAtStartingBlock;
    }
    if (vote.maxSharesPerTokenHolder < votingLambda) {
      votingLambda = vote.maxSharesPerTokenHolder;
    }

    InformationalVoteBallot.Instance memory existingBallot = InformationalVoteBallot(
      ballotModelAddress
    )
      .deserialize(msg.sender, settings, vote);

    if (existingBallot.lambda > 0) {
      if (existingBallot.yna == 0) {
        vote.yesLambda = SafeMath.sub(vote.yesLambda, existingBallot.lambda);
      } else if (existingBallot.yna == 1) {
        vote.noLambda = SafeMath.sub(vote.noLambda, existingBallot.lambda);
      } else {
        vote.abstainLambda = SafeMath.sub(vote.abstainLambda, existingBallot.lambda);
      }
    }

    if (_yna == 0) {
      vote.yesLambda = SafeMath.add(vote.yesLambda, votingLambda);
    } else if (_yna == 1) {
      vote.noLambda = SafeMath.add(vote.noLambda, votingLambda);
    } else {
      vote.abstainLambda = SafeMath.add(vote.abstainLambda, votingLambda);
    }

    uint256 lambda = SafeMath.add(SafeMath.add(vote.yesLambda, vote.noLambda), vote.abstainLambda);
    vote.isApproved = false;
    if (lambda >= vote.quorumLambda) {
      vote.hasReachedQuorum = true;

      if (vote.yesLambda >= vote.approvalLambda) {
        vote.isApproved = true;
      }
    }

    InformationalVoteBallot.Instance memory ballot;
    ballot.lambda = votingLambda;
    ballot.settings = settings;
    ballot.vote = vote;
    ballot.voter = msg.sender;
    ballot.yna = _yna;

    InformationalVoteBallot(ballotModelAddress).serialize(ballot);
    InformationalVote(voteModelAddress).serialize(vote);

    if (existingBallot.lambda == 0) {
      tokenContract.mintShares(msg.sender, ElasticMath.wmul(votingLambda, vote.reward));
    }
  }

  /**
   * @dev Creates the vote
   * @param _proposal - the vote proposal
   * @param _endOnBlock - the block on which the vote ends
   *
   * The vote manager should be initialized prior to creating the vote
   * The vote creator must have the minimum number of votes required to create a vote
   * The vote duration cannot be lesser than the minimum duration of a vote
   *
   * @return uint256 - the InformationalVote ID
   */
  function createVote(string memory _proposal, uint256 _endOnBlock) external returns (uint256) {
    require(initialized, 'ElasticDAO: InformationalVote Manager not initialized');
    InformationalVoteSettings.Instance memory settings = _getSettings();
    IElasticToken tokenContract = IElasticToken(settings.votingTokenAddress);
    require(
      tokenContract.balanceOfInShares(msg.sender) >= settings.minSharesToCreate,
      'ElasticDAO: Not enough shares to create vote'
    );
    require(
      SafeMath.sub(_endOnBlock, block.number) >= settings.minDurationInBlocks,
      'ElasticDAO: InformationalVote period too short'
    );

    InformationalVote voteContract = InformationalVote(voteModelAddress);
    InformationalVote.Instance memory vote;
    vote.settings = settings;
    vote.author = msg.sender;
    vote.hasPenalty = settings.hasPenalty;
    vote.hasReachedQuorum = false;
    vote.isActive = true;
    vote.isApproved = false;
    vote.proposal = _proposal;
    vote.abstainLambda = 0;
    vote.approval = 0;
    vote.endOnBlock = _endOnBlock;
    vote.index = settings.counter;
    vote.maxSharesPerTokenHolder = settings.maxSharesPerTokenHolder;
    vote.minBlocksForPenalty = settings.minBlocksForPenalty;
    vote.noLambda = 0;
    vote.penalty = settings.penalty;
    vote.quorum = settings.quorum;

    uint256 maxVotingShares = ElasticMath.wmul(
      tokenContract.numberOfTokenHolders(),
      settings.maxSharesPerTokenHolder
    );
    uint256 totalSupplyInShares = tokenContract.totalSupplyInShares();
    if (totalSupplyInShares < maxVotingShares) {
      vote.quorumLambda = ElasticMath.wmul(totalSupplyInShares, settings.quorum);
      vote.approvalLambda = ElasticMath.wmul(totalSupplyInShares, settings.approval);
    } else {
      vote.quorumLambda = ElasticMath.wmul(maxVotingShares, settings.quorum);
      vote.approvalLambda = ElasticMath.wmul(maxVotingShares, settings.approval);
    }

    vote.reward = settings.reward;
    vote.startOnBlock = block.number;
    vote.votingTokenAddress = settings.votingTokenAddress;
    vote.yesLambda = 0;
    voteContract.serialize(vote);
    InformationalVoteSettings(settingsModelAddress).incrementCounter(address(this));

    emit CreateVote(vote.index);
  }

  function getSettings() external view returns (InformationalVoteSettings.Instance memory) {
    return _getSettings();
  }

  // Private

  function _getSettings() internal view returns (InformationalVoteSettings.Instance memory) {
    return InformationalVoteSettings(settingsModelAddress).deserialize(address(this));
  }

  function _getVote(uint256 _index, InformationalVoteSettings.Instance memory _settings)
    internal
    view
    returns (InformationalVote.Instance memory)
  {
    return InformationalVote(voteModelAddress).deserialize(_index, _settings);
  }

  function _voteExists(uint256 _index, InformationalVoteSettings.Instance memory _settings)
    internal
    view
    returns (bool)
  {
    return InformationalVote(voteModelAddress).exists(_index, _settings);
  }

  function _voteNotExpired(InformationalVote.Instance memory vote) internal returns (bool) {
    if (vote.endOnBlock <= block.number) {
      vote.isActive = false;
      InformationalVote(voteModelAddress).serialize(vote);
      return false;
    }

    return true;
  }
}
