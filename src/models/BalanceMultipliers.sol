// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

import './Token.sol';
import './TokenHolder.sol';

import 'hardhat/console.sol';

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
    record = _findByBlockNumber(_blockNumber, _token.counter, 0, _token);
    record.blockNumber = _blockNumber;
    record.ecosystem = _ecosystem;
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
    setUint(
      keccak256(abi.encode(record.token.uuid, record.index, 'blockNumber')),
      record.blockNumber
    );
    setUint(keccak256(abi.encode(record.token.uuid, record.index, 'k')), record.k);
    setUint(keccak256(abi.encode(record.token.uuid, record.index, 'm')), record.m);
  }

  function _findByBlockNumber(
    uint256 _blockNumber,
    uint256 _numberOfRecords,
    uint256 _offset,
    Token.Instance memory _token
  ) internal view returns (Instance memory record) {
    if (_numberOfRecords == 0) {
      record.blockNumber = _blockNumber;
      record.k = 0;
      record.m = 0;
      return record;
    }

    if (_numberOfRecords == 1) {
      uint256 index = SafeMath.add(_offset, _numberOfRecords);
      record.blockNumber = getUint(keccak256(abi.encode(_token.uuid, index, 'blockNumber')));

      if (record.blockNumber == 0 || record.blockNumber > _blockNumber) {
        if (_offset == 0) {
          record.blockNumber = getUint(keccak256(abi.encode(_token.uuid, 0, 'blockNumber')));
          if (record.blockNumber == 0 || record.blockNumber > _blockNumber) {
            record.k = 0;
            record.m = 0;
            return record;
          }
          record.k = getUint(keccak256(abi.encode(_token.uuid, 0, 'k')));
          record.m = getUint(keccak256(abi.encode(_token.uuid, 0, 'm')));
          return record;
        }
        return _findByBlockNumber(_blockNumber, _numberOfRecords, SafeMath.sub(_offset, 1), _token);
      }
      record.k = getUint(keccak256(abi.encode(_token.uuid, index, 'k')));
      record.m = getUint(keccak256(abi.encode(_token.uuid, index, 'm')));
      return record;
    }

    uint256 half = SafeMath.div(_numberOfRecords, 2);
    uint256 middleIndex = SafeMath.add(half, _offset);
    record.blockNumber = getUint(keccak256(abi.encode(_token.uuid, middleIndex, 'blockNumber')));

    if (record.blockNumber > _blockNumber) {
      return _findByBlockNumber(_blockNumber, half, _offset, _token);
    }

    if (record.blockNumber < _blockNumber) {
      return _findByBlockNumber(_blockNumber, half, middleIndex, _token);
    }

    record.k = getUint(keccak256(abi.encode(_token.uuid, middleIndex, 'k')));
    record.m = getUint(keccak256(abi.encode(_token.uuid, middleIndex, 'm')));
    return record;
  }
}
