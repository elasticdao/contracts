// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../libraries/ElasticMath.sol';
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
  modifier onlyAfterTokenInitialized() {
    bool tokenInitialized = Token(_getEcosystem().tokenModelAddress).exists(address(this));
    require(tokenInitialized, 'ElasticDAO: Please call initializeToken first.');
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

  function initializeModule(address _moduleAddress, string memory _name)
    external
    onlyBeforeSummoning
    onlySummoners
  {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    Registrator registrator = Registrator(ecosystem.registratorAddress);
    registrator.registerModule(_moduleAddress, _name);
  }

  // Summoning

  function seedSummoning()
    public
    payable
    onlyBeforeSummoning
    onlySummoners
    onlyAfterTokenInitialized
  {
    Token.Instance memory token = _getToken();

    uint256 deltaE = msg.value;
    uint256 deltaLambda = SafeMath.div(SafeMath.div(deltaE, token.capitalDelta), token.k);
    uint256 deltaT = ElasticMath.t(deltaLambda, token.k, token.m);
    ElasticGovernanceToken(token.uuid).mint(msg.sender, deltaT);
  }

  function summon(uint256 _deltaLambda) public onlyBeforeSummoning onlySummoners {
    require(address(this).balance > 0, 'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio');

    DAO.Instance memory dao = _getDAO();
    Token.Instance memory token = _getToken();
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);

    uint256 deltaT = ElasticMath.t(_deltaLambda, token.k, token.m);

    for (uint256 i = 0; i < dao.numberOfSummoners; SafeMath.add(i, 1)) {
      tokenContract.mint(dao.summoners[i], deltaT);
    }

    dao.summoned = true;
    DAO(_getEcosystem().daoModelAddress).serialize(dao);
  }

  // Getters

  function getModuleAddress(string memory _name) external view returns (address) {
    return _getElasticModule(_name).contractAddress;
  }

  // Private

  function _getDAO() internal view returns (DAO.Instance memory dao) {
    dao = DAO(_getEcosystem().daoModelAddress).deserialize(address(this));
  }

  function _getEcosystem() internal view returns (Ecosystem.Instance memory ecosystem) {
    ecosystem = Ecosystem(ecosystemModelAddress).deserialize(address(this));
  }

  function _getElasticModule(string memory _name)
    internal
    view
    returns (ElasticModule.Instance memory elasticModule)
  {
    elasticModule = ElasticModule(_getEcosystem().elasticModuleModelAddress).deserialize(
      address(this),
      _name
    );
  }

  function _getToken() internal view returns (Token.Instance memory token) {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    token = Token(ecosystem.tokenModelAddress).deserialize(ecosystem.governanceTokenAddress);
  }

  function _getTokenHolder(address _uuid)
    internal
    view
    returns (TokenHolder.Instance memory tokenHolder)
  {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    tokenHolder = TokenHolder(ecosystem.tokenHolderModelAddress).deserialize(
      _uuid,
      ecosystem.governanceTokenAddress
    );
  }
}
