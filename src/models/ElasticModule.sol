// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing token data
/// @dev ElasticDAO network contracts can read/write from this contract
/// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract ElasticModule is EternalModel {
  struct Instance {
    address uuid;
    address contractAddress;
    string name;
  }

  /**
   * @dev deserializes Instance struct
   * @param _uuid - address of the unique user ID
   * @param _name - the name of the module
   * @return record Instance
   */
  function deserialize(address _uuid, string memory _name)
    external
    view
    returns (Instance memory record)
  {
    record.uuid = _uuid;
    record.name = _name;

    if (_exists(_uuid, _name)) {
      record.contractAddress = getAddress(keccak256(abi.encode('contractAddress', _uuid, _name)));
    }

    return record;
  }

  /**
   * @dev checks if @param _uuid and @param _name exist
   * @param _uuid - address of the unique user ID
   * @param _name - the name of the module
   * @return recordExists bool
   */
  function exists(address _uuid, string memory _name) external view returns (bool recordExists) {
    return _exists(_uuid, _name);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setAddress(
      keccak256(abi.encode('contractAddress', record.uuid, record.name)),
      record.contractAddress
    );

    setBool(keccak256(abi.encode('exists', record.uuid, record.name)), true);
  }

  function _exists(address _uuid, string memory _name) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid, _name)));
  }
}
