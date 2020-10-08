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
   * @param _votingToken - the address of the voting Token
   * @param _hasPenalty - whether the vote has a penalty or not
   * @param _settings - an array of all the vote related settings
   */
  function initialize(
    address _votingToken,
    bool _hasPenalty,
    uint256[8] memory _settings
  ) external {
    require(initialized == false, 'ElasticDAO: Informational Vote Manager already initialized.');
    InformationalVoteSettings settingsContract = InformationalVoteSettings(settingsModelAddress);
    InformationalVoteSettings.Instance memory settings;
    settings.uuid = address(this);
    settings.votingToken = _votingToken;
    settings.hasPenalty = _hasPenalty;
    settings.approval = _settings[0];
    settings.counter = 0;
    settings.maxSharesPerTokenHolder = _settings[1];
    settings.minBlocksForPenalty = _settings[2];
    settings.minDurationInBlocks = _settings[3];
    settings.minSharesToCreate = _settings[4];
    settings.penalty = _settings[5];
    settings.quorum = _settings[6];
    settings.reward = _settings[7];
    settingsContract.serialize(settings);
    initialized = true;
  }

  /**
   * @dev Applies penalties to @param _addressesToPenalize
   * @param _id - ID of the specific vote
   * @param _addressesToPenalize - An array of all the addresses to be penalized
   *
   * The function does the following checks:
   *   Whether the @param _id is a valid vote ID
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
  function applyPenalty(uint256 _id, address[] memory _addressesToPenalize) external {
    require(_voteExists(_id), 'ElasticDAO: Invalid vote id.');
    InformationalVote.Instance memory vote = _getVote(_id);
    require(vote.isApproved == false, 'ElasticDAO: Cannot penalize a vote that passed.');
    require(vote.isActive == false, 'ElasticDAO: Cannot penalize an active vote.');
    require(
      vote.hasReachedQuorum == false,
      'ElasticDAO: Cannot penalize a vote that has reached quorum.'
    );
    require(vote.hasPenalty, 'ElasticDAO: This vote has no penalty.');
    InformationalVoteBallot ballotContract = InformationalVoteBallot(ballotModelAddress);
    IElasticToken tokenContract = IElasticToken(vote.votingToken);

    for (uint256 i = 0; i < _addressesToPenalize.length; i = SafeMath.add(i, 1)) {
      if (ballotContract.exists(address(this), _id, _addressesToPenalize[i]) == false) {
        InformationalVoteBallot.Instance memory ballot;
        ballot.uuid = address(this);
        ballot.voteId = vote.id;
        ballot.voter = _addressesToPenalize[i];
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
    require(initialized, 'ElasticDAO: InformationalVote Manager not initialized.');
    InformationalVoteSettings.Instance memory settings = _getSettings();
    IElasticToken tokenContract = IElasticToken(settings.votingToken);
    require(
      tokenContract.balanceOfInShares(msg.sender) >= settings.minSharesToCreate,
      'ElasticDAO: Not enough shares to create vote.'
    );
    require(
      SafeMath.sub(_endOnBlock, block.number) >= settings.minDurationInBlocks,
      'ElasticDAO: InformationalVote period too short.'
    );

    InformationalVote voteContract = InformationalVote(voteModelAddress);
    InformationalVote.Instance memory vote;
    vote.uuid = address(this);
    vote.author = msg.sender;
    vote.hasPenalty = settings.hasPenalty;
    vote.hasReachedQuorum = false;
    vote.isActive = true;
    vote.isApproved = false;
    vote.proposal = _proposal;
    vote.abstainLambda = 0;
    vote.approval = 0;
    vote.endOnBlock = _endOnBlock;
    vote.id = settings.counter;
    vote.maxSharesPerTokenHolder = settings.maxSharesPerTokenHolder;
    vote.minBlocksForPenalty = settings.minBlocksForPenalty;
    vote.noLambda = 0;
    vote.penalty = settings.penalty;
    vote.quorum = settings.quorum;
    vote.reward = settings.reward;
    vote.startOnBlock = block.number;
    vote.votingToken = settings.votingToken;
    vote.yesLambda = 0;
    voteContract.serialize(vote);
    InformationalVoteSettings(settingsModelAddress).incrementCounter(address(this));
    return vote.id;
  }

  /**
   * @dev casts the vote ballot
   * @param _id - the ID of the vote
   * @param _yna - YesNoAbstain value - 0 for Yes, 1 for No, 2 for abstain
   * votingLambda - The current number of shares the voter has
   * lambdaAtStartingBlock - the number of shares the voter has on vote creation
   *
   * Essentially, by comparing lambdaAtStartingBlock and votingLambda,
   * a voter is only allowed to vote with the number of shares they had when the vote was created,
   * and if the number of shares exceeds the maximum number of shares per token holder,
   * voter can only vote with the maximum number of shares per token holder,
   */
  function castBallot(uint256 _id, uint256 _yna) external {
    require(_voteExists(_id), 'ElasticDAO: Invalid vote id.');
    InformationalVote.Instance memory vote = _getVote(_id);
    require(vote.isApproved == false, 'ElasticDAO: InformationalVote has already been approved.');
    require(vote.isActive, 'ElasticDAO: InformationalVote is not active or has ended.');
    require(_voteNotExpired(vote), 'ElasticDAO: InformationalVote is not active or has ended.');
    require(_yna < 3, 'ElasticDAO: Invalid _yna value. Use 0 for yes, 1 for no, 2 for abstain.');
    IElasticToken tokenContract = IElasticToken(vote.votingToken);

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

    if (_yna == 0) {
      vote.yesLambda = SafeMath.add(vote.yesLambda, votingLambda);
    } else if (_yna == 1) {
      vote.noLambda = SafeMath.add(vote.noLambda, votingLambda);
    } else {
      vote.abstainLambda = SafeMath.add(vote.abstainLambda, votingLambda);
    }

    uint256 lambda = SafeMath.add(SafeMath.add(vote.yesLambda, vote.noLambda), vote.abstainLambda);
    uint256 tokenLambda = tokenContract.totalSupplyInShares();
    uint256 quorumLambda = ElasticMath.wmul(tokenLambda, vote.quorum);
    if (lambda >= quorumLambda) {
      vote.hasReachedQuorum = true;
    }

    uint256 approvalLambda = ElasticMath.wmul(tokenLambda, vote.approval);
    if (lambda >= approvalLambda) {
      vote.isApproved = true;
    }

    InformationalVoteBallot.Instance memory ballot;
    ballot.uuid = address(this);
    ballot.voteId = vote.id;
    ballot.voter = msg.sender;
    ballot.lambda = votingLambda;
    ballot.yna = _yna;

    InformationalVoteBallot(ballotModelAddress).serialize(ballot);
    InformationalVote(voteModelAddress).serialize(vote);

    tokenContract.mintShares(msg.sender, ElasticMath.wmul(votingLambda, vote.reward));
  }

  function _getBallot(uint256 _id, address _voter)
    internal
    view
    returns (InformationalVoteBallot.Instance memory)
  {
    return InformationalVoteBallot(ballotModelAddress).deserialize(address(this), _id, _voter);
  }

  function _getSettings() internal view returns (InformationalVoteSettings.Instance memory) {
    return InformationalVoteSettings(settingsModelAddress).deserialize(address(this));
  }

  function _getVote(uint256 _id) internal view returns (InformationalVote.Instance memory) {
    return InformationalVote(voteModelAddress).deserialize(address(this), _id);
  }

  function _voteExists(uint256 _id) internal view returns (bool) {
    return InformationalVote(voteModelAddress).exists(address(this), _id);
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
