// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../services/ReentryProtection.sol';

/**
 * @title ElasticDAO ecosystem
 * @author ElasticDAO - https://ElasticDAO.org
 * @notice This contract is used for storing core dao data
 * @dev ElasticDAO network contracts can read/write from this contract
 * @dev Serialize - Translation of data from the concerned struct to key-value pairs
 * @dev Deserialize - Translation of data from the key-value pairs to a struct
 */
contract Ecosystem is EternalModel, ReentryProtection {
  struct Instance {
    address daoAddress;
    // Models
    address daoModelAddress;
    address ecosystemModelAddress;
    address tokenHolderModelAddress;
    address tokenModelAddress;
    // Tokens
    address governanceTokenAddress;
  }

  event Serialized(address indexed _daoAddress);

  /**
   * @dev deserializes Instance struct
   * @param _daoAddress - address of the unique user ID
   * @return record Instance
   */
  function deserialize(address _daoAddress) external view returns (Instance memory record) {
    if (_exists(_daoAddress)) {
      record.daoAddress = _daoAddress;
      record.daoModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'daoModelAddress'))
      );
      record.ecosystemModelAddress = address(this);
      record.governanceTokenAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'governanceTokenAddress'))
      );
      record.tokenHolderModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'tokenHolderModelAddress'))
      );
      record.tokenModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'tokenModelAddress'))
      );
    }

    return record;
  }

  /**
   * @dev checks if @param _daoAddress
   * @param _daoAddress - address of the unique user ID
   * @return recordExists bool
   */
  function exists(address _daoAddress) external view returns (bool recordExists) {
    return _exists(_daoAddress);
  }

  /**
   * @dev serializes Instance struct
   * @param _record Instance
   */
  function serialize(Instance memory _record) external preventReentry {
    bool recordExists = _exists(_record.daoAddress);

    require(
      msg.sender == _record.daoAddress || (_record.daoAddress == address(0) && !recordExists),
      'ElasticDAO: Unauthorized'
    );

    setAddress(
      keccak256(abi.encode(_record.daoAddress, 'daoModelAddress')),
      _record.daoModelAddress
    );
    setAddress(
      keccak256(abi.encode(_record.daoAddress, 'governanceTokenAddress')),
      _record.governanceTokenAddress
    );
    setAddress(
      keccak256(abi.encode(_record.daoAddress, 'tokenHolderModelAddress')),
      _record.tokenHolderModelAddress
    );
    setAddress(
      keccak256(abi.encode(_record.daoAddress, 'tokenModelAddress')),
      _record.tokenModelAddress
    );

    setBool(keccak256(abi.encode(_record.daoAddress, 'exists')), true);

    emit Serialized(_record.daoAddress);
  }

  function _exists(address _daoAddress) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode(_daoAddress, 'exists')));
  }
}
