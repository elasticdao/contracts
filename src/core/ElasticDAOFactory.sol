// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './ElasticDAO.sol';

import '../models/Ecosystem.sol';
import '../services/ReentryProtection.sol';
import '@openzeppelin/contracts/utils/Create2.sol';
import 'hardhat-deploy/solc_0.7/proxy/EIP173ProxyWithReceive.sol';

/**
 * @dev The factory contract for ElasticDAO
 * Deploys ElasticDAO's and also sets all the required parameters and permissions,
 * Collects a fee which is later used by ELasticDAO for further development of the project.
 */
contract ElasticDAOFactory is ReentryProtection {
  address public ecosystemModelAddress;
  address public manager;
  address payable feeAddress;
  address[] public deployedDAOAddresses;
  uint256 public deployedDAOCount;
  uint256 public fee;
  bool public initialized = false;

  event DeployedDAO(address indexed daoAddress);
  event FeeAddressUpdated(address indexed feeReceiver);
  event FeesCollected(address treasuryAddress, uint256 amount);
  event FeeUpdated(uint256 amount);
  event ManagerUpdated(address indexed newManager);

  modifier onlyManager() {
    require(manager == msg.sender, 'ElasticDAO: Only manager');
    _;
  }

  /**
   * @notice Initializes the ElasticDAO factory
   * @param _ecosystemModelAddress - the address of the ecosystem model
   * @dev
   * Requirements:
   * - The factory cannot already be initialized
   * - The ecosystem model address cannot be the zero address
   */
  function initialize(address _ecosystemModelAddress) external preventReentry {
    require(initialized == false, 'ElasticDAO: Factory already initialized');
    require(_ecosystemModelAddress != address(0), 'ElasticDAO: Address Zero');

    initialized = true;
    manager = msg.sender;
    deployedDAOCount = 0;
    fee = 250000000000000000;
    ecosystemModelAddress = _ecosystemModelAddress;
  }

  /**
   * @notice collects the fees sent to this contract
   * @dev emits FeesCollected event
   */
  function collectFees() external preventReentry {
    uint256 amount = address(this).balance;

    (bool success, ) = feeAddress.call{ value: amount }('');
    require(success, 'ElasticDAO: TransactionFailed');
    emit FeesCollected(address(feeAddress), amount);
  }

  /**
   * @notice deploys DAO and initializes token and stores the address of the deployed DAO
   * @param _summoners - an array containing address of summoners
   * @param _nameOfDAO - the name of the DAO
   * @param _nameOfToken - the name of the token
   * @param _eByL-the amount of lambda a summoner gets(per ETH) during the seeding phase of the DAO
   * @param _elasticity-the value by which the cost of entering the  DAO increases ( on every join )
   * @param _k - is the constant token multiplier,
   * it increases the number of tokens that each member of the DAO has with respect to their lambda
   * @param _maxLambdaPurchase - is the maximum amount of lambda that can be purchased per wallet
   * @param _maxVotingLambda - is the maximum amount of lambda that can be used to vote
   * @dev emits DeployedDAO event
   * @dev
   * Requirement:
   * - The fee required should be sent in the call to the function
   */
  function deployDAOAndToken(
    address[] memory _summoners,
    string memory _nameOfDAO,
    string memory _nameOfToken,
    string memory _symbol,
    uint256 _eByL,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase,
    uint256 _maxVotingLambda
  ) external payable preventReentry {
    require(fee == msg.value, 'ElasticDAO: A fee is required to deploy a DAO');
    bytes32 salt = keccak256(abi.encode(msg.sender, deployedDAOCount));

    // compute deployed DAO address
    address payable daoAddress =
      address(uint160(Create2.computeAddress(salt, keccak256(type(ElasticDAO).creationCode))));

    // deploy proxy with the computed dao address
    EIP173ProxyWithReceive proxy =
      new EIP173ProxyWithReceive(daoAddress, type(ElasticDAO).creationCode, msg.sender);

    // deploy DAO with computed address and initialize
    Create2.deploy(0, salt, type(ElasticDAO).creationCode);
    ElasticDAO(daoAddress).initialize(
      ecosystemModelAddress,
      proxy.owner(),
      _summoners,
      _nameOfDAO,
      _maxVotingLambda
    );

    deployedDAOAddresses.push(address(daoAddress));
    deployedDAOCount = SafeMath.add(deployedDAOCount, 1);

    // initialize the token
    ElasticDAO(daoAddress).initializeToken(
      _nameOfToken,
      _symbol,
      _eByL,
      _elasticity,
      _k,
      _maxLambdaPurchase,
      salt
    );
    emit DeployedDAO(address(daoAddress));
  }

  /**
   * @notice updates the fee required to deploy a DAQ
   * @param _amount - the new amount of the fees
   * @dev emits FeeUpdated event
   */
  function updateFee(uint256 _amount) external onlyManager preventReentry {
    fee = _amount;
    emit FeeUpdated(fee);
  }

  /**
   * @notice updates the address of the fee reciever
   * @param _feeReceiver - the new address of the fee reciever
   * @dev emits FeeUpdated event
   * @dev
   * Requirement:
   * - The fee receiver address cannot be zero address
   */
  function updateFeeAddress(address _feeReceiver) external onlyManager preventReentry {
    require(_feeReceiver != address(0), 'ElasticDAO: Address Zero');

    feeAddress = payable(_feeReceiver);
    emit FeeAddressUpdated(_feeReceiver);
  }

  /**
   * @notice updates the manager address
   * @param _newManager - the address of the new manager
   * @dev emits ManagerUpdated event
   */
  function updateManager(address _newManager) external onlyManager preventReentry {
    manager = _newManager;
    emit ManagerUpdated(manager);
  }

  receive() external payable {}

  fallback() external payable {}
}
