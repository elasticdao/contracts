// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import './ElasticDAO.sol';
import '../models/Ecosystem.sol';

import 'hardhat/console.sol';

// This contract is the facory contract for ElasticDAO
contract ElasticDAOFactory {
  address internal ecosystemModelAddress;
  address payable feeAddress;

  event DAODeployed(address indexed daoAddress);

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
    uint256 _capitalDelta,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase
  ) public payable {
    // create the DAO
    console.log(msg.value);

    ElasticDAO elasticDAO = new ElasticDAO(
      ecosystemModelAddress,
      _summoners,
      _nameOfDAO,
      _numberOfSummoners
    );

    // initialize the token
    elasticDAO.initializeToken(
      _nameOfToken,
      _symbol,
      _capitalDelta,
      _elasticity,
      _k,
      _maxLambdaPurchase
    );
    // console.log('elasticDAO intitialize check');

    emit DAODeployed(address(elasticDAO));
  }

  receive() external payable {}

  fallback() external payable {}
}
