// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../models/DAO.sol';
import '../models/Ecosystem.sol';
import '../models/Token.sol';

import '../tokens/ElasticGovernanceToken.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for configuring ElasticDAOs
/// @dev ElasticDAO network contracts can read/write from this contract
contract Configurator {
  /**
   * @dev creates DAO.Instance record
   * @param _summoners - an array of the addresses of the summoners
   * @param _name - the name of the DAO
   * @param _numberOfSummoners - the number of summoners
   * @param _ecosystem - an instance of Ecosystem
   * @return dao DAO.Instance
   */

  function buildDAO(
    address[] memory _summoners,
    string memory _name,
    uint256 _numberOfSummoners,
    Ecosystem.Instance memory _ecosystem
  ) external returns (DAO.Instance memory dao) {
    DAO daoStorage = DAO(_ecosystem.daoModelAddress);
    dao.uuid = msg.sender;
    dao.ecosystem = _ecosystem;
    dao.name = _name;
    dao.numberOfSummoners = _numberOfSummoners;
    dao.summoned = false;
    dao.summoners = _summoners;
    daoStorage.serialize(dao);
    return dao;
  }

  /**
   * @dev duplicates the ecosystem contract address defaults
   * @param defaults - An instance of the Ecosystem
   * @return ecosystem Ecosystem.Instance
   */
  function buildEcosystem(Ecosystem.Instance memory defaults)
    external
    returns (Ecosystem.Instance memory ecosystem)
  {
    Ecosystem ecosystemStorage = Ecosystem(defaults.ecosystemModelAddress);

    ecosystem.daoAddress = msg.sender;

    // Models
    ecosystem.balanceModelAddress = defaults.balanceModelAddress;
    ecosystem.balanceMultipliersModelAddress = defaults.balanceMultipliersModelAddress;
    ecosystem.daoModelAddress = defaults.daoModelAddress;
    ecosystem.ecosystemModelAddress = defaults.ecosystemModelAddress;
    ecosystem.elasticModuleModelAddress = defaults.elasticModuleModelAddress;
    ecosystem.tokenHolderModelAddress = defaults.tokenHolderModelAddress;
    ecosystem.tokenModelAddress = defaults.tokenModelAddress;

    // Services
    ecosystem.configuratorAddress = defaults.configuratorAddress;
    ecosystem.registratorAddress = defaults.registratorAddress;

    ecosystemStorage.serialize(ecosystem);
    return ecosystem;
  }

  /**
   * @dev creates a governance token and it's storage
   * @param _name - the name of the token
   * @param _name - the symbol of the token
   * @param _eByL is the initial Eth/Egt ratio before the DAO has been summoned
   * @param _elasticity is the value of elasticity, initially set by the DAO
   * @param _k is a constant, initially set by the DAO
   * @param _maxLambdaPurchase - the maximum amount of lambda(shares) that can be
   * purchased by an account
   * m - initital share modifier = 1
   * @param _ecosystem - ecosystem instance
   * @return token Token.Instance
   */
  function buildToken(
    string memory _name,
    string memory _symbol,
    uint256 _eByL,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase,
    Ecosystem.Instance memory _ecosystem
  ) external returns (Token.Instance memory token) {
    Token tokenStorage = Token(_ecosystem.tokenModelAddress);
    token.eByL = _eByL;
    token.ecosystem = _ecosystem;
    token.elasticity = _elasticity;
    token.k = _k;
    token.lambda = 0;
    token.m = 1000000000000000000;
    token.maxLambdaPurchase = _maxLambdaPurchase;
    token.name = _name;
    token.symbol = _symbol;
    token.uuid = address(new ElasticGovernanceToken(msg.sender, _ecosystem.ecosystemModelAddress));

    _ecosystem.governanceTokenAddress = token.uuid;
    Ecosystem(_ecosystem.ecosystemModelAddress).serialize(_ecosystem);
    tokenStorage.serialize(token);

    return token;
  }
}
