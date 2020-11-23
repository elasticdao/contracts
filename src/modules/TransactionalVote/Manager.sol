// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './models/Ballot.sol';
import './models/Settings.sol';
import './models/Vote.sol';

import '../../interfaces/IElasticToken.sol';
import '../../libraries/ElasticMath.sol';
import '../../libraries/SecuredTokenTransfer.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for interacting with informational votes
/// @dev ElasticDAO network contracts can read/write from this contract
contract TransactionalVoteManager {
  //keccak256(
  //    "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
  //);
  bytes32
    private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;
  //keccak256(
  //    "EIP712Domain(address verifyingContract)"
  //);
  bytes32
    private constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

  event CreateVote(uint256 index);
  event ExecutionFailure(bytes32 txHash, uint256 payment);
  event ExecutionSuccess(bytes32 txHash, uint256 payment);

  enum Operation { Call, DelegateCall }

  address public ballotModelAddress;
  address public settingsModelAddress;
  address public voteModelAddress;
  bool public initialized;
  uint256 public nonce;
  bytes32 public domainSeparator;

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
   * @dev Initializes the TransactionalVote Manager
   * @param _votingToken - the address of the voting Token
   * @param _hasPenalty - whether the vote has a penalty or not
   * @param _settings - an array of all the vote related settings
   */
  function initialize(
    address _votingToken,
    bool _hasPenalty,
    uint256[10] memory _settings
  ) external {
    require(initialized == false, 'ElasticDAO: Transactional Vote Manager already initialized.');
    TransactionalVoteSettings settingsContract = TransactionalVoteSettings(settingsModelAddress);
    TransactionalVoteSettings.Instance memory settings;
    settings.uuid = address(this);
    settings.votingToken = _votingToken;
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
    domainSeparator = keccak256(abi.encode(DOMAIN_DEPARATOR_TYPEHASH, this));

    // IElasticToken(_votingToken).subscribeToShareUpdates(address(this));
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
   *   Whether the TransactionalVote has a penalty or not
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
    require(_voteExists(_index), 'ElasticDAO: Invalid vote id.');
    TransactionalVote.Instance memory vote = _getVote(_index);
    require(vote.isApproved == false, 'ElasticDAO: Cannot penalize a vote that passed.');
    require(vote.isActive == false, 'ElasticDAO: Cannot penalize an active vote.');
    require(
      vote.hasReachedQuorum == false,
      'ElasticDAO: Cannot penalize a vote that has reached quorum.'
    );
    require(vote.hasPenalty, 'ElasticDAO: This vote has no penalty.');
    TransactionalVoteBallot ballotContract = TransactionalVoteBallot(ballotModelAddress);
    IElasticToken tokenContract = IElasticToken(vote.votingToken);

    for (uint256 i = 0; i < _addressesToPenalize.length; i = SafeMath.add(i, 1)) {
      if (ballotContract.exists(address(this), _index, _addressesToPenalize[i]) == false) {
        TransactionalVoteBallot.Instance memory ballot;
        ballot.uuid = address(this);
        ballot.voteId = vote.index;
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
   * @return uint256 - the TransactionalVote ID
   */
  function createVote(string memory _proposal, uint256 _endOnBlock) external returns (uint256) {
    require(initialized, 'ElasticDAO: TransactionalVote Manager not initialized');
    TransactionalVoteSettings.Instance memory settings = _getSettings();
    IElasticToken tokenContract = IElasticToken(settings.votingToken);
    require(
      tokenContract.balanceOfInShares(msg.sender) >= settings.minSharesToCreate,
      'ElasticDAO: Not enough shares to create vote'
    );
    require(
      SafeMath.sub(_endOnBlock, block.number) >= settings.minDurationInBlocks,
      'ElasticDAO: TransactionalVote period too short'
    );

    TransactionalVote voteContract = TransactionalVote(voteModelAddress);
    TransactionalVote.Instance memory vote;
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
    vote.index = settings.counter;
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
    TransactionalVoteSettings(settingsModelAddress).incrementCounter(address(this));

    emit CreateVote(vote.index);
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
    require(_voteExists(_index), 'ElasticDAO: Invalid vote id.');
    TransactionalVote.Instance memory vote = _getVote(_index);
    require(vote.isApproved == false, 'ElasticDAO: TransactionalVote has already been approved.');
    require(vote.isActive, 'ElasticDAO: TransactionalVote is not active or has ended.');
    require(_voteNotExpired(vote), 'ElasticDAO: TransactionalVote is not active or has ended.');
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

    TransactionalVoteBallot.Instance memory ballot;
    ballot.uuid = address(this);
    ballot.voteId = vote.index;
    ballot.voter = msg.sender;
    ballot.lambda = votingLambda;
    ballot.yna = _yna;

    TransactionalVoteBallot(ballotModelAddress).serialize(ballot);
    TransactionalVote(voteModelAddress).serialize(vote);

    tokenContract.mintShares(msg.sender, ElasticMath.wmul(votingLambda, vote.reward));
  }

  function getSettings() external view returns (TransactionalVoteSettings.Instance memory) {
    return _getSettings();
  }

  /**
   * @dev executes arbitrary transaction when safe abi function signature is passed into data. Based on Gnosis Safe.
   * @param _to - Destination address of Safe transaction.
   * @param _value - Ether value of Safe transaction.
   * @param _data - Data payload of Safe transaction.
   * @param _safeTxGas - Gas that should be used for the Safe transaction.
   * @param _baseGas - Gas costs for that are indipendent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
   * @param _gasPrice - Gas price that should be used for the payment calculation.
   * @param _gasToken - Token address (or 0 if ETH) that is used for the payment.
   * @param _refundReceiver - Address of receiver of gas payment (or 0 if tx.origin).
   * @return success bool
   */
  // TODO: SHOULD BE LOCKED DOWN TO ONLY VOTE MODULES
  function _executeTransaction(
    address _to,
    uint256 _value,
    bytes calldata _data,
    Operation _operation,
    uint256 _safeTxGas,
    uint256 _baseGas,
    uint256 _gasPrice,
    address _gasToken,
    address _refundReceiver
  ) internal view returns (bool success) {
    bytes32 txHash;
    // use scope to limit variable lifetime and prevent `stack to deep` errors
    {
      bytes memory txHashData = _encodeTransactionData(
        _to,
        _value,
        _data,
        _operation,
        _safeTxGas,
        _baseGas,
        _gasPrice,
        _gasToken,
        _refundReceiver
      );

      // increment nonce
      SafeMath.add(nonce, 1);
      // hash transaction data
      txHash = keccak256(txHashData);
    }

    // We require some gas to emit the events (at least 2500) after the execution and some to perform code until the execution (500)
    // We also include the 1/64 in the check that is not send along with a call to counteract potential shortings because of EIP-150
    require(
      gasleft() >= ((_safeTxGas * 64) / 63).max(_safeTxGas + 2500) + 500,
      'ElasticDAO: Not enough gas to execute safe transaction'
    );

    // use scope to limit variable lifetime and prevent `stack to deep` errors
    {
      uint256 gasUsed = gasleft();
      // If the gasPrice is 0 we assume that nearly all available gas can be used (it is always more than safeTxGas)
      // We only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still higher than safeTxGas
      success = execute(
        _to,
        _value,
        _data,
        _operation,
        gasPrice == 0 ? (gasleft() - 2500) : _safeTxGas
      );
      gasUsed = gasUsed.sub(gasleft());

      // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
      uint256 payment = 0;
      if (_gasPrice > 0) {
        payment = _handlePayment(gasUsed, _baseGas, _gasPrice, _gasToken, _refundReceiver);
      }

      if (success) {
        emit ExecutionSuccess(txHash, payment);
      } else {
        emit ExecutionFailure(txHash, payment);
      }
    }
  }

  function _handlePayment(
    uint256 _gasUsed,
    uint256 _baseGas,
    uint256 _gasPrice,
    address _gasToken,
    address payable _refundReceiver
  ) private returns (uint256 payment) {
    address payable receiver = _refundReceiver == address(0) ? _gasPrice : tx.gasprice;

    if (_gasToken == address(0)) {
      // For ETH we will only adjust the gas price to not be higher than the actual used gas price
      payment = _gasUsed.add(_baseGas).mul(_gasPrice < tx.gasprice ? _gasPrice : tx.gasprice);

      require(receiver.send(payment, 'Elastic DAO: Could not pay gas costs with token'));
    } else {
      payment = _gasUsed.add(_baseGas).mul(_gasPrice);

      require(transferToken(_gasToken, receiver, payment));
    }
  }

  function _encodeTransactionData(
    address _to,
    uint256 _value,
    bytes calldata _data,
    Operation _operation,
    uint256 _safeTxGas,
    uint256 _baseGas,
    uint256 _gasPrice,
    address _gasToken,
    address _refundReceiver
  ) internal view returns (bytes memory) {
    bytes32 safeTxHash = keccak256(
      abi.encode(
        SAFE_TX_TYPEHASH,
        _to,
        _value,
        keccak256(_data),
        _operation,
        _safeTxGas,
        _baseGas,
        _gasPrice,
        _gasToken,
        _refundReceiver,
        nonce
      )
    );

    return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, safeTxHash);
  }

  // Private

  function _getBallot(uint256 _index, address _voter)
    internal
    view
    returns (TransactionalVoteBallot.Instance memory)
  {
    return TransactionalVoteBallot(ballotModelAddress).deserialize(address(this), _index, _voter);
  }

  function _getSettings() internal view returns (TransactionalVoteSettings.Instance memory) {
    return TransactionalVoteSettings(settingsModelAddress).deserialize(address(this));
  }

  function _getVote(uint256 _index) internal view returns (TransactionalVote.Instance memory) {
    return TransactionalVote(voteModelAddress).deserialize(address(this), _index);
  }

  function _voteExists(uint256 _index) internal view returns (bool) {
    return TransactionalVote(voteModelAddress).exists(address(this), _index);
  }

  function _voteNotExpired(TransactionalVote.Instance memory vote) internal returns (bool) {
    if (vote.endOnBlock <= block.number) {
      vote.isActive = false;
      TransactionalVote(voteModelAddress).serialize(vote);
      return false;
    }

    return true;
  }
}
