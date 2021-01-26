// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './Ecosystem.sol';
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
    Ecosystem.Instance ecosystem;
  }

  /**
   * @dev deserializes Instance struct
   * @param _uuid - address of the unique user ID
   * @return record Instance
   */
  function deserialize(address _uuid, Ecosystem.Instance memory _ecosystem)
    external
    view
    returns (Instance memory record)
  {
    record.uuid = _uuid;
    record.ecosystem = _ecosystem;

    if (_exists(_uuid)) {
      record.name = getString(keccak256(abi.encode(_uuid, 'name')));
      record.numberOfSummoners = getUint(keccak256(abi.encode(_uuid, 'numberOfSummoners')));
      record.summoned = getBool(keccak256(abi.encode(_uuid, 'summoned')));
    }

    return record;
  }

  /**
   * @dev checks if @param _uuid and @param _name exist
   * @param _uuid - address of the unique user ID
   * @return recordExists bool
   */
  function exists(address _uuid, Ecosystem.Instance memory) external view returns (bool) {
    return _exists(_uuid);
  }

  function getSummoner(Instance memory _dao, uint256 _index) external view returns (address) {
    return getAddress(keccak256(abi.encode(_dao.uuid, 'summoners', _index)));
  }

  /**
   * @dev checks if @param _uuid where _uuid is msg.sender - is a Summoner
   * @param _dao DAO.Instance
   * @param _summonerAddress address
   * @return bool
   */
  function isSummoner(Instance memory _dao, address _summonerAddress) external view returns (bool) {
    return getBool(keccak256(abi.encode(_dao.uuid, 'summoner', _summonerAddress)));
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    require(
      msg.sender == record.uuid || msg.sender == record.ecosystem.configuratorAddress,
      'ElasticDAO: Unauthorized'
    );

    setString(keccak256(abi.encode(record.uuid, 'name')), record.name);
    setUint(keccak256(abi.encode(record.uuid, 'numberOfSummoners')), record.numberOfSummoners);
    setBool(keccak256(abi.encode(record.uuid, 'summoned')), record.summoned);

    if (record.summoners.length == record.numberOfSummoners) {
      for (uint256 i = 0; i < record.numberOfSummoners; i = SafeMath.add(i, 1)) {
        setBool(keccak256(abi.encode(record.uuid, 'summoner', record.summoners[i])), true);
        setAddress(keccak256(abi.encode(record.uuid, 'summoners', i)), record.summoners[i]);
      }
    }

    setBool(keccak256(abi.encode(record.uuid, 'exists')), true);
  }

  function _exists(address _uuid) internal view returns (bool) {
    return getBool(keccak256(abi.encode(_uuid, 'exists')));
  }
}
