// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../Operation.sol';
import './Settings.sol';

import '../../../models/EternalModel.sol';
import '../../../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing information vote data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract TransactionalVote is EternalModel {
  mapping(bytes32 => Operation) operations;

  struct Instance {
    address author;
    address to;
    address votingTokenAddress;
    bool hasPenalty;
    bool hasReachedQuorum;
    bool isActive;
    bool isApproved;
    bool isExecuted;
    bytes data;
    string proposal;
    uint256 abstainLambda;
    uint256 approval;
    uint256 baseGas;
    uint256 endOnBlock;
    uint256 index;
    uint256 maxSharesPerTokenHolder;
    uint256 minBlocksForPenalty;
    uint256 minPenaltyInShares;
    uint256 minRewardInShares;
    uint256 noLambda;
    uint256 penalty;
    uint256 quorum;
    uint256 quorumLambda;
    uint256 reward;
    uint256 safeTxGas;
    uint256 startOnBlock;
    uint256 value;
    uint256 yesLambda;
    Operation operation;
    TransactionalVoteSettings.Instance settings;
  }

  function deserialize(uint256 _index, TransactionalVoteSettings.Instance memory _settings)
    external
    view
    returns (Instance memory record)
  {
    record.index = _index;
    record.settings = _settings;

    if (_exists(_index, _settings)) {
      record.abstainLambda = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'abstainLambda'))
      );
      record.approval = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'approval'))
      );
      record.author = getAddress(keccak256(abi.encode(_index, _settings.managerAddress, 'author')));
      record.baseGas = getUint(keccak256(abi.encode(_index, _settings.managerAddress, 'baseGas')));
      record.data = getBytes(keccak256(abi.encode(_index, _settings.managerAddress, 'data')));
      record.endOnBlock = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'endOnBlock'))
      );
      record.hasPenalty = getBool(
        keccak256(abi.encode(_index, _settings.managerAddress, 'hasPenalty'))
      );
      record.hasReachedQuorum = getBool(
        keccak256(abi.encode(_index, _settings.managerAddress, 'hasReachedQuorum'))
      );
      record.isActive = getBool(
        keccak256(abi.encode(_index, _settings.managerAddress, 'isActive'))
      );
      record.isApproved = getBool(
        keccak256(abi.encode(_index, _settings.managerAddress, 'isApproved'))
      );
      record.isExecuted = getBool(
        keccak256(abi.encode(_index, _settings.managerAddress, 'isExecuted'))
      );
      record.maxSharesPerTokenHolder = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'maxSharesPerTokenHolder'))
      );
      record.minBlocksForPenalty = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'minBlocksForPenalty'))
      );
      record.minPenaltyInShares = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'minPenaltyInShares'))
      );
      record.minRewardInShares = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'minRewardInShares'))
      );
      record.noLambda = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'noLambda'))
      );
      record.penalty = getUint(keccak256(abi.encode(_index, _settings.managerAddress, 'penalty')));
      record.proposal = getString(
        keccak256(abi.encode(_index, _settings.managerAddress, 'proposal'))
      );
      record.quorum = getUint(keccak256(abi.encode(_index, _settings.managerAddress, 'quorum')));
      record.quorumLambda = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'quorumLambda'))
      );
      record.reward = getUint(keccak256(abi.encode(_index, _settings.managerAddress, 'reward')));
      record.safeTxGas = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'safeTxGas'))
      );
      record.startOnBlock = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'startOnBlock'))
      );
      record.to = getAddress(keccak256(abi.encode(_index, _settings.managerAddress, 'to')));
      record.value = getUint(keccak256(abi.encode(_index, _settings.managerAddress, 'value')));
      record.votingTokenAddress = getAddress(
        keccak256(abi.encode(_index, _settings.managerAddress, 'votingTokenAddress'))
      );
      record.yesLambda = getUint(
        keccak256(abi.encode(_index, _settings.managerAddress, 'yesLambda'))
      );
    }

    return record;
  }

  function exists(uint256 _index, TransactionalVoteSettings.Instance memory _settings)
    external
    view
    returns (bool recordExists)
  {
    return _exists(_index, _settings);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setAddress(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'author')),
      record.author
    );
    setAddress(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'to')),
      record.to
    );
    setAddress(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'votingTokenAddress')),
      record.votingTokenAddress
    );
    setBool(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'hasPenalty')),
      record.hasPenalty
    );
    setBool(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'hasReachedQuorum')),
      record.hasReachedQuorum
    );
    setBool(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'isActive')),
      record.isActive
    );
    setBool(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'isApproved')),
      record.isApproved
    );
    setBool(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'isExecuted')),
      record.isExecuted
    );
    setString(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'proposal')),
      record.proposal
    );
    setBytes(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'data')),
      record.data
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'abstainLambda')),
      record.abstainLambda
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'approval')),
      record.approval
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'baseGas')),
      record.baseGas
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'endOnBlock')),
      record.endOnBlock
    );
    setUint(
      keccak256(
        abi.encode(record.index, record.settings.managerAddress, 'maxSharesPerTokenHolder')
      ),
      record.maxSharesPerTokenHolder
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'minBlocksForPenalty')),
      record.minBlocksForPenalty
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'minPenaltyInShares')),
      record.minPenaltyInShares
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'minRewardInShares')),
      record.minRewardInShares
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'noLambda')),
      record.noLambda
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'penalty')),
      record.penalty
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'quorum')),
      record.quorum
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'quorumLambda')),
      record.quorumLambda
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'reward')),
      record.reward
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'safeTxGas')),
      record.safeTxGas
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'startOnBlock')),
      record.startOnBlock
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'value')),
      record.value
    );
    setUint(
      keccak256(abi.encode(record.index, record.settings.managerAddress, 'yesLambda')),
      record.yesLambda
    );

    setBool(keccak256(abi.encode(record.index, record.settings.managerAddress, 'exists')), true);
  }

  function _exists(uint256 _index, TransactionalVoteSettings.Instance memory _settings)
    internal
    view
    returns (bool recordExists)
  {
    return getBool(keccak256(abi.encode(_index, _settings.managerAddress, 'exists')));
  }
}
