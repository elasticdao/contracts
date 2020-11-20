// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../../../models/EternalModel.sol';
import '../../../libraries/SafeMath.sol';

import 'hardhat/console.sol';

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
      record.approval = getUint(keccak256(abi.encode('approval', _managerAddress)));
      record.counter = getUint(keccak256(abi.encode('counter', _managerAddress)));
      record.hasPenalty = getBool(keccak256(abi.encode('hasPenalty', _managerAddress)));
      record.maxSharesPerTokenHolder = getUint(
        keccak256(abi.encode('maxSharesPerTokenHolder', _managerAddress))
      );
      record.minBlocksForPenalty = getUint(
        keccak256(abi.encode('minBlocksForPenalty', _managerAddress))
      );
      record.minDurationInBlocks = getUint(
        keccak256(abi.encode('minDurationInBlocks', _managerAddress))
      );
      record.minSharesToCreate = getUint(
        keccak256(abi.encode('minSharesToCreate', _managerAddress))
      );
      record.minPenaltyInShares = getUint(
        keccak256(abi.encode('minPenaltyInShares', _managerAddress))
      );
      record.minRewardInShares = getUint(
        keccak256(abi.encode('minRewardInShares', _managerAddress))
      );
      record.penalty = getUint(keccak256(abi.encode('penalty', _managerAddress)));
      record.quorum = getUint(keccak256(abi.encode('quorum', _managerAddress)));
      record.reward = getUint(keccak256(abi.encode('reward', _managerAddress)));
      record.votingTokenAddress = getAddress(
        keccak256(abi.encode('votingTokenAddress', _managerAddress))
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
      keccak256(abi.encode('counter', _managerAddress)),
      SafeMath.add(getUint(keccak256(abi.encode('counter', _managerAddress))), 1)
    );
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setBool(keccak256(abi.encode('hasPenalty', record.managerAddress)), record.hasPenalty);
    setUint(keccak256(abi.encode('approval', record.managerAddress)), record.approval);
    setUint(keccak256(abi.encode('counter', record.managerAddress)), record.counter);
    setUint(
      keccak256(abi.encode('maxSharesPerTokenHolder', record.managerAddress)),
      record.maxSharesPerTokenHolder
    );
    setUint(
      keccak256(abi.encode('minBlocksForPenalty', record.managerAddress)),
      record.minBlocksForPenalty
    );
    setUint(
      keccak256(abi.encode('minDurationInBlocks', record.managerAddress)),
      record.minDurationInBlocks
    );
    setUint(
      keccak256(abi.encode('minPenaltyInShares', record.managerAddress)),
      record.minPenaltyInShares
    );
    setUint(
      keccak256(abi.encode('minRewardInShares', record.managerAddress)),
      record.minRewardInShares
    );
    setUint(
      keccak256(abi.encode('minSharesToCreate', record.managerAddress)),
      record.minSharesToCreate
    );
    setUint(keccak256(abi.encode('penalty', record.managerAddress)), record.penalty);
    setUint(keccak256(abi.encode('quorum', record.managerAddress)), record.quorum);
    setUint(keccak256(abi.encode('reward', record.managerAddress)), record.reward);
    setAddress(
      keccak256(abi.encode('votingTokenAddress', record.managerAddress)),
      record.votingTokenAddress
    );

    setBool(keccak256(abi.encode('exists', record.managerAddress)), true);
  }

  function _exists(address _managerAddress) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _managerAddress)));
  }
}
