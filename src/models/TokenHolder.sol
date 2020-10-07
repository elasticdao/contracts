// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing token data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract TokenHolder is EternalModel {
  struct Instance {
    address uuid;
    address tokenAddress;
    uint256 counter;
    uint256 lambda;
  }

  /**
   * @dev deserializes Instance struct
   * @param _uuid - address of the unique user ID
   * @param _tokenAddress - the address of the token
   * @return record Instance
   */
  function deserialize(address _uuid, address _tokenAddress)
    external
    view
    returns (Instance memory record)
  {
    record.uuid = _uuid;
    record.tokenAddress = _tokenAddress;

    if (_exists(_uuid, _tokenAddress)) {
      record.counter = getUint(keccak256(abi.encode(_tokenAddress, 'counter', _uuid)));
      record.lambda = getUint(keccak256(abi.encode(_tokenAddress, 'lambda', _uuid)));
    }

    return record;
  }

  /**
   * @dev checks if @param _uuid and @param _name exist
   * @param _uuid - address of the unique user ID
   * @param _tokenAddress - the address of the token
   * @return recordExists bool
   */
  function exists(address _uuid, address _tokenAddress) external view returns (bool recordExists) {
    return _exists(_uuid, _tokenAddress);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setUint(keccak256(abi.encode(record.tokenAddress, 'counter', record.uuid)), record.counter);
    setUint(keccak256(abi.encode(record.tokenAddress, 'lambda', record.uuid)), record.lambda);

    setBool(keccak256(abi.encode('exists', record.uuid, record.tokenAddress)), true);
  }

  function _exists(address _uuid, address _tokenAddress) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid, _tokenAddress)));
  }
}
