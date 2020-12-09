// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './models/Ballot.sol';
import './models/Settings.sol';
import './models/Vote.sol';
import './Operation.sol';

import '../../interfaces/IElasticToken.sol';
import '../../libraries/ElasticMath.sol';

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

  address public ballotModelAddress;
  address public settingsModelAddress;
  address payable public vaultAddress;
  address public voteModelAddress;
  bool public initialized;
  uint256 public nonce;
  bytes32 public domainSeparator;

  constructor(
    address _ballotModelAddress,
    address _settingsModelAddress,
    address payable _vaultAddress,
    address _voteModelAddress
  ) {
    ballotModelAddress = _ballotModelAddress;
    initialized = false;
    settingsModelAddress = _settingsModelAddress;
    vaultAddress = _vaultAddress;
    voteModelAddress = _voteModelAddress;
  }

  /**
   * @dev Initializes the TransactionalVote Manager
   * @param _votingTokenAddress - the address of the voting Token
   * @param _hasPenalty - whether the vote has a penalty or not
   * @param _settings - an array of all the vote related settings
   */
  function initialize(
    address _votingTokenAddress,
    bool _hasPenalty,
    uint256[10] memory _settings
  ) external {
    require(initialized == false, 'ElasticDAO: Transactional Vote Manager already initialized.');
    TransactionalVoteSettings settingsContract = TransactionalVoteSettings(settingsModelAddress);
    TransactionalVoteSettings.Instance memory settings;
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
    domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this));

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
    TransactionalVoteSettings.Instance memory settings = _getSettings();
    require(_voteExists(_index, settings), 'ElasticDAO: Invalid vote id.');
    TransactionalVote.Instance memory vote = _getVote(_index, settings);
    require(vote.isApproved == false, 'ElasticDAO: Cannot penalize a vote that passed.');
    require(vote.isActive == false, 'ElasticDAO: Cannot penalize an active vote.');
    require(
      vote.hasReachedQuorum == false,
      'ElasticDAO: Cannot penalize a vote that has reached quorum.'
    );
    require(vote.hasPenalty, 'ElasticDAO: This vote has no penalty.');
    TransactionalVoteBallot ballotContract = TransactionalVoteBallot(ballotModelAddress);
    IElasticToken tokenContract = IElasticToken(vote.votingTokenAddress);

    for (uint256 i = 0; i < _addressesToPenalize.length; i = SafeMath.add(i, 1)) {
      if (ballotContract.exists(_addressesToPenalize[i], settings, vote) == false) {
        TransactionalVoteBallot.Instance memory ballot;
        ballot.settings = settings;
        ballot.vote = vote;
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
    TransactionalVoteSettings.Instance memory settings = _getSettings();
    require(_voteExists(_index, settings), 'ElasticDAO: Invalid vote id.');
    TransactionalVote.Instance memory vote = _getVote(_index, settings);
    require(vote.isApproved == false, 'ElasticDAO: TransactionalVote has already been approved.');
    require(vote.isActive, 'ElasticDAO: TransactionalVote is not active or has ended.');
    require(_voteNotExpired(vote), 'ElasticDAO: TransactionalVote is not active or has ended.');
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
    ballot.settings = settings;
    ballot.vote = vote;
    ballot.voter = msg.sender;
    ballot.lambda = votingLambda;
    ballot.yna = _yna;

    TransactionalVoteBallot(ballotModelAddress).serialize(ballot);
    TransactionalVote(voteModelAddress).serialize(vote);

    tokenContract.mintShares(msg.sender, ElasticMath.wmul(votingLambda, vote.reward));
  }

  function createVote(
    address _to,
    uint256 _value,
    bytes memory _data,
    Operation _operation,
    uint256 _safeTxGas,
    uint256 _baseGas,
    uint256 _endOnBlock
  ) external returns (uint256) {
    require(initialized, 'ElasticDAO: TransactionalVote Manager not initialized');
    TransactionalVoteSettings.Instance memory settings = _getSettings();
    IElasticToken tokenContract = IElasticToken(settings.votingTokenAddress);
    require(
      tokenContract.balanceOfInShares(msg.sender) >= settings.minSharesToCreate,
      'ElasticDAO: Not enough shares to create vote'
    );
    require(
      SafeMath.sub(_endOnBlock, block.number) >= settings.minDurationInBlocks,
      'ElasticDAO: TransactionalVote period too short'
    );
    bytes memory zero;
    require(
      _value > 0,
      'ElasticDAO: Transaction must either transfer value or call another contract function'
    );
    if (keccak256(abi.encodePacked(_data)) == keccak256(abi.encodePacked(zero))) {
      revert(
        'ElasticDAO: Transaction must either transfer value or call another contract function'
      );
    }

    TransactionalVote voteContract = TransactionalVote(voteModelAddress);
    TransactionalVote.Instance memory vote;
    vote.settings = settings;
    vote.abstainLambda = 0;
    vote.approval = 0;
    vote.author = msg.sender;
    vote.baseGas = _baseGas;
    vote.data = _data;
    vote.endOnBlock = _endOnBlock;
    vote.hasPenalty = settings.hasPenalty;
    vote.hasReachedQuorum = false;
    vote.index = settings.counter;
    vote.isActive = true;
    vote.isApproved = false;
    vote.maxSharesPerTokenHolder = settings.maxSharesPerTokenHolder;
    vote.minBlocksForPenalty = settings.minBlocksForPenalty;
    vote.noLambda = 0;
    vote.operation = _operation;
    vote.penalty = settings.penalty;
    vote.quorum = settings.quorum;
    vote.reward = settings.reward;
    vote.safeTxGas = _safeTxGas;
    vote.startOnBlock = block.number;
    vote.to = _to;
    vote.value = _value;
    vote.votingTokenAddress = settings.votingTokenAddress;
    vote.yesLambda = 0;
    voteContract.serialize(vote);
    TransactionalVoteSettings(settingsModelAddress).incrementCounter(address(this));

    emit CreateVote(vote.index);
  }

  /**
   * @dev executes arbitrary transaction when safe abi function signature is passed into data. Based on Gnosis Safe.
   * @param _gasPrice - Gas price that should be used for the payment calculation.
   * @param _gasToken - Token address (or 0 if ETH) that is used for the payment.
   * @param _index - the vote index id.
   * @return success bool
   */
  function execute(
    address _gasToken,
    uint256 _gasPrice,
    uint256 _index
  ) external returns (bool success) {
    TransactionalVoteSettings.Instance memory settings = _getSettings();
    TransactionalVote.Instance memory vote = _getVote(_index, settings);

    require(!vote.isExecuted, 'ElasticDAO: Vote has already been executed');
    require(vote.isApproved, 'ElasticDAO: Can not call unless vote is successful');

    vote.isExecuted = true;
    TransactionalVote voteContract = TransactionalVote(voteModelAddress);
    voteContract.serialize(vote);

    success = _executeTransaction(
      vote.to,
      vote.value,
      vote.data,
      vote.operation,
      vote.safeTxGas,
      vote.baseGas,
      _gasPrice,
      _gasToken,
      vaultAddress
    );

    if (!success) {
      revert('ElasticDAO: Transaction Failed');
    }

    return true;
  }

  function getSettings() external view returns (TransactionalVoteSettings.Instance memory) {
    return _getSettings();
  }

  // Private
  function _executeTransaction(
    address _to,
    uint256 _value,
    bytes memory _data,
    Operation _operation,
    uint256 _safeTxGas,
    uint256 _baseGas,
    uint256 _gasPrice,
    address _gasToken,
    address payable _refundReceiver
  ) internal returns (bool success) {
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
      gasleft() >= SafeMath.max((_safeTxGas * 64) / 63, (_safeTxGas + 2500) + 500),
      'ElasticDAO: Not enough gas to execute safe transaction'
    );

    // use scope to limit variable lifetime and prevent `stack to deep` errors
    {
      uint256 gasUsed = gasleft();
      // If the gasPrice is 0 we assume that nearly all available gas can be used (it is always more than safeTxGas)
      // We only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still higher than safeTxGas
      success = _handleCall(
        _to,
        _value,
        _data,
        _operation,
        _gasPrice == 0 ? (gasleft() - 2500) : _safeTxGas
      );
      gasUsed = SafeMath.sub(gasUsed, gasleft());

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
    address payable receiver = _refundReceiver == address(0) ? tx.origin : _refundReceiver;

    if (_gasToken == address(0)) {
      // For ETH we will only adjust the gas price to not be higher than the actual used gas price
      payment = SafeMath.mul(
        SafeMath.add(_gasUsed, _baseGas),
        _gasPrice < tx.gasprice ? _gasPrice : tx.gasprice
      );

      require(receiver.send(payment), 'Elastic DAO: Could not pay gas costs with token');
    } else {
      payment = SafeMath.mul(SafeMath.add(_gasUsed, _baseGas), _gasPrice);

      require(_transferToken(_gasToken, receiver, payment));
    }
  }

  function _encodeTransactionData(
    address _to,
    uint256 _value,
    bytes memory _data,
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

  function _handleCall(
    address _to,
    uint256 _value,
    bytes memory _data,
    Operation _operation,
    uint256 _txGas
  ) internal returns (bool success) {
    if (_operation == Operation.Call) success = _executeCall(_to, _value, _data, _txGas);
    else if (_operation == Operation.DelegateCall)
      success = _executeDelegateCall(_to, _data, _txGas);
    else success = false;
  }

  function _executeCall(
    address to,
    uint256 value,
    bytes memory data,
    uint256 txGas
  ) internal returns (bool success) {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
    }
  }

  function _executeDelegateCall(
    address to,
    bytes memory data,
    uint256 txGas
  ) internal returns (bool success) {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
    }
  }

  /// @dev Transfers a token and returns if it was a success
  /// @param token Token that should be transferred
  /// @param receiver Receiver to whom the token should be transferred
  /// @param amount The amount of tokens that should be transferred
  function _transferToken(
    address token,
    address receiver,
    uint256 amount
  ) internal returns (bool transferred) {
    bytes memory data = abi.encodeWithSignature('transfer(address,uint256)', receiver, amount);
    assembly {
      let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0)
      let ptr := mload(0x40)
      mstore(0x40, add(ptr, returndatasize()))
      returndatacopy(ptr, 0, returndatasize())
      switch returndatasize()
        case 0 {
          transferred := success
        }
        case 0x20 {
          transferred := iszero(or(iszero(success), iszero(mload(ptr))))
        }
        default {
          transferred := 0
        }
    }
  }

  function _getSettings() internal view returns (TransactionalVoteSettings.Instance memory) {
    return TransactionalVoteSettings(settingsModelAddress).deserialize(address(this));
  }

  function _getVote(uint256 _index, TransactionalVoteSettings.Instance memory _settings)
    internal
    view
    returns (TransactionalVote.Instance memory)
  {
    return TransactionalVote(voteModelAddress).deserialize(_index, _settings);
  }

  function _voteExists(uint256 _index, TransactionalVoteSettings.Instance memory _settings)
    internal
    view
    returns (bool)
  {
    return TransactionalVote(voteModelAddress).exists(_index, _settings);
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
