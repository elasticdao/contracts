// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './EternalStorage.sol';
import './ElasticStorage.sol';
import './libraries/ElasticMathLib.sol';
import './libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing Elastic Core data
/// @dev ElasticDAO network contracts can read/write from this contract
/// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract ElasticCoreStorage is EternalStorage {
  constructor(address _owner) EternalStorage(_owner) {}

  /**
   * @dev returns the current state of the DAO with respect to summoning
   * @return isSummoned bool
   */
  function daoSummoned() external view onlyOwner returns (bool isSummoned) {
    return getBool('dao.summoned');
  }

  /**
   * @dev Gets the DAO's data
   * @return dao DAO
   */
  function getDAO() external view onlyOwner returns (ElasticStorage.DAO memory dao) {
    return _deserializeDAO();
  }

  /**
   * @dev checks whether given address is a summoner
   * @param _account - The address of the account
   * @return accountIsSummoner bool
   */
  function isSummoner(address _account) external view onlyOwner returns (bool accountIsSummoner) {
    return getBool(keccak256(abi.encode('dao.summoner', _account)));
  }

  /**
   * @dev Sets the DAO
   * @param _dao - The data of the DAO
   */
  function setDAO(ElasticStorage.DAO memory _dao) external onlyOwner {
    _serializeDAO(_dao);
  }

  /**
   * @dev Sets the summoned state of the DAO to true
   */
  function setSummoned() external onlyOwner {
    setBool('dao.summoned', true);
  }

  /**
   * @dev Sets the summoners of the DAO
   * @param _summoners - an address array of all the summoners
   * @param _initialSummonerShare - the intitial share each summoner gets
   */
  function setSummoners(address[] calldata _summoners, uint256 _initialSummonerShare)
    external
    onlyOwner
  {
    ElasticStorage elasticStorage = ElasticStorage(owner);
    for (uint256 i = 0; i < _summoners.length; i++) {
      setBool(keccak256(abi.encode('dao.summoner', _summoners[i])), true);
      elasticStorage.updateBalance(_summoners[i], true, _initialSummonerShare);
    }
  }

  function _deserializeDAO() internal view returns (ElasticStorage.DAO memory dao) {
    dao.name = getString('dao.name');
    dao.summoned = getBool('dao.summoned');
  }

  function _serializeDAO(ElasticStorage.DAO memory dao) internal {
    setString('dao.name', dao.name);
    setBool('dao.summoned', dao.summoned);
  }
}
