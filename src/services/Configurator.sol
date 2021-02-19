// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../models/DAO.sol';
import '../models/Ecosystem.sol';
import '../models/Token.sol';

import '../tokens/ElasticGovernanceToken.sol';
import 'hardhat-deploy/solc_0.7/proxy/EIP173Proxy.sol';
import '@openzeppelin/contracts/utils/Create2.sol';

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
   * @return bool true
   */
  function buildDAO(
    address[] memory _summoners,
    string memory _name,
    Ecosystem.Instance memory _ecosystem
  ) external returns (bool) {
    DAO daoStorage = DAO(_ecosystem.daoModelAddress);
    DAO.Instance memory dao;

    dao.uuid = msg.sender;
    dao.ecosystem = _ecosystem;
    dao.name = _name;
    dao.summoned = false;
    dao.summoners = _summoners;
    daoStorage.serialize(dao);

    return true;
  }

  /**
   * @dev duplicates the ecosystem contract address defaults so that each
   * deployed DAO has it's own ecosystem configuration
   * @param defaults instance of Ecosystem
   * @return ecosystem Ecosystem.Instance
   */
  function buildEcosystem(Ecosystem.Instance memory defaults)
    external
    returns (Ecosystem.Instance memory ecosystem)
  {
    Ecosystem ecosystemStorage = Ecosystem(defaults.ecosystemModelAddress);

    ecosystem.daoAddress = msg.sender;

    // Models
    ecosystem.daoModelAddress = defaults.daoModelAddress;
    ecosystem.ecosystemModelAddress = defaults.ecosystemModelAddress;
    ecosystem.tokenHolderModelAddress = defaults.tokenHolderModelAddress;
    ecosystem.tokenModelAddress = defaults.tokenModelAddress;

    // Services
    ecosystem.configuratorAddress = defaults.configuratorAddress;

    ecosystemStorage.serialize(ecosystem);
    return ecosystem;
  }

  /**
   * @dev creates a governance token proxy, implementation, and Token instance (storage)
   * @param _name name of the token
   * @param _symbol symbol of the token
   * @param _eByL initial ETH/token ratio
   * @param _elasticity the percentage by which capitalDelta should increase
   * @param _k a constant, initially set by the DAO
   * @param _maxLambdaPurchase maximum amount of lambda (shares) that can be
   * minted on each call to the join function in ElasticDAO.sol
   * @param _salt unique identifier for use with create2
   * @param _ecosystem the DAO's ecosystem instance
   * @return token Token.Instance
   */
  function buildToken(
    string memory _name,
    string memory _symbol,
    uint256 _eByL,
    uint256 _elasticity,
    uint256 _k,
    uint256 _maxLambdaPurchase,
    bytes32 _salt,
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

    // deploy new token with create2 and set the computed address as uuid
    address tokenAddress =
      Create2.computeAddress(_salt, keccak256(type(ElasticGovernanceToken).creationCode));
    // set token uuid to computed address
    token.uuid = tokenAddress;
    // create upgradeable ERC20 proxy
    EIP173Proxy proxy =
      new EIP173Proxy(
        tokenAddress,
        type(ElasticGovernanceToken).creationCode,
        _ecosystem.daoAddress
      );
    // deploy the new elastic governance token
    Create2.deploy(0, _salt, type(ElasticGovernanceToken).creationCode);
    // initialize the token within the ecosystem
    ElasticGovernanceToken(tokenAddress).initialize(
      proxy.owner(),
      _ecosystem.ecosystemModelAddress
    );
    _ecosystem.governanceTokenAddress = token.uuid;
    // serialize ecosystem
    Ecosystem(_ecosystem.ecosystemModelAddress).serialize(_ecosystem);
    tokenStorage.serialize(token);

    return token;
  }
}
