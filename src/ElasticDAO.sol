// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

// Contracts
import './ElasticStorage.sol';
import './tokens/ElasticGovernanceToken.sol';

// Libraries
import './libraries/ElasticMathLib.sol';
import './libraries/SafeMath.sol';
import './libraries/ShareLib.sol';
import './libraries/StorageLib.sol';
import './libraries/StringLib.sol';

contract ElasticDAO {
  ElasticStorage internal elasticStorage;

  modifier onlyAfterSummoning() {
    require(elasticStorage.daoSummoned(), 'ElasticDAO: DAO must be summoned');
    _;
  }
  modifier onlyBeforeSummoning() {
    require(elasticStorage.daoSummoned() == false, 'ElasticDAO: DAO must not be summoned');
    _;
  }
  modifier onlySummoners() {
    require(elasticStorage.isSummoner(msg.sender), 'ElasticDAO: Only summoners');
    _;
  }

  constructor(
    address[] calldata _summoners,
    string[3] calldata _stringData,
    bool[4] calldata _boolData,
    uint256[15] calldata _uintData
  ) {
    elasticStorage = new ElasticStorage();

    elasticStorage.setSummoners(_summoners, _uintData[3]);

    ElasticStorage.DAO memory dao;
    string memory name = _stringData[0];
    dao.name = name;
    dao.summoned = false;

    ElasticStorage.Token memory token;
    string memory tokenName = _stringData[1];
    string memory tokenSymbol = _stringData[2];
    token.elasticity = _uintData[2];
    token.k = _uintData[0];
    token.m = _uintData[1];
    token.name = tokenName;
    token.symbol = tokenSymbol;

    ElasticStorage.VoteSettings memory voteSettings;
    voteSettings.approval = _uintData[4];
    voteSettings.maxSharesPerAccount = _uintData[5];
    voteSettings.minBlocksForPenalty = _uintData[9];
    voteSettings.minSharesToCreate = _uintData[11];
    voteSettings.penalty = _uintData[12];
    voteSettings.quorum = _uintData[13];
    voteSettings.reward = _uintData[14];

    ElasticStorage.VoteType memory contractVoteType;
    contractVoteType.minBlocks = _uintData[6];
    contractVoteType.name = 'contract';
    contractVoteType.penalty = _boolData[0];

    ElasticStorage.VoteType memory financeVoteType;
    contractVoteType.minBlocks = _uintData[7];
    contractVoteType.name = 'finance';
    contractVoteType.penalty = _boolData[1];

    ElasticStorage.VoteType memory informationVoteType;
    contractVoteType.minBlocks = _uintData[8];
    contractVoteType.name = 'information';
    contractVoteType.penalty = _boolData[2];

    ElasticStorage.VoteType memory permissionVoteType;
    contractVoteType.minBlocks = _uintData[10];
    contractVoteType.name = 'permission';
    contractVoteType.penalty = _boolData[3];

    elasticStorage.setDAO(dao);
    elasticStorage.setToken(token);
    elasticStorage.setVoteSettings(voteSettings);
    elasticStorage.setVoteType(contractVoteType);
    elasticStorage.setVoteType(financeVoteType);
    elasticStorage.setVoteType(informationVoteType);
    elasticStorage.setVoteType(permissionVoteType);
  }

  function joinDAO(uint256 _amount) public payable onlyAfterSummoning {
    uint256 voteMaxSharesPerWallet = eternalStorage.getUint(
      StorageLib.formatLocation('dao.vote.maxSharesPerWallet')
    );
    uint256 walletLambda = eternalStorage.getUint(
      StorageLib.formatAddress('dao.shares', msg.sender)
    );
    uint256 k = eternalStorage.getUint(StorageLib.formatLocation('dao.baseTokenRatio'));
    uint256 lambda = eternalStorage.getUint(StorageLib.formatLocation('dao.totalShares'));

    require(
      SafeMath.add(_amount, walletLambda) <= voteMaxSharesPerWallet,
      'ElasticDAO: Cannot purchase that many shares'
    );

    uint256 elasticity = eternalStorage.getUint(
      StorageLib.formatLocation('dao.priceToTokenInflationRate')
    );
    uint256 m = eternalStorage.getUint(StorageLib.formatLocation('dao.shareModifier'));
    uint256 capitalDelta = eternalStorage.getUint(StorageLib.formatLocation('dao.tokenPrice'));
    uint256 deltaE = ElasticMathLib.deltaE(_amount, capitalDelta, k, elasticity, lambda, m);

    require(deltaE == msg.value, 'ElasticDAO: Incorrect ETH amount');

    ShareLib.updateBalance(msg.sender, true, _amount, eternalStorage);
  }

  function seedSummoning() public payable onlyBeforeSummoning onlySummoners {
    uint256 capitalDelta = eternalStorage.getUint(
      StorageLib.formatLocation('dao.initialTokenPrice')
    );
    uint256 k = eternalStorage.getUint(StorageLib.formatLocation('dao.baseTokenRatio'));
    uint256 deltaE = msg.value;
    uint256 deltaLambda = SafeMath.div(SafeMath.div(deltaE, capitalDelta), k);
    ShareLib.updateBalance(msg.sender, true, deltaLambda, eternalStorage);
  }

  function summon() public onlyBeforeSummoning onlySummoners {
    uint256 e = address(this).balance;

    require(e > 0, 'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio');

    uint256 lambda = eternalStorage.getUint(StorageLib.formatLocation('dao.totalShares'));
    uint256 k = eternalStorage.getUint(StorageLib.formatLocation('dao.baseTokenRatio'));
    uint256 t = SafeMath.mul(lambda, k); // m = 1.0
    uint256 capitalDelta = SafeMath.div(e, t);

    eternalStorage.setUint(StorageLib.formatLocation('dao.shareModifier'), 1);
    eternalStorage.setUint(StorageLib.formatLocation('dao.tokenPrice'), capitalDelta);

    new ElasticGovernanceToken(address(eternalStorage));

    eternalStorage.setBool(StorageLib.formatLocation('dao.summoned'), true);
  }
}
