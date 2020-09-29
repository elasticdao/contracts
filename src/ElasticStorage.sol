// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './ElasticBallotStorage.sol';
import './ElasticCoreStorage.sol';
import './ElasticTokenStorage.sol';
import './ElasticVoteStorage.sol';

contract ElasticStorage {
  ElasticBallotStorage internal elasticBallotStorage;
  ElasticCoreStorage internal elasticCoreStorage;
  ElasticTokenStorage internal elasticTokenStorage;
  ElasticVoteStorage internal elasticVoteStorage;

  struct AccountBalance {
    address uuid;
    uint256 counter;
    uint256 e;
    uint256 k;
    uint256 lambda;
    uint256 m;
    uint256 t;
  }

  struct DAO {
    bool summoned;
    string name;
  }

  struct MathData {
    uint256 capitalDelta;
    uint256 e;
    uint256 elasticity;
    uint256 k;
    uint256 lambda;
    uint256 m;
    uint256 maxLambdaPurchase;
    uint256 t;
  }

  struct ShareUpdate {
    address uuid;
    bool isIncreasing;
    uint256 blockNumber;
    uint256 counter;
    uint256 deltaLambda;
    uint256 deltaT;
    uint256 k;
    uint256 m;
  }

  struct Token {
    address uuid;
    string name;
    string symbol;
    uint256 capitalDelta;
    uint256 elasticity;
    uint256 k;
    uint256 lambda;
    uint256 m;
    uint256 maxLambdaPurchase;
  }

  // entire struct is in Vote.sol
  //is already in Vote.sol comment is due to this struct already having it
  struct Vote {
    bool hasPenalty;
    bool hasReachedQuorum;
    bool isActive;
    bool isApproved;
    string voteType;
    uint256 abstainLambda;
    uint256 approval;
    uint256 endOnBlock;
    uint256 id;
    uint256 maxSharesPerAccount;
    uint256 minBlocksForPenalty;
    uint256 noLambda;
    uint256 penalty;
    uint256 quorum;
    uint256 reward;
    uint256 startOnBlock;
    uint256 yesLambda;
  }

  struct VoteBallot {
    address uuid; //put into Vote.sol struct
    uint256 lambda; //put into Vote.sol struct- dont know if required
    // - yesLambda, noLambda already present in Vote.sol
    uint256 voteId;
    uint256 yna;
  }

  struct VoteInformation {
    string proposal; //put into Vote.sol struct
    uint256 id; // is already in Vote.sol struct
  }

  struct VoteSettings {
    uint256 approval; // is already in Vote.sol struct
    uint256 counter;
    uint256 maxSharesPerAccount; // is already in Vote.sol struct
    uint256 minBlocksForPenalty; // is already in Vote.sol struct
    uint256 minSharesToCreate;
    uint256 penalty; // is already in Vote.sol struct
    uint256 quorum; // is already in Vote.sol struct
    uint256 reward; // is already in Vote.sol struct
  }

  struct VoteType {
    string name; // put into Vote.sol struct
    bool hasPenalty; // is already in Vote.sol struct
    uint256 minBlocks; // is already in Vote.sol struct - minBlocksForPenalty
  }

  modifier onlyElasticBallotStorage() {
    require(
      msg.sender == address(elasticBallotStorage),
      'ElasticDAO: Not authorized to call that function.'
    );
    _;
  }

  constructor() {
    elasticBallotStorage = new ElasticBallotStorage(address(this));
    elasticCoreStorage = new ElasticCoreStorage(address(this));
    elasticTokenStorage = new ElasticTokenStorage(address(this));
    elasticVoteStorage = new ElasticVoteStorage(address(this));
  }

  /**
   * @dev returns the current state of the DAO with respect to summoning
   * @return isSummoned bool
   */
  function daoSummoned() external view returns (bool isSummoned) {
    return elasticCoreStorage.daoSummoned();
  }

  /**
   * @dev returns the account balance of a specific user
   * @param _uuid - Unique User ID - the address of the user
   * @return accountBalance AccountBalance
   */
  function getAccountBalance(address _uuid)
    external
    view
    returns (AccountBalance memory accountBalance)
  {
    return elasticTokenStorage.getAccountBalance(_uuid);
  }

  /**
   * @dev returns the balance of a specific address at a specific block
   * @param _uuid the unique user identifier - the User's address
   * @param _blockNumber the blockNumber at which the user wants the account balance
   * Essentially the function locally instantiates the counter and shareUpdate,
   * Then using a while loop, loops through shareUpdate's blocks and then
   * checks if the share value is increasing or decreasing,
   * if increasing it updates t ( the balance of the tokens )
   * by adding deltaT ( the change in the amount of tokens ), else
   * if decreasing it reduces the value of t by deltaT.
   * @return t uint256 - the balance at that block
   */
  function getBalanceAtBlock(address _uuid, uint256 _blockNumber)
    external
    view
    returns (uint256 t)
  {
    return elasticTokenStorage.getBalanceAtBlock(_uuid, _blockNumber);
  }

  /**
   * @dev Gets the DAO's data
   * @return dao DAO
   */
  function getDAO() external view returns (ElasticStorage.DAO memory dao) {
    return elasticCoreStorage.getDAO();
  }

  function getElasticBallotStorageAddress() external view returns (address elasticBallotAddress) {
    return address(elasticBallotStorage);
  }

  function getElasticTokenStorageAddress()
    external
    view
    returns (address elasticTokenStorageAddress)
  {
    return address(elasticTokenStorage);
  }

  function getElasticVoteStorageAddress()
    external
    view
    returns (address elasticVoteStorageAddress)
  {
    return address(elasticVoteStorage);
  }

  /**
   * @dev Gets the Math data
   * @param e - Eth value
   * @return mathData MathData
   */
  function getMathData(uint256 e) external view returns (MathData memory mathData) {
    return elasticTokenStorage.getMathData(e);
  }

  /**
   * @dev Gets the Token
   * @param token - The token of the DAO
   * @return token Token
   */
  function getToken() external view returns (Token memory token) {
    return elasticTokenStorage.getToken();
  }

  /**
   * @dev Gets the vote using it's ID
   * @param _id - The id of the vote requested
   * @return vote Vote
   */
  function getVote(uint256 _id) external view returns (Vote memory vote) {
    return elasticVoteStorage.getVote(_id);
  }

  /**
   * @dev checks whether given address is a summoner
   * @param _account - The address of the account
   * @return accountIsSummoner bool
   */
  function isSummoner(address _account) external view returns (bool accountIsSummoner) {
    return elasticCoreStorage.isSummoner(_account);
  }

  function recordBallotChange(
    uint256 _id,
    uint256 _deltaLambda,
    bool _isIncreasing,
    string memory _ynaKey
  ) external onlyElasticBallotStorage {
    elasticVoteStorage.recordBallotChange(_id, _deltaLambda, _isIncreasing, _ynaKey);
  }

  /**
   * @dev Sets the DAO
   * @param _dao - The data of the DAO
   */
  function setDAO(DAO memory _dao) external {
    elasticCoreStorage.setDAO(_dao);
  }

  /**
   * @dev Sets the MathData
   * @param mathData - The mathData required by the DAO
   */
  function setMathData(MathData memory mathData) external {
    elasticTokenStorage.setMathData(mathData);
  }

  /**
   * @dev Sets the summoned state of the DAO to true
   */
  function setSummoned() external {
    elasticCoreStorage.setSummoned();
  }

  /**
   * @dev Sets the summoners of the DAO
   * @param _summoners - an address array of all the summoners
   * @param _initialSummonerShare - the intitial share each summoner gets
   */
  function setSummoners(address[] calldata _summoners, uint256 _initialSummonerShare) external {
    return elasticCoreStorage.setSummoners(_summoners, _initialSummonerShare);
  }

  /**
   * @dev Sets the token of the DAO
   * @param _token - The token itself that has to be set for the DAO
   */
  function setToken(Token memory _token) external {
    elasticTokenStorage.setToken(_token);
  }

  /**
   * @dev sets the vote module
   * @param _voteModuleAddress - the addresss of the vote module
   */
  function setVoteModule(address _voteModuleAddress) external {
    elasticBallotStorage.setVoteModule(_voteModuleAddress);
    elasticVoteStorage.setVoteModule(_voteModuleAddress);
  }

  /**
   * @dev Sets the vote settings
   * @param _voteSettings - the vote settings which have to be set
   */
  function setVoteSettings(VoteSettings memory _voteSettings) external {
    elasticVoteStorage.setVoteSettings(_voteSettings);
  }

  /**
   * @dev Sets the type of the vote
   * @param _voteType - the type of the vote itself
   */
  function setVoteType(VoteType memory _voteType) external {
    elasticVoteStorage.setVoteType(_voteType);
  }

  /**
   * @dev updates the balance of an address
   * @param _uuid - Unique User ID - the address of the user
   * @param _isIncreasing - whether the balance is increasing or not
   * @param _deltaLambda - the change in the number of shares
   */
  function updateBalance(
    address _uuid,
    bool _isIncreasing,
    uint256 _deltaLambda
  ) external {
    elasticTokenStorage.updateBalance(_uuid, _isIncreasing, _deltaLambda);
  }
}
