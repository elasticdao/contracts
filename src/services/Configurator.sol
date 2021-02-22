// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../models/DAO.sol';
import '../models/Ecosystem.sol';
import '../models/Token.sol';

import '../tokens/ElasticGovernanceToken.sol';

import '@pie-dao/proxy/contracts/PProxy.sol';

/**
 * @notice This contract is used for configuring ElasticDAOs
 * @dev The main reason for having this is to decrease the size of ElasticDAO.sol
 */
contract Configurator {
  /**
   * @dev creates DAO.Instance record
   * @param _summoners addresses of the summoners
   * @param _name name of the DAO
   * @param _ecosystem instance of Ecosystem the DAO uses
   * @param _maxVotingLambda - the maximum amount of lambda that can be used to vote in the DAO
   * @return bool true
   */
  function buildDAO(
    address[] memory _summoners,
    string memory _name,
    uint256 _maxVotingLambda,
    Ecosystem.Instance memory _ecosystem
  ) external returns (bool) {
    DAO daoStorage = DAO(_ecosystem.daoModelAddress);
    DAO.Instance memory dao;

    dao.uuid = msg.sender;
    dao.ecosystem = _ecosystem;
    dao.maxVotingLambda = _maxVotingLambda;
    dao.name = _name;
    dao.summoned = false;
    dao.summoners = _summoners;
    daoStorage.serialize(dao);

    return true;
  }

  /**
   * @dev duplicates the ecosystem contract address defaults so that each
   * deployed DAO has it's own ecosystem configuration
   * @param _controller the address which can control the core DAO functions
   * @param _defaults instance of Ecosystem with the implementation addresses
   * @return ecosystem Ecosystem.Instance
   */
  function buildEcosystem(address _controller, Ecosystem.Instance memory _defaults)
    external
    returns (Ecosystem.Instance memory ecosystem)
  {
    ecosystem.configuratorAddress = _defaults.configuratorAddress;
    ecosystem.daoAddress = msg.sender;
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
   * @dev creates a governance token proxy and Token instance (storage)
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
  function buildToken(
    address _controller,
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
    token.uuid = _ecosystem.governanceTokenAddress;

    // initialize the token within the ecosystem
    ElasticGovernanceToken(token.uuid).initialize(
      _controller,
      _ecosystem.daoAddress,
      _ecosystem.ecosystemModelAddress,
      _controller
    );

    // serialize ecosystem and token
    Ecosystem(_ecosystem.ecosystemModelAddress).serialize(_ecosystem);
    tokenStorage.serialize(token);

    return token;
  }

  function _deployProxy(address _implementationAddress, address _owner) internal returns (address) {
    PProxy proxy = new PProxy();
    proxy.setImplementation(_implementationAddress);
    proxy.setProxyOwner(_owner);
    return address(proxy);
  }
}
