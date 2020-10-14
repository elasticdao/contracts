// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../../../models/EternalModel.sol';
import '../../../libraries/SafeMath.sol';

import '@nomiclabs/buidler/console.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing information vote settings data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract InformationalVoteSettings is EternalModel {
  struct Instance {
    address uuid;
    address votingToken;
    bool hasPenalty;
    uint256 approval;
    uint256 counter;
    uint256 maxSharesPerTokenHolder;
    uint256 minBlocksForPenalty;
    uint256 minDurationInBlocks;
    uint256 minPenaltyInShares;
    uint256 minSharesToCreate;
    uint256 penalty;
    uint256 quorum;
    uint256 reward;
  }

  /**
   * @dev deserializes Instance struct
   * @param _uuid - address of the unique manager instance
   * @return record Instance
   */
  function deserialize(address _uuid) external view returns (Instance memory record) {
    record.uuid = _uuid;

    if (_exists(_uuid)) {
      record.approval = getUint(keccak256(abi.encode('approval', _uuid)));
      record.counter = getUint(keccak256(abi.encode('counter', _uuid)));
      record.maxSharesPerTokenHolder = getUint(
        keccak256(abi.encode('maxSharesPerTokenHolder', _uuid))
      );
      record.minBlocksForPenalty = getUint(keccak256(abi.encode('minBlocksForPenalty', _uuid)));
      record.minDurationInBlocks = getUint(keccak256(abi.encode('minDurationInBlocks', _uuid)));
      record.minSharesToCreate = getUint(keccak256(abi.encode('minSharesToCreate', _uuid)));
      record.minPenaltyInShares = getUint(keccak256(abi.encode('minPenaltyInShares', _uuid)));
      record.penalty = getUint(keccak256(abi.encode('penalty', _uuid)));
      record.quorum = getUint(keccak256(abi.encode('quorum', _uuid)));
      record.reward = getUint(keccak256(abi.encode('reward', _uuid)));
      record.votingToken = getAddress(keccak256(abi.encode('votingToken', _uuid)));
    }

    return record;
  }

  function exists(address _uuid) external view returns (bool recordExists) {
    return _exists(_uuid);
  }

  function getQuorumLambda(address _uuid, uint256 _id) external view returns (uint256) {
    return getUint(keccak256(abi.encode('quorumLambda', _uuid, _id)));
  }

  /**
   * @dev increments counter for the @param _uuid
   * @param _uuid - address of the unique manager instance
   */
  function incrementCounter(address _uuid) external {
    setUint(
      keccak256(abi.encode('counter', _uuid)),
      SafeMath.add(getUint(keccak256(abi.encode('counter', _uuid))), 1)
    );
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setUint(keccak256(abi.encode('approval', record.uuid)), record.approval);
    setUint(keccak256(abi.encode('counter', record.uuid)), record.counter);
    setUint(
      keccak256(abi.encode('maxSharesPerTokenHolder', record.uuid)),
      record.maxSharesPerTokenHolder
    );
    setUint(keccak256(abi.encode('minBlocksForPenalty', record.uuid)), record.minBlocksForPenalty);
    setUint(keccak256(abi.encode('minDurationInBlocks', record.uuid)), record.minDurationInBlocks);
    setUint(keccak256(abi.encode('minPenaltyInShares', record.uuid)), record.minPenaltyInShares);
    setUint(keccak256(abi.encode('minSharesToCreate', record.uuid)), record.minSharesToCreate);
    setUint(keccak256(abi.encode('penalty', record.uuid)), record.penalty);
    setUint(keccak256(abi.encode('quorum', record.uuid)), record.quorum);
    setUint(keccak256(abi.encode('reward', record.uuid)), record.reward);
    setAddress(keccak256(abi.encode('votingToken', record.uuid)), record.votingToken);

    setBool(keccak256(abi.encode('exists', record.uuid)), true);
  }

  function _exists(address _uuid) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid)));
  }
}
