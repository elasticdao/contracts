// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../Operation.sol';

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
    address uuid;
    address author;
    address to;
    address votingToken;
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
  }

  /**
   * @dev deserializes Instance struct
   * @param _uuid - address of the unique manager instance
   * @param _index - the counter value of this vote
   * @return record Instance
   */
  function deserialize(address _uuid, uint256 _index)
    external
    view
    returns (Instance memory record)
  {
    record.index = _index;
    record.uuid = _uuid;

    if (_exists(_uuid, _index)) {
      record.abstainLambda = getUint(keccak256(abi.encode('abstainLambda', _uuid, _index)));
      record.approval = getUint(keccak256(abi.encode('approval', _uuid, _index)));
      record.author = getAddress(keccak256(abi.encode('author', _uuid, _index)));
      record.baseGas = getUint(keccak256(abi.encode('baseGas', _uuid, _index)));
      record.data = getBytes(keccak256(abi.encode('data', _uuid, _index)));
      record.endOnBlock = getUint(keccak256(abi.encode('endOnBlock', _uuid, _index)));
      record.hasPenalty = getBool(keccak256(abi.encode('hasPenalty', _uuid, _index)));
      record.hasReachedQuorum = getBool(keccak256(abi.encode('hasReachedQuorum', _uuid, _index)));
      record.isActive = getBool(keccak256(abi.encode('isActive', _uuid, _index)));
      record.isApproved = getBool(keccak256(abi.encode('isApproved', _uuid, _index)));
      record.isExecuted = getBool(keccak256(abi.encode('isExecuted', _uuid, _index)));
      record.maxSharesPerTokenHolder = getUint(
        keccak256(abi.encode('maxSharesPerTokenHolder', _uuid, _index))
      );
      record.minBlocksForPenalty = getUint(
        keccak256(abi.encode('minBlocksForPenalty', _uuid, _index))
      );
      record.minPenaltyInShares = getUint(keccak256(abi.encode('minPenaltyInShares')));
      record.minRewardInShares = getUint(keccak256(abi.encode('minRewardInShares')));
      record.noLambda = getUint(keccak256(abi.encode('noLambda', _uuid, _index)));
      record.penalty = getUint(keccak256(abi.encode('penalty', _uuid, _index)));
      record.proposal = getString(keccak256(abi.encode('proposal', _uuid, _index)));
      record.quorum = getUint(keccak256(abi.encode('quorum', _uuid, _index)));
      record.quorumLambda = getUint(keccak256(abi.encode('quorumLambda', _uuid, _index)));
      record.reward = getUint(keccak256(abi.encode('reward', _uuid, _index)));
      record.safeTxGas = getUint(keccak256(abi.encode('safeTxGas', _uuid, _index)));
      record.startOnBlock = getUint(keccak256(abi.encode('startOnBlock', _uuid, _index)));
      record.to = getAddress(keccak256(abi.encode('to', _uuid, _index)));
      record.value = getUint(keccak256(abi.encode('value', _uuid, _index)));
      record.votingToken = getAddress(keccak256(abi.encode('votingToken', _uuid, _index)));
      record.yesLambda = getUint(keccak256(abi.encode('yesLambda', _uuid, _index)));
    }

    return record;
  }

  function exists(address _uuid, uint256 _index) external view returns (bool recordExists) {
    return _exists(_uuid, _index);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setAddress(keccak256(abi.encode('author', record.uuid, record.index)), record.author);
    setAddress(keccak256(abi.encode('to', record.uuid, record.index)), record.to);
    setAddress(keccak256(abi.encode('votingToken', record.uuid, record.index)), record.votingToken);
    setBool(keccak256(abi.encode('hasPenalty', record.uuid, record.index)), record.hasPenalty);
    setBool(
      keccak256(abi.encode('hasReachedQuorum', record.uuid, record.index)),
      record.hasReachedQuorum
    );
    setBool(keccak256(abi.encode('isActive', record.uuid, record.index)), record.isActive);
    setBool(keccak256(abi.encode('isApproved', record.uuid, record.index)), record.isApproved);
    setBool(keccak256(abi.encode('isExecuted', record.uuid, record.index)), record.isExecuted);
    setString(keccak256(abi.encode('proposal', record.uuid, record.index)), record.proposal);
    setBytes(keccak256(abi.encode('data', record.uuid, record.index)), record.data);
    setUint(
      keccak256(abi.encode('abstainLambda', record.uuid, record.index)),
      record.abstainLambda
    );
    setUint(keccak256(abi.encode('approval', record.uuid, record.index)), record.approval);
    setUint(keccak256(abi.encode('baseGas', record.uuid, record.index)), record.baseGas);
    setUint(keccak256(abi.encode('endOnBlock', record.uuid, record.index)), record.endOnBlock);
    setUint(
      keccak256(abi.encode('maxSharesPerTokenHolder', record.uuid, record.index)),
      record.maxSharesPerTokenHolder
    );
    setUint(
      keccak256(abi.encode('minBlocksForPenalty', record.uuid, record.index)),
      record.minBlocksForPenalty
    );
    setUint(
      keccak256(abi.encode('minPenaltyInShares', record.uuid, record.index)),
      record.minPenaltyInShares
    );
    setUint(
      keccak256(abi.encode('minRewardInShares', record.uuid, record.index)),
      record.minRewardInShares
    );
    setUint(keccak256(abi.encode('noLambda', record.uuid, record.index)), record.noLambda);
    setUint(keccak256(abi.encode('penalty', record.uuid, record.index)), record.penalty);
    setUint(keccak256(abi.encode('quorum', record.uuid, record.index)), record.quorum);
    setUint(keccak256(abi.encode('quorumLambda', record.uuid, record.index)), record.quorumLambda);
    setUint(keccak256(abi.encode('reward', record.uuid, record.index)), record.reward);
    setUint(keccak256(abi.encode('safeTxGas', record.uuid, record.index)), record.safeTxGas);
    setUint(keccak256(abi.encode('startOnBlock', record.uuid, record.index)), record.startOnBlock);
    setUint(keccak256(abi.encode('value', record.uuid, record.index)), record.value);
    setUint(keccak256(abi.encode('yesLambda', record.uuid, record.index)), record.yesLambda);

    setBool(keccak256(abi.encode('exists', record.uuid, record.index)), true);
  }

  function _exists(address _uuid, uint256 _index) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid, _index)));
  }
}
