// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

import './Token.sol';
import './TokenHolder.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing token balance change data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract BalanceMultipliers is EternalModel {
  struct Instance {
    uint256 blockNumber;
    uint256 index; // counter
    uint256 k;
    uint256 m;
    Ecosystem.Instance ecosystem;
    Token.Instance token;
  }

  function deserialize(
    uint256 _blockNumber,
    Ecosystem.Instance memory _ecosystem,
    Token.Instance memory _token
  ) public view returns (Instance memory record) {
    record.blockNumber = _blockNumber;
    record.ecosystem = _ecosystem;
    record.index = _token.counter;
    record.k = getUint(keccak256(abi.encode(_token.uuid, record.index, 'k')));
    record.m = getUint(keccak256(abi.encode(_token.uuid, record.index, 'm')));
    record.token = _token;
    return record;
  }

  function exists(
    uint256,
    Ecosystem.Instance memory,
    Token.Instance memory
  ) external pure returns (bool) {
    return true;
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    require(msg.sender == record.ecosystem.balanceModelAddress, 'ElasticDAO: Unauthorized');

    setUint(
      keccak256(abi.encode(record.token.uuid, record.index, 'blockNumber')),
      record.blockNumber
    );
    setUint(keccak256(abi.encode(record.token.uuid, record.index, 'k')), record.k);
    setUint(keccak256(abi.encode(record.token.uuid, record.index, 'm')), record.m);
  }
}
