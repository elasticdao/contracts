// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './ElasticDAO.sol';

import '../models/Ecosystem.sol';
import '../services/ReentryProtection.sol';

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
    uint256 _maxLambdaPurchase
  ) external payable preventReentry {
    require(fee == msg.value, 'ElasticDAO: pay up');

    // create the DAO
    ElasticDAO elasticDAO =
      new ElasticDAO(ecosystemModelAddress, msg.sender, _summoners, _nameOfDAO);

    deployedDAOAddresses.push(address(elasticDAO));
    deployedDAOCount = SafeMath.add(deployedDAOCount, 1);

    // initialize the token
    elasticDAO.initializeToken(_nameOfToken, _symbol, _eByL, _elasticity, _k, _maxLambdaPurchase);
    emit DeployedDAO(address(elasticDAO));
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
