// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './EternalModel.sol';
import '../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing core dao data
/// @dev ElasticDAO network contracts can read/write from this contract
contract DAO is EternalModel {
  constructor() EternalModel() {}

  struct Instance {
    address uuid;
    address[] summoners;
    bool summoned;
    string name;
    uint256 numberOfSummoners;
  }

  /**
   * @dev deserializes Instance struct
   * @param _uuid - address of the unique user ID
   * @return record Instance
   */
  function deserialize(address _uuid) external view returns (Instance memory record) {
    if (_exists(_uuid)) {
      record.name = getString(keccak256(abi.encode('name', _uuid)));
      record.numberOfSummoners = getUint(keccak256(abi.encode('numberOfSummoners', _uuid)));
      record.summoned = getBool(keccak256(abi.encode('summoned', _uuid)));
      record.uuid = _uuid;
    }

    return record;
  }

  /**
   * @dev checks if @param _uuid and @param _name exist
   * @param _uuid - address of the unique user ID
   * @return recordExists bool
   */
  function exists(address _uuid) external view returns (bool) {
    return _exists(_uuid);
  }

  /**
   * @dev checks if @param _uuid where _uuid is msg.sender - is a Summoner
   * @param _uuid bool
   * @return bool
   */
  function isSummoner(address _uuid) external view returns (bool) {
    bool summonerData = getBool(keccak256(abi.encode('summoner', _uuid)));

    if (summonerData == true) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setBool(keccak256(abi.encode('exists', record.uuid)), true);
    setString(keccak256(abi.encode('name', record.uuid)), record.name);
    setUint(keccak256(abi.encode('numberOfSummoners', record.uuid)), record.numberOfSummoners);
    setBool(keccak256(abi.encode('summoned', record.uuid)), record.summoned);
    for (uint256 i = 0; i < record.numberOfSummoners; i = SafeMath.add(i, 1)) {
      setBool(keccak256(abi.encode('summoner', record.summoners[i])), true);
    }
  }

  function _exists(address _uuid) internal view returns (bool) {
    return getBool(keccak256(abi.encode('exists', _uuid)));
  }
}
