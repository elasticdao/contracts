// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './ElasticDAO.sol';

import '../models/Ecosystem.sol';
import '../services/ReentryProtection.sol';

// This contract is the facory contract for ElasticDAO
contract ElasticDAOFactory is ReentryProtection {
  address public deployer;
  address public ecosystemModelAddress;
  address payable feeAddress;
  address[] public deployedDAOAddresses;
  uint256 public deployedDAOCount = 0;

  event DeployedDAO(address indexed daoAddress);
  event FeeAddressUpdated(address indexed feeReceiver);
  event FeesCollected(address treasuryAddress, uint256 amount);

  modifier onlyDeployer() {
    require(msg.sender == deployer, 'ElasticDAO: Only deployer');
    _;
  }

  constructor(address _ecosystemModelAddress) {
    deployer = msg.sender;
    ecosystemModelAddress = _ecosystemModelAddress;
  }

  /**
   * @dev deploys DAO and initializes token
   * and stores the address of the deployed DAO
   */
  function deployDAOAndToken(
    address[] memory _summoners,
    string memory _nameOfDAO,
    uint256 _numberOfSummoners,
    string memory _nameOfToken,
    string memory _symbol,
    uint256 _eByL,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase
  ) public payable preventReentry {
    // create the DAO
    ElasticDAO elasticDAO =
      new ElasticDAO(ecosystemModelAddress, msg.sender, _summoners, _nameOfDAO, _numberOfSummoners);

    // initialize the token
    elasticDAO.initializeToken(_nameOfToken, _symbol, _eByL, _elasticity, _k, _maxLambdaPurchase);

    deployedDAOAddresses.push(address(elasticDAO));
    deployedDAOCount = SafeMath.add(deployedDAOCount, 1);
    emit DeployedDAO(address(elasticDAO));
  }

  function updateFeeAddress(address _feeReceiver) external onlyDeployer preventReentry {
    feeAddress = payable(_feeReceiver);
    emit FeeAddressUpdated(_feeReceiver);
  }

  function collectFees() external preventReentry {
    uint256 amount = address(this).balance;

    feeAddress.transfer(amount);
    emit FeesCollected(address(feeAddress), amount);
  }

  receive() external payable {}

  fallback() external payable {}
}
