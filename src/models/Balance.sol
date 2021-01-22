// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

import './BalanceMultipliers.sol';
import './Token.sol';
import './TokenHolder.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing token balance change data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract Balance is EternalModel {
  struct Instance {
    uint256 blockNumber;
    uint256 index; // tokenHolder.counter
    uint256 k;
    uint256 m;
    uint256 lambda;
    Ecosystem.Instance ecosystem;
    Token.Instance token;
    TokenHolder.Instance tokenHolder;
  }

  function deserialize(
    uint256 _blockNumber,
    Ecosystem.Instance memory _ecosystem,
    Token.Instance memory _token,
    TokenHolder.Instance memory _tokenHolder
  ) public view returns (Instance memory record) {
    record = _findByBlockNumber(_blockNumber, _tokenHolder.counter, 0, _token, _tokenHolder);

    record.ecosystem = _ecosystem;
    record.token = _token;
    record.tokenHolder = _tokenHolder;

    BalanceMultipliers.Instance memory balanceMultipliers =
      BalanceMultipliers(record.ecosystem.balanceMultipliersModelAddress).deserialize(
        _blockNumber,
        record.ecosystem,
        record.token
      );

    record.blockNumber = _blockNumber;
    record.k = balanceMultipliers.k;
    record.m = balanceMultipliers.m;

    return record;
  }

  function exists(
    uint256,
    Ecosystem.Instance memory,
    Token.Instance memory,
    TokenHolder.Instance memory
  ) external pure returns (bool) {
    return true;
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setUint(
      keccak256(
        abi.encode(record.token.uuid, record.tokenHolder.account, record.index, 'blockNumber')
      ),
      record.blockNumber
    );
    setUint(
      keccak256(abi.encode(record.token.uuid, record.tokenHolder.account, record.index, 'lambda')),
      record.lambda
    );

    BalanceMultipliers.Instance memory balanceMultipliers;
    balanceMultipliers.blockNumber = record.blockNumber;
    balanceMultipliers.index = record.token.counter;
    balanceMultipliers.k = record.k;
    balanceMultipliers.m = record.m;
    balanceMultipliers.ecosystem = record.ecosystem;
    balanceMultipliers.token = record.token;
    BalanceMultipliers(record.ecosystem.balanceMultipliersModelAddress).serialize(
      balanceMultipliers
    );
    Token(record.ecosystem.tokenModelAddress).incrementCounter(record.token.uuid);
  }

  function _findByBlockNumber(
    uint256 _blockNumber,
    uint256 _numberOfRecords,
    uint256 _offset,
    Token.Instance memory _token,
    TokenHolder.Instance memory _tokenHolder
  ) internal view returns (Instance memory record) {
    if (_numberOfRecords == 0) {
      record.blockNumber = _blockNumber;
      record.lambda = 0;
      return record;
    }

    if (_numberOfRecords == 1) {
      uint256 index = SafeMath.add(_offset, _numberOfRecords);
      record.blockNumber = getUint(
        keccak256(abi.encode(_token.uuid, _tokenHolder.account, index, 'blockNumber'))
      );

      if (record.blockNumber == 0 || record.blockNumber > _blockNumber) {
        if (_offset == 0) {
          record.blockNumber = getUint(
            keccak256(abi.encode(_token.uuid, _tokenHolder.account, 0, 'blockNumber'))
          );
          if (record.blockNumber == 0 || record.blockNumber > _blockNumber) {
            record.lambda = 0;
            return record;
          }
          record.lambda = getUint(
            keccak256(abi.encode(_token.uuid, _tokenHolder.account, 0, 'lambda'))
          );
          return record;
        }
        return
          _findByBlockNumber(
            _blockNumber,
            _numberOfRecords,
            SafeMath.sub(_offset, 1),
            _token,
            _tokenHolder
          );
      }
      record.lambda = getUint(
        keccak256(abi.encode(_token.uuid, _tokenHolder.account, index, 'lambda'))
      );
      return record;
    }

    uint256 half = SafeMath.div(_numberOfRecords, 2);
    uint256 middleIndex = SafeMath.add(half, _offset);
    record.blockNumber = getUint(
      keccak256(abi.encode(_token.uuid, _tokenHolder.account, middleIndex, 'blockNumber'))
    );

    if (record.blockNumber > _blockNumber) {
      return _findByBlockNumber(_blockNumber, half, _offset, _token, _tokenHolder);
    }

    if (record.blockNumber < _blockNumber) {
      return _findByBlockNumber(_blockNumber, half, middleIndex, _token, _tokenHolder);
    }

    record.lambda = getUint(
      keccak256(abi.encode(_token.uuid, _tokenHolder.account, middleIndex, 'lambda'))
    );
    return record;
  }
}
