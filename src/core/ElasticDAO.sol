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
  address internal deployer;
  address[] public summoners;

  event ElasticGovernanceTokenDeployed(address indexed tokenAddress);

  modifier onlyAfterSummoning() {
    DAO.Instance memory dao = _getDAO();
    require(dao.summoned, 'ElasticDAO: DAO must be summoned');
    _;
  }
  modifier onlyAfterTokenInitialized() {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    bool tokenInitialized = Token(_getEcosystem().tokenModelAddress).exists(
      ecosystem.governanceTokenAddress,
      ecosystem
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
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    DAO daoContract = DAO(ecosystem.daoModelAddress);
    DAO.Instance memory dao = daoContract.deserialize(address(this), ecosystem);
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
    deployer = msg.sender;
    Ecosystem.Instance memory defaults = Ecosystem(_ecosystemModelAddress).deserialize(address(0));
    summoners = _summoners;

    Configurator configurator = Configurator(defaults.configuratorAddress);
    Ecosystem.Instance memory ecosystem = configurator.buildEcosystem(defaults);
    configurator.buildDAO(_summoners, _name, _numberOfSummoners, ecosystem);
  }

  function exitDAO(uint256 _deltaLambda) public onlyAfterSummoning {
    // burn the shares
    Token.Instance memory token = _getToken();
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);
    tokenContract.burnShares(msg.sender, _deltLambda);

    // eth to be transfered = ( deltaLambda/lambda ) * totalEthInTheDAO
    uint256 ratioOfShares = ElasticMath.wdiv(_deltaLambda, token.lambda);
    uint256 ethToBeTransfered = ElasticMath.wmul(ratioOfShares, address(this).balance);

    // transfer the eth
      msg.sender.transfer(ethToBeTransfered);
  }

  function initializeToken(
    string memory _name,
    string memory _symbol,
    uint256 _eByL,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase
  ) external onlyBeforeSummoning {
    require(msg.sender == deployer, 'ElasticDAO: Only deployer can initialize the Token');
    Ecosystem.Instance memory ecosystem = _getEcosystem();

    Token.Instance memory token = Configurator(ecosystem.configuratorAddress).buildToken(
      _name,
      _symbol,
      _eByL,
      _elasticity,
      _k,
      _maxLambdaPurchase,
      ecosystem
    );
    emit ElasticGovernanceTokenDeployed(token.uuid);
  }

  function initializeModule(address _moduleAddress, string memory _name)
    external
  // onlySummoners - TODO: Replace this with a permission
  {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    Registrator registrator = Registrator(ecosystem.registratorAddress);
    registrator.registerModule(_moduleAddress, _name, ecosystem);
  }

  function join(uint256 _deltaLambda) public payable onlyAfterSummoning {
    Token.Instance memory token = _getToken();

    require(
      _deltaLambda <= token.maxLambdaPurchase,
      'ElasticDAO: Cannot purchase that many shares at once'
    );

    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);
    uint256 capitalDelta = ElasticMath.capitalDelta(
      // at this stage address(this).balance has the eth present in it(before function join),
      // along with msg.value
      // hence msg.value is subtracted from capitalDelta because capitalDelta is calculated
      // with the eth present in the contract prior to recieving msg.value
      address(this).balance - msg.value,
      tokenContract.totalSupply()
    );
    uint256 deltaE = ElasticMath.deltaE(
      _deltaLambda,
      capitalDelta,
      token.k,
      token.elasticity,
      token.lambda,
      token.m
    );

    require(deltaE == msg.value, 'ElasticDAO: Incorrect ETH amount');

    // mdash
    uint256 lambdaDash = SafeMath.add(_deltaLambda, token.lambda);
    uint256 mDash = ElasticMath.mDash(lambdaDash, token.lambda, token.m);

    // serialize the token
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    Token tokenStorage = Token(ecosystem.tokenModelAddress);
    token.m = mDash;
    tokenStorage.serialize(token);

    // tokencontract mint shares
    tokenContract.mintShares(msg.sender, _deltaLambda);
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
    uint256 deltaLambda = ElasticMath.wdiv(deltaE, token.eByL);
    ElasticGovernanceToken(token.uuid).mintShares(msg.sender, deltaLambda);
  }

  function summon(uint256 _deltaLambda) public onlyBeforeSummoning onlySummoners {
    require(address(this).balance > 0, 'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio');

    Ecosystem.Instance memory ecosystem = _getEcosystem();
    DAO daoContract = DAO(ecosystem.daoModelAddress);
    DAO.Instance memory dao = daoContract.deserialize(address(this), ecosystem);
    Token.Instance memory token = Token(ecosystem.tokenModelAddress).deserialize(
      ecosystem.governanceTokenAddress,
      ecosystem
    );
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);

    for (uint256 i = 0; i < dao.numberOfSummoners; i = SafeMath.add(i, 1)) {
      tokenContract.mintShares(daoContract.getSummoner(dao, i), _deltaLambda);
    }
    dao.summoned = true;
    daoContract.serialize(dao);
  }

  // Getters

  function getDAO() public view returns (DAO.Instance memory) {
    return _getDAO();
  }

  function getEcosystem() public view returns (Ecosystem.Instance memory) {
    return _getEcosystem();
  }

  // Private

  function _getDAO() internal view returns (DAO.Instance memory) {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    return DAO(ecosystem.daoModelAddress).deserialize(address(this), ecosystem);
  }

  function _getEcosystem() internal view returns (Ecosystem.Instance memory) {
    return Ecosystem(ecosystemModelAddress).deserialize(address(this));
  }

  function _getToken() internal view returns (Token.Instance memory) {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    return
      Token(ecosystem.tokenModelAddress).deserialize(ecosystem.governanceTokenAddress, ecosystem);
  }

  receive() external payable {}

  fallback() external payable {}
}
