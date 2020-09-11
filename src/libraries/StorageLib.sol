// SPDX-License-Identifier: GPLv3

pragma solidity ^0.7.0;

library StorageLib {
  /// @notice Format Storage Locations into bytes32
  function formatAddress(string memory _storageLocation, address _value)
    external
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(_storageLocation, _value));
  }

  function formatBool(string memory _storageLocation, bool _value) external pure returns (bytes32) {
    return keccak256(abi.encode(_storageLocation, _value));
  }

  function formatInt(string memory _storageLocation, int256 _value)
    external
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(_storageLocation, _value));
  }

  function formatString(string memory _storageLocation, string memory _value)
    external
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(_storageLocation, _value));
  }

  function formatUint(string memory _storageLocation, uint256 _value)
    external
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(_storageLocation, _value));
  }

  function formatLocation(string memory _location) external pure returns (bytes32) {
    return keccak256(abi.encode(_location));
  }
}
