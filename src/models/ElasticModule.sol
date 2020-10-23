// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './DAO.sol';
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
    string name;
    DAO.Instance dao;
    Ecosystem.Instance ecosystem;
  }

  function deserialize(address _uuid, DAO.Instance memory _dao)
    external
    view
    returns (Instance memory record)
  {
    record.uuid = _uuid;
    record.dao = _dao;
    record.name = getString(keccak256(abi.encode(record.dao.uuid, record.uuid)));

    return record;
  }

  function exists(address _uuid, DAO.Instance memory _dao)
    external
    view
    returns (bool recordExists)
  {
    return _exists(_uuid, _dao);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setAddress(keccak256(abi.encode(record.dao.uuid, record.name, 'contractAddress')), record.uuid);

    setBool(keccak256(abi.encode(record.dao.uuid, record.name, 'exists')), true);
  }

  function _exists(address _uuid, DAO.Instance memory _dao)
    internal
    view
    returns (bool recordExists)
  {
    return getBool(keccak256(abi.encode(_dao.uuid, _uuid, 'exists')));
  }
}
