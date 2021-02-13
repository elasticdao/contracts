// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './ElasticDAO.sol';

import '../models/Ecosystem.sol';
import '../services/ReentryProtection.sol';
import '../libraries/Create2.sol';

import 'hardhat-deploy/solc_0.7/proxy/EIP173ProxyWithReceive.sol';

// import 'hardhat-deploy/solc_0.7/proxy/EIP173Proxy.sol';

// This contract is the facory contract for ElasticDAO
contract ElasticDAOFactory is ReentryProtection {
  address public ecosystemModelAddress;
  address public manager;
  address payable feeAddress;
  address[] public deployedDAOAddresses;
  uint256 public deployedDAOCount = 0;
  uint256 public fee = 250000000000000000;

  event DeployedDAO(address indexed daoAddress);
  event FeeAddressUpdated(address indexed feeReceiver);
  event FeesCollected(address treasuryAddress, uint256 amount);
  event FeeUpdated(uint256 amount);
  event ManagerUpdated(address indexed newManager);

  modifier onlyManager() {
    require(manager == msg.sender, 'ElasticDAO: Only manager');
    _;
  }

  constructor(address _ecosystemModelAddress) {
    require(_ecosystemModelAddress != address(0), 'ElasticDAO: Address Zero');

    manager = msg.sender;
    ecosystemModelAddress = _ecosystemModelAddress;
  }

  function collectFees() external preventReentry {
    uint256 amount = address(this).balance;

    (bool success, ) = feeAddress.call{ value: amount }('');
    require(success, 'ElasticDAO: TransactionFailed');
    emit FeesCollected(address(feeAddress), amount);
  }

  /**
   * @dev deploys DAO and initializes token
   * and stores the address of the deployed DAO
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
    bytes32 salt = keccak256(abi.encode(_nameOfDAO, deployedDAOCount));

    // compute deployed DAO address
    address payable daoAddress =
      address(uint160(Create2.computeAddress(salt, type(ElasticDAO).creationCode)));

    // deploy proxy with the computed dao address
    EIP173Proxy proxy =
      new EIP173ProxyWithReceive(daoAddress, type(ElasticDAO).creationCode, msg.sender);

    // deploy DAO with computed address and initialize
    Create2.deploy(salt, type(ElasticDAO).creationCode);
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
      _maxLambdaPurchase
    );
    emit DeployedDAO(address(daoAddress));
  }

  function updateFee(uint256 amount) external onlyManager preventReentry {
    fee = amount;
    emit FeeUpdated(fee);
  }

  function updateFeeAddress(address _feeReceiver) external onlyManager preventReentry {
    require(_feeReceiver != address(0), 'ElasticDAO: Address Zero');

    feeAddress = payable(_feeReceiver);
    emit FeeAddressUpdated(_feeReceiver);
  }

  function updateManager(address newManager) external onlyManager preventReentry {
    manager = newManager;
    emit ManagerUpdated(manager);
  }

  receive() external payable {}

  fallback() external payable {}
}
