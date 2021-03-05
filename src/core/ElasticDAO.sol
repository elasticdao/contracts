// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../libraries/ElasticMath.sol';
import '../libraries/SafeMath.sol';

import '../models/DAO.sol';
import '../models/Ecosystem.sol';
import '../models/Token.sol';

import '../services/ReentryProtection.sol';

import '@pie-dao/proxy/contracts/PProxy.sol';

/**
 * @dev The ElasticDAO contract outlines and defines all the functionality
 * such as initialize, Join, exit, etc for an elasticDAO.
 *
 * It also serves as the vault for ElasticDAO.
 */
contract ElasticDAO is ReentryProtection {
  address public deployer;
  address public ecosystemModelAddress;
  address public controller;
  address[] public summoners;
  bool public initialized;

  event ElasticGovernanceTokenDeployed(address indexed tokenAddress);
  event MaxVotingLambdaChanged(address indexed daoAddress, bytes32 settingName, uint256 value);
  event ControllerChanged(address indexed daoAddress, bytes32 settingName, address value);
  event ExitDAO(
    address indexed daoAddress,
    address indexed memberAddress,
    uint256 shareAmount,
    uint256 ethAmount
  );
  event FailedToFullyPenalize(
    address indexed memberAddress,
    uint256 attemptedAmount,
    uint256 actualAmount
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

  /**
   * @notice Initializes and builds the ElasticDAO struct
   *
   * @param _ecosystemModelAddress - the address of the ecosystem model
   * @param _controller the address which can control the core DAO functions
   * @param _summoners - an array containing the addresses of the summoners
   * @param _name - the name of the DAO
   * @param _maxVotingLambda - the maximum amount of lambda that can be used to vote in the DAO
   *
   * @dev
   * Requirements:
   * - The DAO cannot already be initialized
   * - The ecosystem model address cannot be the zero address
   * - The DAO must have atleast one summoner to summon the DAO
   */
  function initialize(
    address _ecosystemModelAddress,
    address _controller,
    address[] memory _summoners,
    string memory _name,
    uint256 _maxVotingLambda
  ) external preventReentry {
    require(initialized == false, 'ElasticDAO: Already initialized');
    require(
      _ecosystemModelAddress != address(0) || _controller != address(0),
      'ElasticDAO: Address Zero'
    );
    require(_summoners.length > 0, 'ElasticDAO: At least 1 summoner required');

    Ecosystem.Instance memory defaults = Ecosystem(_ecosystemModelAddress).deserialize(address(0));
    Ecosystem.Instance memory ecosystem = _buildEcosystem(controller, defaults);
    ecosystemModelAddress = ecosystem.ecosystemModelAddress;

    controller = _controller;
    deployer = msg.sender;
    summoners = _summoners;

    bool success = _buildDAO(_summoners, _name, _maxVotingLambda, ecosystem);
    initialized = true;
    require(success, 'ElasticDAO: Build DAO Failed');
  }

  /**
   * @notice initializes the token of the DAO
   *
   * @param _name - name of the token
   * @param _symbol - symbol of the token
   * @param _eByL -the amount of lambda a summoner gets(per ETH) during the seeding phase of the DAO
   * @param _elasticity the value by which the cost of entering the  DAO increases ( on every join )
   * @param _k - is the constant token multiplier
   * it increases the number of tokens that each member of the DAO has with respect to their lambda
   * @param _maxLambdaPurchase - is the maximum amount of lambda that can be purchased per wallet
   *
   * @dev emits ElasticGovernanceTokenDeployed event
   * @dev
   * Requirements:
   * - Only the deployer of the DAO can initialize the Token
   */
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
      _buildToken(
        controller,
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

  /**
   * @notice this function is to be used for exiting the DAO
   * for the underlying ETH value of  _deltaLambda
   *
   * The eth value of _deltaLambda is calculated using:
   *
   * eth to be transfered = ( deltaLambda/lambda ) * totalEthInTheDAO
   *
   * @param _deltaLambda - the amount of lambda the address exits with
   *
   * Requirement:
   * - ETH transfer must be successful
   * @dev emits ExitDAO event
   */
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

  /**
   * @notice this function is used to join the DAO after it has been summoned
   * Joining the DAO is syntactically equal to minting _deltaLambda for the function caller.
   *
   * Based on the current state of the DAO, capitalDelta, deltaE, mDash are calulated,
   * after which  _deltaLambda is minted for the address calling the function.
   *
   * @param _deltaLambda - the amount of lambda minted to the address
   *
   * @dev documentation and further math regarding capitalDelta, deltaE,
   * mDash can be found at ../libraries/ElasticMath.sol
   * @dev emits the JoinDAO event
   *
   * @dev Requirements:
   * The amount of shares being purchased has to be lower than or equal to maxLambdaPurchase
   * (The value of maxLambdaPurchase is set during the initialzing of the DAO)
   * The correct value of ETH, calculated via deltaE,
   * must be sent in the transaction by the calling address
   * The token contract should be successfully be able to mint  _deltaLambda
   */
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
      'ElasticDAO: Cannot purchase those many lambda at once'
    );

    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);
    uint256 capitalDelta =
      ElasticMath.capitalDelta(
        // the current totalBalance of the DAO is inclusive of msg.value,
        // capitalDelta is to be calculated without the msg.value
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
    bool success = tokenContract.mintShares(msg.sender, _deltaLambda);
    require(success, 'ElasticDAO: Mint Shares Failed during Join');
    emit JoinDAO(address(this), msg.sender, _deltaLambda, msg.value);
  }

  /**
   * @notice penalizes @param _addresses with @param _amounts respectively
   *
   * @param _addresses - an array of addresses
   * @param _amounts - an array containing the amounts each address has to be penalized respectively
   *
   * @dev Requirement:
   * - Each address must have a corresponding amount to be penalized with
   */
  function penalize(address[] memory _addresses, uint256[] memory _amounts)
    external
    onlyController
    preventReentry
  {
    require(
      _addresses.length == _amounts.length,
      'ElasticDAO: An amount is required for each address'
    );

    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(_getToken().uuid);

    for (uint256 i = 0; i < _addresses.length; i += 1) {
      uint256 lambda = tokenContract.balanceOfInShares(_addresses[i]);

      if(lambda < _amounts[i]) {
        if(lambda != 0) {
          tokenContract.burnShares(_addresses[i], lambda);
        }

        FailedToFullyPenalize(_addresses[i], _amounts[i], lambda);
      } else {
        tokenContract.burnShares(_addresses[i], _amounts[i]);
      }
    }
  }

  /**
   * @notice rewards @param _addresess with @param _amounts respectively
   *
   * @param _addresses - an array of addresses
   * @param _amounts - an array containing the amounts each address has to be rewarded respectively
   *
   * @dev Requirement:
   * - Each address must have a corresponding amount to be rewarded with
   */
  function reward(address[] memory _addresses, uint256[] memory _amounts)
    external
    onlyController
    preventReentry
  {
    require(
      _addresses.length == _amounts.length,
      'ElasticDAO: An amount is required for each address'
    );

    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(_getToken().uuid);

    for (uint256 i = 0; i < _addresses.length; i += 1) {
      tokenContract.mintShares(_addresses[i], _amounts[i]);
    }
  }

  /**
   * @notice sets the controller of the DAO,
   * The controller of the DAO handles various responsibilities of the DAO,
   * such as burning and minting tokens on behalf of the DAO
   *
   * @param _controller - the new address of the controller of the DAO
   *
   * @dev emits ControllerChanged event
   * @dev Requirements:
   * - The controller must not be the 0 address
   * - The controller of the DAO should successfully be set as the burner of the tokens of the DAO
   * - The controller of the DAO should successfully be set as the minter of the tokens of the DAO
   */
  function setController(address _controller) external onlyController preventReentry {
    require(_controller != address(0), 'ElasticDAO: Address Zero');

    controller = _controller;

    // Update minter / burner
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(_getToken().uuid);
    bool success = tokenContract.setBurner(controller);
    require(success, 'ElasticDAO: Set Burner failed during setController');
    success = tokenContract.setMinter(controller);
    require(success, 'ElasticDAO: Set Minter failed during setController');

    emit ControllerChanged(address(this), 'setController', controller);
  }

  /**
   * @notice sets the max voting lambda value for the DAO
   * @param _maxVotingLambda - the value of the maximum amount of lambda that can be used for voting
   * @dev emits MaxVotingLambda event
   */
  function setMaxVotingLambda(uint256 _maxVotingLambda) external onlyController preventReentry {
    Ecosystem.Instance memory ecosystem = _getEcosystem();
    DAO daoStorage = DAO(ecosystem.daoModelAddress);
    DAO.Instance memory dao = daoStorage.deserialize(address(this), ecosystem);
    dao.maxVotingLambda = _maxVotingLambda;
    daoStorage.serialize(dao);

    emit MaxVotingLambdaChanged(address(this), 'setMaxVotingLambda', _maxVotingLambda);
  }

  /**
   * @notice seeds the DAO,
   * Essentially transferring of ETH by a summoner address, in return for lambda is seeding the DAO,
   * The lambda receieved is given by:
   * Lambda = Eth  / eByL
   *
   * @dev seeding of the DAO occurs after the DAO has been initialized,
   * and before the DAO has been summoned
   * @dev emits the SeedDAO event
   */
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

  /**
   * @notice summons the DAO,
   * Summoning the DAO results in all summoners getting _deltaLambda
   * after which people can enter the DAO using the join function
   *
   * @param _deltaLambda - the amount of lambda each summoner address receives
   *
   * @dev emits SummonedDAO event
   * @dev Requirement:
   * The DAO must be seeded with ETH during the seeding phase
   * (This is to facilitate capitalDelta calculations after the DAO has been summoned).
   *
   * @dev documentation and further math regarding capitalDelta
   * can be found at ../libraries/ElasticMath.sol
   */
  function summon(uint256 _deltaLambda) external onlyBeforeSummoning onlySummoners preventReentry {
    require(address(this).balance > 0, 'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio');

    Ecosystem.Instance memory ecosystem = _getEcosystem();
    DAO daoContract = DAO(ecosystem.daoModelAddress);
    DAO.Instance memory dao = daoContract.deserialize(address(this), ecosystem);
    Token.Instance memory token =
      Token(ecosystem.tokenModelAddress).deserialize(ecosystem.governanceTokenAddress, ecosystem);
    ElasticGovernanceToken tokenContract = ElasticGovernanceToken(token.uuid);

    // number of summoners can not grow unboundly. it is fixed limit.
    for (uint256 i = 0; i < dao.numberOfSummoners; i += 1) {
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

  /**
   * @dev creates DAO.Instance record
   * @param _summoners addresses of the summoners
   * @param _name name of the DAO
   * @param _ecosystem instance of Ecosystem the DAO uses
   * @param _maxVotingLambda - the maximum amount of lambda that can be used to vote in the DAO
   * @return bool true
   */
  function _buildDAO(
    address[] memory _summoners,
    string memory _name,
    uint256 _maxVotingLambda,
    Ecosystem.Instance memory _ecosystem
  ) internal returns (bool) {
    DAO daoStorage = DAO(_ecosystem.daoModelAddress);
    DAO.Instance memory dao;

    dao.uuid = address(this);
    dao.ecosystem = _ecosystem;
    dao.maxVotingLambda = _maxVotingLambda;
    dao.name = _name;
    dao.summoned = false;
    dao.summoners = _summoners;
    daoStorage.serialize(dao);

    return true;
  }

  /**
   * @dev Deploys proxies leveraging the implementation contracts found on the
   * default Ecosystem.Instance record.
   * @param _controller the address which can control the core DAO functions
   * @param _defaults instance of Ecosystem with the implementation addresses
   * @return ecosystem Ecosystem.Instance
   */
  function _buildEcosystem(address _controller, Ecosystem.Instance memory _defaults)
    internal
    returns (Ecosystem.Instance memory ecosystem)
  {
    ecosystem.daoAddress = address(this);
    ecosystem.daoModelAddress = _deployProxy(_defaults.daoModelAddress, _controller);
    ecosystem.ecosystemModelAddress = _deployProxy(_defaults.ecosystemModelAddress, _controller);
    ecosystem.governanceTokenAddress = _deployProxy(_defaults.governanceTokenAddress, _controller);
    ecosystem.tokenHolderModelAddress = _deployProxy(
      _defaults.tokenHolderModelAddress,
      _controller
    );
    ecosystem.tokenModelAddress = _deployProxy(_defaults.tokenModelAddress, _controller);

    Ecosystem(ecosystem.ecosystemModelAddress).serialize(ecosystem);
    return ecosystem;
  }

  /**
   * @dev creates a Token.Instance record and initializes the ElasticGovernanceToken.
   * @param _controller the address which can control the core DAO functions
   * @param _name name of the token
   * @param _symbol symbol of the token
   * @param _eByL initial ETH/token ratio
   * @param _elasticity the percentage by which capitalDelta should increase
   * @param _k a constant, initially set by the DAO
   * @param _maxLambdaPurchase maximum amount of lambda (shares) that can be
   * minted on each call to the join function in ElasticDAO.sol
   * @param _ecosystem the DAO's ecosystem instance
   * @return token Token.Instance
   */
  function _buildToken(
    address _controller,
    string memory _name,
    string memory _symbol,
    uint256 _eByL,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase,
    Ecosystem.Instance memory _ecosystem
  ) internal returns (Token.Instance memory token) {
    token.eByL = _eByL;
    token.ecosystem = _ecosystem;
    token.elasticity = _elasticity;
    token.k = _k;
    token.lambda = 0;
    token.m = 1000000000000000000;
    token.maxLambdaPurchase = _maxLambdaPurchase;
    token.name = _name;
    token.symbol = _symbol;
    token.uuid = _ecosystem.governanceTokenAddress;

    // initialize the token within the ecosystem
    return ElasticGovernanceToken(token.uuid).initialize(
      _controller,
      _controller,
      _ecosystem,
      token
    );
  }

  function _deployProxy(address _implementationAddress, address _owner) internal returns (address) {
    PProxy proxy = new PProxy();
    proxy.setImplementation(_implementationAddress);
    proxy.setProxyOwner(_owner);
    return address(proxy);
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
