// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing token balance change data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract BalanceChange is EternalModel {
  constructor() EternalModel() {}

  struct Instance {
    address tokenAddress;
    address uuid;
    bool isIncreasing;
    uint256 blockNumber;
    uint256 deltaLambda;
    uint256 id; // counter
    uint256 k;
    uint256 m;
  }

  /**
   * @dev deserializes Instance struct
   * @param _tokenAddress - address of the token
   * @param _uuid - address of the unique user ID
   * @param _id - the counter value of this change
   * @return record Instance
   */
  function deserialize(
    address _tokenAddress,
    address _uuid,
    uint256 _id
  ) external view returns (Instance memory record) {
    record.id = _id;
    record.tokenAddress = _tokenAddress;
    record.uuid = _uuid;

    if (_exists(_tokenAddress, _uuid, _id)) {
      record.blockNumber = getUint(keccak256(abi.encode(_tokenAddress, _uuid, _id, 'blockNumber')));
      record.deltaLambda = getUint(keccak256(abi.encode(_tokenAddress, _uuid, _id, 'deltaLambda')));
      record.isIncreasing = getBool(
        keccak256(abi.encode(_tokenAddress, _uuid, _id, 'isIncreasing'))
      );
      record.k = getUint(keccak256(abi.encode(_tokenAddress, _uuid, _id, 'k')));
      record.m = getUint(keccak256(abi.encode(_tokenAddress, _uuid, _id, 'm')));
    }

    return record;
  }

  function exists(
    address _tokenAddress,
    address _uuid,
    uint256 _id
  ) external view returns (bool recordExists) {
    return _exists(_tokenAddress, _uuid, _id);
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
      keccak256(abi.encode(record.tokenAddress, record.uuid, record.id, 'deltaLambda')),
      record.deltaLambda
    );
    setBool(
      keccak256(abi.encode(record.tokenAddress, record.uuid, record.id, 'isIncreasing')),
      record.isIncreasing
    );
    setUint(keccak256(abi.encode(record.tokenAddress, record.uuid, record.id, 'k')), record.k);
    setUint(keccak256(abi.encode(record.tokenAddress, record.uuid, record.id, 'm')), record.m);

    setBool(keccak256(abi.encode('exists', record.tokenAddress, record.uuid, record.id)), true);
  }

  function _exists(
    address _tokenAddress,
    address _uuid,
    uint256 _id
  ) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _tokenAddress, _uuid, _id)));
  }
}
