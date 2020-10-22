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
  ) public view returns (Instance memory) {
    record = _findByBlockNumber(_token.uuid, _blockNumber, _token.counter, 0);
    record.blockNumber = _blockNumber;
    record.ecosystem = _ecosystem;
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
    address _uuid,
    uint256 _blockNumber,
    uint256 _numberOfRecords,
    uint256 _offset
  ) internal view returns (Instance memory record) {
    if (_numberOfRecords == 0) {
      record.blockNumber = _blockNumber;
      record.k = 0;
      record.m = 0;
      return record;
    }

    if (_numberOfRecords == 1) {
      uint256 index = SafeMath.add(_offset, _numberOfRecords);
      record.blockNumber = getUint(keccak256(abi.encode(_uuid, index, 'blockNumber')));

      if (record.blockNumber == 0 || record.blockNumber > _blockNumber) {
        if (_offset == 0) {
          record.blockNumber = getUint(keccak256(abi.encode(_uuid, 0, 'blockNumber')));
          if (record.blockNumber == 0 || record.blockNumber > _blockNumber) {
            record.k = 0;
            record.m = 0;
            return record;
          }
          record.k = getUint(keccak256(abi.encode(_uuid, 0, 'k')));
          record.m = getUint(keccak256(abi.encode(_uuid, 0, 'm')));
          return record;
        }
        return _findByBlockNumber(_uuid, _blockNumber, SafeMath.sub(_offset, 1), _numberOfRecords);
      }
      record.k = getUint(keccak256(abi.encode(_uuid, id, 'k')));
      record.m = getUint(keccak256(abi.encode(_uuid, id, 'm')));
      return record;
    }

    uint256 half = SafeMath.div(_numberOfRecords, 2);
    uint256 middleId = SafeMath.add(half, _offset);
    record.blockNumber = getUint(keccak256(abi.encode(_uuid, middleId, 'blockNumber')));

    if (record.blockNumber > _blockNumber) {
      return _findByBlockNumber(_uuid, _blockNumber, _offset, half);
    }

    if (record.blockNumber < _blockNumber) {
      return _findByBlockNumber(_uuid, _blockNumber, middleId, half);
    }

    record.k = getUint(keccak256(abi.encode(_uuid, 0, 'k')));
    record.m = getUint(keccak256(abi.encode(_uuid, 0, 'm')));
    return record;
  }
}
