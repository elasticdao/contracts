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
    require(
      elasticStorage.daoSummoned(),
      'ElasticDAO: DAO must be summoned'
    );
    _;
  }
  modifier onlyBeforeSummoning() {
    require(
      elasticStorage.daoSummoned() == false,
      'ElasticDAO: DAO must not be summoned'
    );
    _;
  }
  modifier onlySummoners() {
    require(elasticStorage.isSummoner(msg.sender), 'ElasticDAO: Only summoners');
    _;
  }

  constructor(
    address[] memory _summoners,
    string[3] memory _stringData,
    bool[4] memory _boolData,
    uint256[15] memory _uintData
  ) {
    elasticStorage = new ElasticStorage();

    elasticStorage.storeSummoners()

    // require(storeStringData(_stringData));
    // require(storeBoolData(_boolData));
    // require(storeUintDAOData(_uintData, _summoners));
    // require(storeUintVoteData(_uintData));

    // Initialize DAO
    // eternalStorage.setBool(StorageLib.formatLocation('dao.summoned'), false);
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

  function storeStringData(string[3] memory _data) internal returns (bool) {
    eternalStorage.setString(StorageLib.formatLocation('dao.name'), _data[0]);
    eternalStorage.setString(StorageLib.formatLocation('dao.token.name'), _data[1]);
    eternalStorage.setString(StorageLib.formatLocation('dao.token.symbol'), _data[2]);

    return true;
  }

  function storeBoolData(bool[4] memory _data) internal returns (bool) {
    eternalStorage.setBool(StorageLib.formatLocation('dao.vote.contract.penalty'), _data[0]);
    eternalStorage.setBool(StorageLib.formatLocation('dao.vote.finance.penalty'), _data[1]);
    eternalStorage.setBool(StorageLib.formatLocation('dao.vote.information.penalty'), _data[2]);
    eternalStorage.setBool(StorageLib.formatLocation('dao.vote.permission.penalty'), _data[3]);

    return true;
  }

  function storeUintDAOData(uint256[15] memory _data, address[] memory _summoners)
    internal
    returns (bool)
  {
    eternalStorage.setUint(StorageLib.formatLocation('dao.baseTokenRatio'), _data[0]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.initialTokenPrice'), _data[1]);

    eternalStorage.setUint(StorageLib.formatLocation('dao.priceToTokenInflationRate'), _data[2]);

    for (uint256 i = 0; i < _summoners.length; i++) {
      eternalStorage.setBool(StorageLib.formatAddress('dao.summoner', _summoners[i]), true);
      ShareLib.updateBalance(_summoners[i], true, _data[3], eternalStorage);
    }

    return true;
  }

  function storeUintVoteData(uint256[15] memory _data) internal returns (bool) {
    // Initialize Vote
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.approval'), _data[4]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.maxSharesPerWallet'), _data[5]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.contract.minBlocks'), _data[6]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.finance.minBlocks'), _data[7]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.information.minBlocks'), _data[8]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.minBlocksForPenalty'), _data[9]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.permission.minBlocks'), _data[10]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.minSharesToCreate'), _data[11]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.penalty'), _data[12]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.quorum'), _data[13]);
    eternalStorage.setUint(StorageLib.formatLocation('dao.vote.reward'), _data[14]);

    return true;
  }
}
