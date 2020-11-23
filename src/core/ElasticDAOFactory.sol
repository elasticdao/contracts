// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './ElasticDAO.sol';
import '../models/Ecosystem.sol';

// This contract is the facory contract for ElasticDAO
contract ElasticDAOFactory {
  address internal ecosystemModelAddress;
  address payable feeAddress;
  address[] public deployedDAOAddresses;
  uint256 public deployedDAOCount = 0;

  event DAODeployed(address indexed daoAddress);
  event FeeAddressUpdated(address indexed feeReceiver);
  event FeesCollected(address treasuryAddress, uint256 amount);

  constructor(address _ecosystemModelAddress) {
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
    uint256 _eByl,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase
  ) public payable {
    // create the DAO
    ElasticDAO elasticDAO = new ElasticDAO(
      ecosystemModelAddress,
      _summoners,
      _nameOfDAO,
      _numberOfSummoners
    );

    // initialize the token
    elasticDAO.initializeToken(_nameOfToken, _symbol, _eByl, _elasticity, _k, _maxLambdaPurchase);

    deployedDAOAddresses.push(address(elasticDAO));
    deployedDAOCount = SafeMath.add(deployedDAOCount, 1);
    emit DAODeployed(address(elasticDAO));
  }

  function updateFeeAddress(address _feeReceiver) external {
    // TODO: NEEDS MODIFIER!!! THIS SHOULD ONLY BE UPDATEABLE BY A TRANSACTIONAL VOTE

    feeAddress = payable(_feeReceiver);
    emit FeeAddressUpdated(_feeReceiver);
  }

  function collectFees() external {
    // TODO: NEEDS MODIFIER!!! THIS SHOULD ONLY BE UPDATEABLE BY A TRANSACTIONAL VOTE

    uint256 amount = address(this).balance;

    feeAddress.transfer(amount);
    emit FeesCollected(address(feeAddress), amount);
  }

  receive() external payable {}

  fallback() external payable {}
}
