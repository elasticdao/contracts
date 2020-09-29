// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;

import '../libraries/SafeMath.sol';

import '../models/DAO.sol';
import '../models/Ecosystem.sol';
import '../models/Token.sol';

import '../services/Configurator.sol';
import '../services/Registrator.sol';

contract ElasticDAO {
  address internal ecosystemModelAddress;

  modifier onlyAfterSummoning() {
    DAO.Instance memory dao = _getDAO();
    require(dao.summoned, 'ElasticDAO: DAO must be summoned');
    _;
  }
  modifier onlyBeforeSummoning() {
    DAO.Instance memory dao = _getDAO();
    require(dao.summoned == false, 'ElasticDAO: DAO must not be summoned');
    _;
  }
  modifier onlySummoners() {
    DAO.Instance memory dao = _getDAO();
    bool isSummoner = false;
    for (uint256 i = 0; i < dao.numberOfSummoners; SafeMath.add(i, 1)) {
      if (dao.summoners[i] == msg.sender) {
        isSummoner = true;
      }
    }
    require(isSummoner, 'ElasticDAO: Only summoners');
    _;
  }

  constructor(
    address _ecosystemModelAddress,
    address[] memory _summoners,
    string memory _name,
    uint256 _numberOfSummoners
  ) {
    ecosystemModelAddress = _ecosystemModelAddress;
    Ecosystem.Instance memory defaults = Ecosystem(_ecosystemModelAddress).deserialize(address(0));

    Configurator configurator = Configurator(defaults.configuratorAddress);
    configurator.buildDAO(
      _summoners,
      _name,
      _numberOfSummoners,
      configurator.buildEcosystem(defaults)
    );
  }

  function initializeToken(
    string memory _name,
    string memory _symbol,
    uint256 _capitalDelta,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase
  ) external onlyBeforeSummoning onlySummoners {
    Configurator(_getEcosystem().configuratorAddress).buildToken(
      ecosystemModelAddress,
      _name,
      _symbol,
      _capitalDelta,
      _elasticity,
      _k,
      _maxLambdaPurchase
    );
  }

  // function initializeVoteModule(address _voteModuleAddress)
  //   external
  //   onlyBeforeSummoning
  //   onlySummoners
  // {
  //   Ecosystem.Instance memory ecosystem = _getEcosystem();
  //   Registrator registrator = Registrator(ecosystem.registratorAddress);
  //   registrator.registerModule('voteModule', _voteModuleAddress);
  // }

  function _getDAO() internal view returns (DAO.Instance memory dao) {
    dao = DAO(_getEcosystem().daoModelAddress).deserialize(msg.sender);
  }

  function _getEcosystem() internal view returns (Ecosystem.Instance memory ecosystem) {
    ecosystem = Ecosystem(ecosystemModelAddress).deserialize(msg.sender);
  }
}
