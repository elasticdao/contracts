// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './Ecosystem.sol';
import './EternalModel.sol';
import '../libraries/SafeMath.sol';
import '../services/ReentryProtection.sol';

/**
 * @author ElasticDAO - https://ElasticDAO.org
 * @notice This contract is used for storing core DAO data
 * @dev ElasticDAO network contracts can read/write from this contract
 */
contract DAO is EternalModel, ReentryProtection {
  struct Instance {
    address uuid;
    address[] summoners;
    bool summoned;
    string name;
    uint256 maxVotingLambda;
    uint256 numberOfSummoners;
    Ecosystem.Instance ecosystem;
  }

  event Serialized(address indexed uuid);

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
      record.maxVotingLambda = getUint(keccak256(abi.encode(_uuid, 'maxVotingLambda')));
      record.name = getString(keccak256(abi.encode(_uuid, 'name')));
      record.numberOfSummoners = getUint(keccak256(abi.encode(_uuid, 'numberOfSummoners')));
      record.summoned = getBool(keccak256(abi.encode(_uuid, 'summoned')));
    }

    return record;
  }

  /**
   * @dev checks if @param _uuid exists
   * @param _uuid - address of the unique user ID
   * @return recordExists bool
   */
  function exists(address _uuid) external view returns (bool) {
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
   * @param _record Instance
   */
  function serialize(Instance memory _record) external preventReentry {
    require(msg.sender == _record.uuid, 'ElasticDAO: Unauthorized');

    setUint(keccak256(abi.encode(_record.uuid, 'maxVotingLambda')), _record.maxVotingLambda);
    setString(keccak256(abi.encode(_record.uuid, 'name')), _record.name);
    setBool(keccak256(abi.encode(_record.uuid, 'summoned')), _record.summoned);

    if (_record.summoners.length > 0) {
      _record.numberOfSummoners = _record.summoners.length;
      setUint(keccak256(abi.encode(_record.uuid, 'numberOfSummoners')), _record.numberOfSummoners);
      for (uint256 i = 0; i < _record.numberOfSummoners; i += 1) {
        setBool(keccak256(abi.encode(_record.uuid, 'summoner', _record.summoners[i])), true);
        setAddress(keccak256(abi.encode(_record.uuid, 'summoners', i)), _record.summoners[i]);
      }
    }

    setBool(keccak256(abi.encode(_record.uuid, 'exists')), true);

    emit Serialized(_record.uuid);
  }

  function _exists(address _uuid) internal view returns (bool) {
    return getBool(keccak256(abi.encode(_uuid, 'exists')));
  }
}
