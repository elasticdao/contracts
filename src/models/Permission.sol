// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './DAO.sol';
import './EternalModel.sol';
import '../libraries/SafeMath.sol';

contract Permission is EternalModel {
  modifier onlyPermitted(
    address _permittedAddress,
    string memory _permission,
    DAO.Instance memory _dao
  ) {
    if (_dao.uuid != _permittedAddress) {
      bool permitted = getBool(keccak256(abi.encode(_dao.uuid, 'set', _permission, msg.sender)));
      require(permitted, 'ElasticDAO: Access Denied');
    }
    _;
  }

  function getCounter(string memory _permission, DAO.Instance memory _dao)
    external
    view
    returns (uint256)
  {
    return _counter(_permission, _dao);
  }

  function getPermittedAddress(
    string memory _permission,
    uint256 _index,
    DAO.Instance memory _dao
  ) external view returns (address) {
    return getAddress(keccak256(abi.encode(_dao.uuid, _permission, _index)));
  }

  function isPermitted(
    address _permittedAddress,
    string memory _permission,
    DAO.Instance memory _dao
  ) external view returns (bool) {
    return getBool(keccak256(abi.encode(_dao.uuid, _permission, _permittedAddress)));
  }

  function permit(
    address _permittedAddress,
    string memory _permission,
    DAO.Instance memory _dao
  ) external onlyPermitted(_permittedAddress, _permission, _dao) returns (bool) {
    setBool(keccak256(abi.encode(_dao.uuid, _permission, _permittedAddress)), true);
    updateIndex(_permittedAddress, true, _permission, _dao);
    return true;
  }

  function revoke(
    address _permittedAddress,
    string memory _permission,
    DAO.Instance memory _dao
  ) external onlyPermitted(_permittedAddress, _permission, _dao) returns (bool) {
    setBool(keccak256(abi.encode(_dao.uuid, _permission, _permittedAddress)), false);
    updateIndex(_permittedAddress, false, _permission, _dao);
    return true;
  }

  function updateIndex(
    address _permittedAddress,
    bool _isPermitted,
    string memory _permission,
    DAO.Instance memory _dao
  ) internal {
    uint256 counter = _counter(_permission, _dao);
    bool alreadySeen = false;
    for (uint256 i = 0; i < counter; i = SafeMath.add(i, 1)) {
      address permittedAddress = getAddress(keccak256(abi.encode(_dao.uuid, _permission, i)));
      if (permittedAddress == _permittedAddress) {
        alreadySeen = true;
        if (_isPermitted == false) {
          setAddress(keccak256(abi.encode(_dao.uuid, _permission, i)), address(0));
        }
      }
    }

    if (alreadySeen == false && _isPermitted) {
      setAddress(keccak256(abi.encode(_dao.uuid, _permission, counter)), _permittedAddress);
      _incrementCounter(_permission, _dao);
    }
  }

  function _counter(string memory _permission, DAO.Instance memory _dao)
    internal
    view
    returns (uint256)
  {
    return getUint(keccak256(abi.encode(_dao.uuid, _permission, 'counter')));
  }

  function _incrementCounter(string memory _permission, DAO.Instance memory _dao)
    internal
    returns (bool)
  {
    uint256 counter = _counter(_permission, _dao);
    setUint(keccak256(abi.encode(_dao.uuid, _permission, 'counter')), SafeMath.add(counter, 1));
    return true;
  }
}
