// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../libraries/ElasticMath.sol';
import '../libraries/SafeMath.sol';

import '../models/DAO.sol';
import '../models/Ecosystem.sol';
import '../models/Token.sol';
import '../services/ReentryProtection.sol';

import '../services/Configurator.sol';

contract ElasticDAO is ReentryProtection {
  address public deployer;
  address public ecosystemModelAddress;
  address public controller;
  address[] public summoners;
  uint256 public maxVotingLambda;

  event ElasticGovernanceTokenDeployed(address indexed tokenAddress);
  event MaxVotingLambdaChanged(address indexed daoAddress, bytes32 settingName, uint256 value);
  event ControllerChanged(address indexed daoAddress, bytes32 settingName, address value);
  event ExitDAO(
    address indexed daoAddress,
    address indexed memberAddress,
    uint256 shareAmount,
    uint256 ethAmount
  );
  event JoinDAO(
    address indexed daoAddress,
    address indexed memberAddress,
    uint256 shareAmount,
    uint256 ethAmount
  );
  event SeedDAO(address indexed daoAddress, address indexed summonerAddress, uint256 amount);
  event SummonedDAO(address indexed daoAddress, address indexed summonedBy);

  modifier onlyAfterSummoning() {
    DAO.Instance memory dao = _getDAO();
    require(dao.summoned, 'ElasticDAO: DAO must be summoned');
    _;
  }
  modifier onlyAfterTokenInitialized() {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    bool tokenInitialized =
      Token(_getEcosystem().tokenModelAddress).exists(ecosystem.governanceTokenAddress, ecosystem);
    require(tokenInitialized, 'ElasticDAO: Please call initializeToken first');
    _;
  }
  modifier onlyBeforeSummoning() {
    DAO.Instance memory dao = _getDAO();
    require(dao.summoned == false, 'ElasticDAO: DAO must not be summoned');
    _;
  }
  modifier onlyController() {
    require(msg.sender == controller, 'ElasticDAO: Only controller');
    _;
  }
  modifier onlyDeployer() {
    require(msg.sender == deployer, 'ElasticDAO: Only deployer');
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
  modifier onlyWhenOpen() {
    require(address(this).balance > 0, 'ElasticDAO: This DAO is closed');
    _;
  }

  constructor(
    address _ecosystemModelAddress,
    address _controller,
    address[] memory _summoners,
    string memory _name,
    uint256 _maxVotingLambda
  ) {
    require(
      _ecosystemModelAddress != address(0) || _controller != address(0),
      'ElasticDAO: Address Zero'
    );
    require(_summoners.length > 0, 'ElasticDAO: At least 1 summoner required');

    ecosystemModelAddress = _ecosystemModelAddress;
    controller = _controller;
    deployer = msg.sender;
    Ecosystem.Instance memory defaults = Ecosystem(_ecosystemModelAddress).deserialize(address(0));
    maxVotingLambda = _maxVotingLambda;
    summoners = _summoners;

    Configurator configurator = Configurator(defaults.configuratorAddress);
    Ecosystem.Instance memory ecosystem = configurator.buildEcosystem(defaults);
    bool success = configurator.buildDAO(_summoners, _name, ecosystem);
    require(success, 'ElasticDAO: Build DAO Failed');
  }

  function exit(uint256 _deltaLambda) external onlyAfterSummoning preventReentry {
    // burn the shares
    Token.Instance memory token = _getToken();
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);

    // eth to be transfered = ( deltaLambda/lambda ) * totalEthInTheDAO
    uint256 ratioOfShares = ElasticMath.wdiv(_deltaLambda, token.lambda);
    uint256 ethToBeTransfered = ElasticMath.wmul(ratioOfShares, address(this).balance);
    // transfer the eth
    tokenContract.burnShares(msg.sender, _deltaLambda);
    (bool success, ) = msg.sender.call{ value: ethToBeTransfered }('');
    require(success, 'ElasticDAO: Exit Failed');
    emit ExitDAO(address(this), msg.sender, _deltaLambda, ethToBeTransfered);
  }

  function initializeToken(
    string memory _name,
    string memory _symbol,
    uint256 _eByL,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase
  ) external onlyBeforeSummoning onlyDeployer preventReentry {
    require(msg.sender == deployer, 'ElasticDAO: Only deployer can initialize the Token');
    Ecosystem.Instance memory ecosystem = _getEcosystem();

    Token.Instance memory token =
      Configurator(ecosystem.configuratorAddress).buildToken(
        _name,
        _symbol,
        _eByL,
        _elasticity,
        _k,
        _maxLambdaPurchase,
        ecosystem
      );

    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);
    tokenContract.setBurner(controller);
    tokenContract.setMinter(controller);

    emit ElasticGovernanceTokenDeployed(token.uuid);
  }

  function join(uint256 _deltaLambda)
    external
    payable
    onlyAfterSummoning
    onlyWhenOpen
    preventReentry
  {
    Token.Instance memory token = _getToken();

    require(
      _deltaLambda <= token.maxLambdaPurchase,
      'ElasticDAO: Cannot purchase that many shares at once'
    );

    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);
    uint256 capitalDelta =
      ElasticMath.capitalDelta(
        // at this stage address(this).balance has the eth present in it(before function join),
        // along with msg.value
        // hence msg.value is subtracted from capitalDelta because capitalDelta is calculated
        // with the eth present in the contract prior to recieving msg.value
        address(this).balance - msg.value,
        tokenContract.totalSupply()
      );
    uint256 deltaE =
      ElasticMath.deltaE(
        _deltaLambda,
        capitalDelta,
        token.k,
        token.elasticity,
        token.lambda,
        token.m
      );

    if (deltaE != msg.value) {
      revert('ElasticDAO: Incorrect ETH amount');
    }

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

    emit JoinDAO(address(this), msg.sender, _deltaLambda, msg.value);
  }

  function setController(address _controller) external onlyController preventReentry {
    require(_controller != address(0), 'ElasticDAO: Address Zero');

    controller = _controller;
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(_getToken().uuid);
    tokenContract.setBurner(controller);
    tokenContract.setMinter(controller);

    emit ControllerChanged(address(this), 'setController', controller);
  }

  function setMaxVotingLambda(uint256 _maxVotingLambda) external onlyController preventReentry {
    maxVotingLambda = _maxVotingLambda;

    emit MaxVotingLambdaChanged(address(this), 'setMaxVotingLambda', _maxVotingLambda);
  }

  // Summoning

  function seedSummoning()
    external
    payable
    onlyBeforeSummoning
    onlySummoners
    onlyAfterTokenInitialized
    preventReentry
  {
    Token.Instance memory token = _getToken();

    uint256 deltaE = msg.value;
    uint256 deltaLambda = ElasticMath.wdiv(deltaE, token.eByL);
    ElasticGovernanceToken(token.uuid).mintShares(msg.sender, deltaLambda);

    emit SeedDAO(address(this), msg.sender, deltaLambda);
  }

  function summon(uint256 _deltaLambda) external onlyBeforeSummoning onlySummoners preventReentry {
    require(address(this).balance > 0, 'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio');

    Ecosystem.Instance memory ecosystem = _getEcosystem();
    DAO daoContract = DAO(ecosystem.daoModelAddress);
    DAO.Instance memory dao = daoContract.deserialize(address(this), ecosystem);
    Token.Instance memory token =
      Token(ecosystem.tokenModelAddress).deserialize(ecosystem.governanceTokenAddress, ecosystem);
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);

    // number of summoners can not grow unboundly. it is fixed limit.
    for (uint256 i = 0; i < dao.numberOfSummoners; i = SafeMath.add(i, 1)) {
      tokenContract.mintShares(daoContract.getSummoner(dao, i), _deltaLambda);
    }
    dao.summoned = true;
    daoContract.serialize(dao);

    emit SummonedDAO(address(this), msg.sender);
  }

  // Getters

  function getDAO() external view returns (DAO.Instance memory) {
    return _getDAO();
  }

  function getEcosystem() external view returns (Ecosystem.Instance memory) {
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
