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
contract Balance is EternalModel {
  struct Instance {
    address uuid;
    uint256 blockNumber;
    uint256 index; // tokenHolder.counter
    uint256 k;
    uint256 m;
    uint256 lambda;
    Token.Instance token;
  }

  // TODO: Clean interface from deserialze and serialize

  function deserialize(
    address _uuid,
    uint256 _blockNumber,
    address _tokenModelAddress,
    address _balanceMultipliersModelAddress
  ) public view returns (Instance memory record) {
    record.tokenHolder = _tokenHolder;
    record.blockNumber = _blockNumber;

    return findByBlockNumber(_uuid, _tokenHolder, _blockNumber, _tokenHolder.counter, 0);
  }

  function exists(
    address _tokenAddress,
    address _uuid,
    uint256 _index
  ) external view returns (bool recordExists) {
    return true;
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record, Ecosystem.Instance memory ecosystem) external {
    setUint(
      keccak256(abi.encode(record.token.uuid, record.uuid, record.index, 'blockNumber')),
      record.blockNumber
    );
    setUint(
      keccak256(abi.encode(record.token.uuid, record.uuid, record.index, 'lambda')),
      record.lambda
    );

    BalanceMultipliers.Instance memory balanceMultipliers;
    balanceMultipliers.uuid = record.token.uuid;
    balanceMultipliers.blockNumber = record.blockNumber;
    balanceMultipliers.k = record.k;
    balanceMultipliers.m = record.m;
    balanceMultipliers.index = record.token.counter;
    BalanceMultipliers(ecosystem.balanceMultipliersModelAddress).serialize(balanceMultipliers);
    Token(ecosystem.tokenModelAddress).incrementCounter(_token.uuid);

    setBool(keccak256(abi.encode('exists', record.token.uuid, record.uuid, record.index)), true);
  }

  function findByBlockNumber(
    address _uuid,
    address _account,
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
      uint256 index = SafeMath.add(_offset, id);
      record.blockNumber = getUint(keccak256(abi.encode(_uuid, id, 'blockNumber')));

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
        return findByBlockNumber(_uuid, _blockNumber, SafeMath.sub(_offset, 1), _numberOfRecords);
      }
      record.k = getUint(keccak256(abi.encode(_uuid, id, 'k')));
      record.m = getUint(keccak256(abi.encode(_uuid, id, 'm')));
      return record;
    }

    uint256 half = SafeMath.div(id, 2);
    uint256 middleId = SafeMath.add(half, _offset);
    record.blockNumber = getUint(keccak256(abi.encode(_uuid, middleId, 'blockNumber')));

    if (record.blockNumber > _blockNumber) {
      return findByBlockNumber(_uuid, _blockNumber, _offset, half);
    }

    if (record.blockNumber < _blockNumber) {
      return findByBlockNumber(_uuid, _blockNumber, middleId, half);
    }

    record.k = getUint(keccak256(abi.encode(_uuid, 0, 'k')));
    record.m = getUint(keccak256(abi.encode(_uuid, 0, 'm')));
    return record;
  }

  function _exists(
    address _tokenAddress,
    address _uuid,
    uint256 _index
  ) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _tokenAddress, _uuid, _index)));
  }
}
