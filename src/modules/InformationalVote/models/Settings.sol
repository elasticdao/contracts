// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../../../models/EternalModel.sol';
import '../../../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing information vote settings data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract InformationalVoteSettings is EternalModel {
  struct Instance {
    address managerAddress;
    address votingTokenAddress;
    bool hasPenalty;
    uint256 approval;
    uint256 counter;
    uint256 maxSharesPerTokenHolder;
    uint256 minBlocksForPenalty;
    uint256 minDurationInBlocks;
    uint256 minPenaltyInShares;
    uint256 minRewardInShares;
    uint256 minSharesToCreate;
    uint256 penalty;
    uint256 quorum;
    uint256 reward;
  }

  /**
   * @dev deserializes Instance struct
   * @param _managerAddress - address of the unique manager instance
   * @return record Instance
   */
  function deserialize(address _managerAddress) external view returns (Instance memory record) {
    record.managerAddress = _managerAddress;

    if (_exists(_managerAddress)) {
      record.approval = getUint(keccak256(abi.encode(_managerAddress, 'approval')));
      record.counter = getUint(keccak256(abi.encode(_managerAddress, 'counter')));
      record.hasPenalty = getBool(keccak256(abi.encode(_managerAddress, 'hasPenalty')));
      record.maxSharesPerTokenHolder = getUint(
        keccak256(abi.encode(_managerAddress, 'maxSharesPerTokenHolder'))
      );
      record.minBlocksForPenalty = getUint(
        keccak256(abi.encode(_managerAddress, 'minBlocksForPenalty'))
      );
      record.minDurationInBlocks = getUint(
        keccak256(abi.encode(_managerAddress, 'minDurationInBlocks'))
      );
      record.minSharesToCreate = getUint(
        keccak256(abi.encode(_managerAddress, 'minSharesToCreate'))
      );
      record.minPenaltyInShares = getUint(
        keccak256(abi.encode(_managerAddress, 'minPenaltyInShares'))
      );
      record.minRewardInShares = getUint(
        keccak256(abi.encode(_managerAddress, 'minRewardInShares'))
      );
      record.penalty = getUint(keccak256(abi.encode(_managerAddress, 'penalty')));
      record.quorum = getUint(keccak256(abi.encode(_managerAddress, 'quorum')));
      record.reward = getUint(keccak256(abi.encode(_managerAddress, 'reward')));
      record.votingTokenAddress = getAddress(
        keccak256(abi.encode(_managerAddress, 'votingTokenAddress'))
      );
    }

    return record;
  }

  function exists(address _managerAddress) external view returns (bool recordExists) {
    return _exists(_managerAddress);
  }

  /**
   * @dev increments counter for the @param _managerAddress
   * @param _managerAddress - address of the unique manager instance
   */
  function incrementCounter(address _managerAddress) external {
    setUint(
      keccak256(abi.encode(_managerAddress, 'counter')),
      SafeMath.add(getUint(keccak256(abi.encode(_managerAddress, 'counter'))), 1)
    );
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setBool(keccak256(abi.encode(record.managerAddress, 'hasPenalty')), record.hasPenalty);
    setUint(keccak256(abi.encode(record.managerAddress, 'approval')), record.approval);
    setUint(keccak256(abi.encode(record.managerAddress, 'counter')), record.counter);
    setUint(
      keccak256(abi.encode(record.managerAddress, 'maxSharesPerTokenHolder')),
      record.maxSharesPerTokenHolder
    );
    setUint(
      keccak256(abi.encode(record.managerAddress, 'minBlocksForPenalty')),
      record.minBlocksForPenalty
    );
    setUint(
      keccak256(abi.encode(record.managerAddress, 'minDurationInBlocks')),
      record.minDurationInBlocks
    );
    setUint(
      keccak256(abi.encode(record.managerAddress, 'minPenaltyInShares')),
      record.minPenaltyInShares
    );
    setUint(
      keccak256(abi.encode(record.managerAddress, 'minRewardInShares')),
      record.minRewardInShares
    );
    setUint(
      keccak256(abi.encode(record.managerAddress, 'minSharesToCreate')),
      record.minSharesToCreate
    );
    setUint(keccak256(abi.encode(record.managerAddress, 'penalty')), record.penalty);
    setUint(keccak256(abi.encode(record.managerAddress, 'quorum')), record.quorum);
    setUint(keccak256(abi.encode(record.managerAddress, 'reward')), record.reward);
    setAddress(
      keccak256(abi.encode(record.managerAddress, 'votingTokenAddress')),
      record.votingTokenAddress
    );

    setBool(keccak256(abi.encode(record.managerAddress, 'exists')), true);
  }

  function _exists(address _managerAddress) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode(_managerAddress, 'exists')));
  }
}
