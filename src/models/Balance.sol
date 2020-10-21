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
    uint256 id; // counter
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

    record.k = findByBlockNumber(_blockNumber, 0, _tokenHolder.counter, _tokenHolder, 'k');
    record.lambda = findByBlockNumber(
      _blockNumber,
      0,
      _tokenHolder.counter,
      _tokenHolder,
      'lambda'
    );
    record.m = findByBlockNumber(_blockNumber, 0, _tokenHolder.counter, _tokenHolder, 'm');

    return record;
  }

  function exists(
    address _tokenAddress,
    address _uuid,
    uint256 _id
  ) external view returns (bool recordExists) {
    return true;
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setUint(
      keccak256(abi.encode(record.tokenAddress, record.uuid, record.id, 'blockNumber')),
      record.blockNumber
    );
    setUint(
      keccak256(abi.encode(record.tokenAddress, record.uuid, record.id, 'lambda')),
      record.lambda
    );

    BalanceMultipliers.Instance memory balanceMultipliers;
    balanceMultipliers.uuid = record.tokenAddress;
    balanceMultipliers.blockNumber = record.blockNumber;
    balanceMultipliers.k = record.k;
    balanceMultipliers.m = record.m;

    balanceMultiplersContract.serialize(balanceMultipliers);

    setBool(keccak256(abi.encode('exists', record.tokenAddress, record.uuid, record.id)), true);
  }

  function findByBlockNumber(
    uint256 _blockNumber,
    uint256 _offset,
    uint256 _numberOfRecords,
    TokenHolder.Instance memory _tokenHolder,
    string _key
  ) internal returns (Instance memory) {
    getUint(keccak256(abi.encode(record.tokenAddress, record.blockNumber, 'k')));

    if (_numberOfRecords == 1) {
      Instance memory instance = deserialize(
        _tokenHolder.tokenAddress,
        _tokenHolder.uuid,
        SafeMath.add(_numberOfRecords, _offset)
      );
      if (instance.blockNumber > _blockNumber) {
        if (_offset == 0) {
          if (_key == 'lambda') {
            return getUint(keccak256(abi.encode(record.tokenAddress, record.blockNumber, 'k')));
          }
          return getUint(keccak256(abi.encode(record.tokenAddress, record.blockNumber, _key)));

          return deserialize(_tokenHolder.tokenAddress, _tokenHolder.uuid, 0);
        }
        return
          findByBlockNumber(
            _tokenHolder.tokenAddress,
            _tokenHolder.uuid,
            _blockNumber,
            1,
            SafeMath.sub(_offset, 1)
          );
      }
      return instance;
    }

    uint256 half = SafeMath.add(SafeMath.div(_numberOfRecords, 2), _offset);
    uint256 blockNumber = getUint(keccak256(abi.encode(_tokenAddress, _uuid, half, 'blockNumber')));

    if (blockNumber < _targetNumber) {
      return
        findByBlockNumber(
          _tokenAddress,
          _uuid,
          _targetNumber,
          SafeMath.div(_numberOfRecords, 2),
          SafeMath.add(_offset, half)
        );
    }

    if (blockNumber > _targetNumber) {
      return
        findByBlockNumber(
          _tokenAddress,
          _uuid,
          _targetNumber,
          SafeMath.div(_numberOfRecords, 2),
          _offset
        );
    }

    return deserialize(_tokenAddress, _uuid, half);
  }

  // private

  function _exists(
    address _tokenAddress,
    address _uuid,
    uint256 _id
  ) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _tokenAddress, _uuid, _id)));
  }
}
