// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import "./libraries/StorageLib.sol";

/// @author ElasticDAO - https://ElasticDAO.org
/// @title  Implementation of Eternal Storage(https://fravoll.github.io/solidity-patterns/eternal_storage.html)
/// @notice This contract is used for storing contract network data
/// @dev ElasticDAO network contracts can read/write from this contract
contract EternalStorage {
  struct Storage {
    mapping(bytes32 => uint256) uIntStorage;
    mapping(bytes32 => string) stringStorage;
    mapping(bytes32 => address) addressStorage;
    mapping(bytes32 => address[]) addressArrayStorage;
    mapping(bytes32 => bool) boolStorage;
    mapping(bytes32 => int256) intStorage;
    mapping(bytes32 => bytes) bytesStorage;
  }

  Storage internal s;

  //////////////////////////////
  /// @notice Getter Functions
  /////////////////////////////

  /// @notice Get stored contract data in uint256 format
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @return uint256 _value from storage _key location
  function getUint(bytes32 _key) external view returns (uint256) {
    return s.uIntStorage[_key];
  }

  /// @notice Get stored contract data in string format
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @return string _value from storage _key location
  function getString(bytes32 _key) external view returns (string memory) {
    require(_key[0] != 0, "ElasticDAO: Zero Address");

    return s.stringStorage[_key];
  }

  /// @notice Get stored contract data in address format
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @return address _value from storage _key location
  function getAddress(bytes32 _key) external view returns (address) {
    return s.addressStorage[_key];
  }

  /// @notice Get stored contract data in address format
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @return address[] _value from storage _key location
  function getAddressArray(bytes32 _key) external view returns (address[]) {
    return s.addressArrayStorage[_key];
  }

  /// @notice Get stored contract data in bool format
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @return bool _value from storage _key location
  function getBool(bytes32 _key) external view returns (bool) {
    return s.boolStorage[_key];
  }

  /// @notice Get stored contract data in int256 format
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @return int256 _value from storage _key location
  function getInt(bytes32 _key) external view returns (int256) {
    return s.intStorage[_key];
  }

  /// @notice Get stored contract data in bytes format
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @return bytes _value from storage _key location
  function getBytes(bytes32 _key) external view returns (bytes memory) {
    require(_key[0] != 0, "ElasticDAO: Zero Address");

    return s.bytesStorage[_key];
  }

  //////////////////////////////
  /// @notice Setter Functions
  /////////////////////////////

  /// @notice Store contract data in uint256 format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @param _value uint256 value
  function setUint(bytes32 _key, uint256 _value) external {
    s.uIntStorage[_key] = _value;
  }

  /// @notice Store contract data in string format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @param _value string value
  function setString(bytes32 _key, string calldata _value) external {
    s.stringStorage[_key] = _value;
  }

  /// @notice Store contract data in address format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @param _value address value
  function setAddress(bytes32 _key, address _value) external {
    s.addressStorage[_key] = _value;
  }

  /// @notice Store contract data in address format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @param _value address value
  function setAddressArray(bytes32 _key, address[] _value) external {
    s.addressArrayStorage[_key] = _value;
  }

  /// @notice Store contract data in bool format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @param _value bool value
  function setBool(bytes32 _key, bool _value) external {
    s.boolStorage[_key] = _value;
  }

  /// @notice Store contract data in int256 format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @param _value int256 value
  function setInt(bytes32 _key, int256 _value) external {
    s.intStorage[_key] = _value;
  }

  /// @notice Store contract data in bytes format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  /// @param _value bytes value
  function setBytes(bytes32 _key, bytes calldata _value) external {
    s.bytesStorage[_key] = _value;
  }

  //////////////////////////////
  /// @notice Delete Functions
  /////////////////////////////

  /// @notice Delete stored contract data in bytes format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  function deleteUint(bytes32 _key) external {
    delete s.uIntStorage[_key];
  }

  /// @notice Delete stored contract data in string format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  function deleteString(bytes32 _key) external {
    require(_key[0] != 0, "ElasticDAO: Zero Address");

    delete s.stringStorage[_key];
  }

  /// @notice Delete stored contract data in address format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  function deleteAddress(bytes32 _key) external {
    delete s.addressStorage[_key];
  }

  /// @notice Delete stored contract data in address format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  function deleteAddressArray(bytes32 _key) external {
    delete s.addressArrayStorage[_key];
  }

  /// @notice Delete stored contract data in bool format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  function deleteBool(bytes32 _key) external {
    delete s.boolStorage[_key];
  }

  /// @notice Delete stored contract data in int256 format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  function deleteInt(bytes32 _key) external {
    delete s.intStorage[_key];
  }

  /// @notice Delete stored contract data in bytes format
  /// @dev restricted to latest ElasticDAO Networks contracts
  /// @param _key bytes32 location should be keccak256 and abi.encodePacked
  function deleteBytes(bytes32 _key) external {
    delete s.bytesStorage[_key];
  }
}
