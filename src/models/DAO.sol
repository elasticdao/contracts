// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing core dao data
/// @dev ElasticDAO network contracts can read/write from this contract
contract DAO is EternalModel {
  struct Instance {
    address uuid;
    address[] summoners;
    bool summoned;
    string name;
    uint256 numberOfSummoners;
  }

  function deserialize(address _uuid) external view returns (Instance memory record) {
    if (_exists(_uuid)) {
      record.name = getString(keccak256(abi.encode('name', _uuid)));
      record.numberOfSummoners = getUint(keccak256(abi.encode('numberOfSummoners', _uuid)));
      record.summoned = getBool(keccak256(abi.encode('summoned', _uuid)));
      record.uuid = _uuid;
      for (uint256 i = 0; i < record.numberOfSummoners; SafeMath.add(i, 1)) {
        record.summoners[i] = getAddress(keccak256(abi.encode('summoner', i, _uuid)));
      }
    }
  }

  function exists(address _uuid) external view returns (bool recordExists) {
    return _exists(_uuid);
  }

  function serialize(Instance memory record) external {
    setBool(keccak256(abi.encode('exists.', record.uuid)), true);
    setString(keccak256(abi.encode('name', record.uuid)), record.name);
    setUint(keccak256(abi.encode('numberOfSummoners', record.uuid)), record.numberOfSummoners);
    setBool(keccak256(abi.encode('summoned', record.uuid)), record.summoned);
    for (uint256 i = 0; i < record.numberOfSummoners; SafeMath.add(i, 1)) {
      setAddress(keccak256(abi.encode('summoner', i, record.uuid)), record.summoners[i]);
    }
  }

  function _exists(address _uuid) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists.', _uuid)));
  }
}
