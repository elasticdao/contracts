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
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    bool tokenInitialized = Token(_getEcosystem().tokenModelAddress).exists(
      ecosystem.governanceTokenAddress
    );
    require(tokenInitialized, 'ElasticDAO: Please call initializeToken first');
    _;
  }
  modifier onlyBeforeSummoning() {
    DAO.Instance memory dao = _getDAO();
    require(dao.summoned == false, 'ElasticDAO: DAO must not be summoned');
    _;
  }
  modifier onlySummoners() {
    DAO daoContract = DAO(_getEcosystem().daoModelAddress);
    DAO.Instance memory dao = daoContract.deserialize(address(this));
    bool summonerCheck = daoContract.isSummoner(dao, msg.sender);

    require(summonerCheck, 'ElasticDAO: Only summoners');
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
    Ecosystem.Instance memory ecosystem = configurator.buildEcosystem(defaults);
    configurator.buildDAO(_summoners, _name, _numberOfSummoners, ecosystem);
  }

  function initializeToken(
    string memory _name,
    string memory _symbol,
    uint256 _capitalDelta,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase
  ) external onlyBeforeSummoning onlySummoners {
    Ecosystem.Instance memory ecosystem = _getEcosystem();

    Configurator(ecosystem.configuratorAddress).buildToken(
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

  function join(uint256 _deltaLambda) public payable onlyAfterSummoning {
    Token.Instance memory token = _getToken();

    require(
      _deltaLambda <= token.maxLambdaPurchase,
      'ElasticDAO: Cannot purchase that many shares at once'
    );

    uint256 deltaE = ElasticMath.deltaE(
      _deltaLambda,
      token.capitalDelta,
      token.k,
      token.elasticity,
      token.lambda,
      token.m
    );

    require(deltaE == msg.value, 'ElasticDAO: Incorrect ETH amount');

    uint256 deltaT = ElasticMath.t(_deltaLambda, token.k, token.m);
    ElasticGovernanceToken(_getEcosystem().governanceTokenAddress).mint(msg.sender, deltaT);
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

    uint256 deltaLambda = ElasticMath.wdiv(ElasticMath.wdiv(deltaE, token.capitalDelta), token.k);

    uint256 deltaT = ElasticMath.t(deltaLambda, token.k, token.m);

    ElasticGovernanceToken(token.uuid).mint(msg.sender, deltaT);
  }

  function summon(uint256 _deltaLambda) public onlyBeforeSummoning onlySummoners {
    require(address(this).balance > 0, 'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio');

    DAO daoContract = DAO(_getEcosystem().daoModelAddress);
    DAO.Instance memory dao = daoContract.deserialize(address(this));
    Token.Instance memory token = _getToken();
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);

    uint256 deltaT = ElasticMath.t(_deltaLambda, token.k, token.m);

    for (uint256 i = 0; i < dao.numberOfSummoners; i = SafeMath.add(i, 1)) {
      tokenContract.mint(daoContract.getSummoner(dao, i), deltaT);
    }

    dao.summoned = true;
    DAO(_getEcosystem().daoModelAddress).serialize(dao);
  }

  // Getters

  function getDAO() public view returns (DAO.Instance memory) {
    return _getDAO();
  }

  function getEcosystem() public view returns (Ecosystem.Instance memory) {
    return _getEcosystem();
  }

  function getModuleAddress(string memory _name) external view returns (address) {
    return _getElasticModule(_name).contractAddress;
  }

  // Private

  function _getDAO() internal view returns (DAO.Instance memory) {
    return DAO(_getEcosystem().daoModelAddress).deserialize(address(this));
  }

  function _getEcosystem() internal view returns (Ecosystem.Instance memory) {
    return Ecosystem(ecosystemModelAddress).deserialize(address(this));
  }

  function _getElasticModule(string memory _name)
    internal
    view
    returns (ElasticModule.Instance memory)
  {
    return
      ElasticModule(_getEcosystem().elasticModuleModelAddress).deserialize(address(this), _name);
  }

  function _getToken() internal view returns (Token.Instance memory) {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    return Token(ecosystem.tokenModelAddress).deserialize(ecosystem.governanceTokenAddress);
  }

  function _getTokenHolder(address _uuid) internal view returns (TokenHolder.Instance memory) {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    return
      TokenHolder(ecosystem.tokenHolderModelAddress).deserialize(
        _uuid,
        ecosystem.governanceTokenAddress
      );
  }
}
