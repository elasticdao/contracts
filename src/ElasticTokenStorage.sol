// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './EternalStorage.sol';
import './ElasticStorage.sol';
import './libraries/ElasticMathLib.sol';
import './libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing Elastic Token data
/// @dev ElasticDAO network contracts can read/write from this contract
/// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract ElasticTokenStorage is EternalStorage {
  modifier onlyOwnerOrToken() {
    address tokenAddress = getAddress('dao.token.address');
    require(
      msg.sender == owner || msg.sender == tokenAddress,
      'ElasticDAO: Not authorized to call that function.'
    );
    _;
  }

  constructor(address _owner) EternalStorage(_owner) {}

  /**
   * @dev returns the account balance of a specific user
   * @param _uuid - Unique User ID - the address of the user
   * @return accountBalance AccountBalance
   */
  function getAccountBalance(address _uuid)
    external
    view
    onlyOwnerOrToken
    returns (ElasticStorage.AccountBalance memory accountBalance)
  {
    return _deserializeAccountBalance(_uuid);
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
    onlyOwnerOrToken
    returns (uint256 t)
  {
    uint256 i = 0;
    t = 0;

    uint256 counter = getUint(keccak256(abi.encode('dao.shares.counter', _uuid)));

    ElasticStorage.ShareUpdate memory shareUpdate = _deserializeShareUpdate(_uuid, i);

    while (i <= counter && shareUpdate.blockNumber != 0 && shareUpdate.blockNumber < _blockNumber) {
      if (shareUpdate.isIncreasing) {
        t = SafeMath.add(t, shareUpdate.deltaT);
      } else {
        t = SafeMath.sub(t, shareUpdate.deltaT);
      }

      i = SafeMath.add(i, 1);

      shareUpdate = _deserializeShareUpdate(_uuid, i);
    }

    return t;
  }

  /**
   * @dev Gets the Math data
   * @param e - Eth value
   * @return mathData MathData
   */
  function getMathData(uint256 e)
    external
    view
    onlyOwnerOrToken
    returns (ElasticStorage.MathData memory mathData)
  {
    return _deserializeMathData(e);
  }

  /**
   * @dev Gets the Token
   * @param token - The token of the DAO
   * @return token Token
   */
  function getToken() external view onlyOwnerOrToken returns (ElasticStorage.Token memory token) {
    return _deserializeToken();
  }

  /**
   * @dev Sets the MathData
   * @param mathData - The mathData required by the DAO
   */
  function setMathData(ElasticStorage.MathData memory mathData) external onlyOwnerOrToken {
    _serializeMathData(mathData);
  }

  /**
   * @dev Sets the token of the DAO
   * @param token - The token itself that has to be set for the DAO
   */
  function setToken(ElasticStorage.Token memory token) external onlyOwner {
    _serializeToken(token);
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
  ) external onlyOwnerOrToken {
    _updateBalance(_uuid, _isIncreasing, _deltaLambda);
  }

  function _deserializeAccountBalance(address _uuid)
    internal
    view
    returns (ElasticStorage.AccountBalance memory accountBalance)
  {
    accountBalance.counter = getUint(keccak256(abi.encode('dao.shares.counter', _uuid)));
    accountBalance.k = getUint('dao.token.constant');
    accountBalance.lambda = getUint(keccak256(abi.encode('dao.shares', _uuid)));
    accountBalance.m = getUint('dao.token.modifier');
    accountBalance.t = SafeMath.mul(
      SafeMath.mul(accountBalance.lambda, accountBalance.m),
      accountBalance.k
    );
    accountBalance.uuid = _uuid;
  }

  function _deserializeMathData(uint256 e)
    internal
    view
    returns (ElasticStorage.MathData memory mathData)
  {
    mathData.e = e;
    mathData.k = getUint('dao.token.constant');
    mathData.elasticity = getUint('dao.token.elasticity');
    mathData.lambda = getUint('dao.token.totalShares');
    mathData.m = getUint('dao.token.modifier');
    mathData.maxLambdaPurchase = getUint('dao.token.maxLambdaPurchase');
    mathData.t = ElasticMathLib.t(mathData.lambda, mathData.k, mathData.m);
    if (mathData.e > 0) {
      mathData.capitalDelta = SafeMath.div(mathData.e, mathData.t);
    }
    return mathData;
  }

  function _deserializeShareUpdate(address _uuid, uint256 _counter)
    internal
    view
    returns (ElasticStorage.ShareUpdate memory shareUpdate)
  {
    shareUpdate.blockNumber = getUint(
      keccak256(abi.encode('dao.shares.blockNumber', _counter, _uuid))
    );
    shareUpdate.counter = _counter;
    shareUpdate.deltaLambda = getUint(
      keccak256(abi.encode('dao.shares.deltaLambda', _counter, _uuid))
    );
    shareUpdate.isIncreasing = getBool(
      keccak256(abi.encode('dao.shares.isIncreasing', _counter, _uuid))
    );
    shareUpdate.k = getUint(keccak256(abi.encode('dao.shares.constant', _counter, _uuid)));
    shareUpdate.m = getUint(keccak256(abi.encode('dao.shares.modifier', _counter, _uuid)));
    shareUpdate.deltaT = ElasticMathLib.t(shareUpdate.deltaLambda, shareUpdate.m, shareUpdate.k);

    shareUpdate.uuid = _uuid;
    return shareUpdate;
  }

  function _deserializeToken() internal view returns (ElasticStorage.Token memory token) {
    token.capitalDelta = getUint('dao.token.initialCapitalDelta');
    token.elasticity = getUint('dao.token.elasticity');
    token.k = getUint('dao.token.constant');
    token.lambda = getUint('dao.token.totalShares');
    token.m = getUint('dao.token.modifier');
    token.maxLambdaPurchase = getUint('dao.token.maxLambdaPurchase');
    token.name = getString('dao.token.name');
    token.symbol = getString('dao.token.symbol');
    token.uuid = getAddress('dao.token.address');
    return token;
  }

  function _serializeAccountBalance(ElasticStorage.AccountBalance memory accountBalance) internal {
    setUint(keccak256(abi.encode('dao.shares', accountBalance.uuid)), accountBalance.lambda);
    setUint(
      keccak256(abi.encode('dao.shares.counter', accountBalance.uuid)),
      accountBalance.counter
    );
  }

  function _serializeMathData(ElasticStorage.MathData memory mathData) internal {
    setUint('dao.totalShares', mathData.lambda);
    setUint('dao.token.modifier', mathData.m);
  }

  function _serializeShareUpdate(ElasticStorage.ShareUpdate memory shareUpdate) internal {
    setBool(
      keccak256(abi.encode('dao.shares.isIncreasing', shareUpdate.counter, shareUpdate.uuid)),
      shareUpdate.isIncreasing
    );
    setUint(
      keccak256(abi.encode('dao.shares.blockNumber', shareUpdate.counter, shareUpdate.uuid)),
      shareUpdate.blockNumber
    );
    setUint(
      keccak256(abi.encode('dao.shares.deltaLambda', shareUpdate.counter, shareUpdate.uuid)),
      shareUpdate.deltaLambda
    );
    setUint(
      keccak256(abi.encode('dao.shares.modifier', shareUpdate.counter, shareUpdate.uuid)),
      shareUpdate.m
    );
    setUint(
      keccak256(abi.encode('dao.shares.constant', shareUpdate.counter, shareUpdate.uuid)),
      shareUpdate.k
    );
  }

  function _serializeToken(ElasticStorage.Token memory token) internal {
    ElasticStorage.Token memory currentToken = _deserializeToken();

    if (currentToken.uuid != address(0)) {
      return;
    }

    if (token.uuid != address(0)) {
      setAddress('dao.token.address', token.uuid);
      return;
    }

    setString('dao.token.name', token.name);
    setString('dao.token.symbol', token.symbol);
    setUint('dao.token.constant', token.k);
    setUint('dao.token.initialCapitalDelta', token.capitalDelta);
    setUint('dao.token.elasticity', token.elasticity);
    setUint('dao.token.maxLambdaPurchase', token.maxLambdaPurchase);
    setUint('dao.token.modifier', token.m);
    setUint('dao.token.totalShares', token.lambda);
  }

  function _updateBalance(
    address _uuid,
    bool _isIncreasing,
    uint256 _deltaLambda
  ) internal {
    ElasticStorage.AccountBalance memory accountBalance = _deserializeAccountBalance(_uuid);
    ElasticStorage.Token memory token;
    token.lambda = getUint('dao.token.totalShares');

    if (_isIncreasing) {
      accountBalance.lambda = SafeMath.add(accountBalance.lambda, _deltaLambda);
      token.lambda = SafeMath.add(token.lambda, _deltaLambda);
    } else {
      accountBalance.lambda = SafeMath.sub(accountBalance.lambda, _deltaLambda);
      token.lambda = SafeMath.sub(token.lambda, _deltaLambda);
    }

    ElasticStorage.ShareUpdate memory shareUpdate;
    shareUpdate.blockNumber = block.number;
    shareUpdate.counter = accountBalance.counter;
    shareUpdate.deltaLambda = _deltaLambda;
    shareUpdate.isIncreasing = _isIncreasing;
    shareUpdate.k = accountBalance.k;
    shareUpdate.m = accountBalance.m;
    shareUpdate.uuid = _uuid;

    _serializeAccountBalance(accountBalance);
    _serializeShareUpdate(shareUpdate);
    setUint('dao.token.totalShares', token.lambda);
  }
}
