// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../interfaces/IElasticToken.sol';

import '../libraries/SafeMath.sol';
import '../libraries/ElasticMath.sol';

import '../models/BalanceChange.sol';
import '../models/DAO.sol';
import '../models/Ecosystem.sol';
import '../models/Token.sol';
import '../models/TokenHolder.sol';

/**
 * @dev Implementation of the IERC20 interface
 */
contract ElasticGovernanceToken is IElasticToken {
  address daoAddress;
  address ecosystemModelAddress;

  mapping(address => mapping(address => uint256)) private _allowances;

  modifier onlyDAO() {
    require(msg.sender == daoAddress, 'ElasticDAO: Not authorized.');
    _;
  }

  constructor(address _daoAddress, address _ecosystemModelAddress) IERC20() {
    daoAddress = _daoAddress;
    ecosystemModelAddress = _ecosystemModelAddress;
  }

  /**
   * @dev Returns the remaining number of tokens that @param _spender will be
   * allowed to spend on behalf of @param _owner through {transferFrom}. This is
   * zero by default
   * @param _spender - the address of the spender
   * @param _owner - the address of the owner
   * This value changes when {approve} or {transferFrom} are called
   * @return uint256
   */
  function allowance(address _owner, address _spender) external override view returns (uint256) {
    return _allowances[_owner][_spender];
  }

  /**
   * @dev Sets @param _amount as the allowance of @param _spender over the caller's tokens
   * @param _spender - the address of the spender
   * Returns a boolean value indicating whether the operation succeeded
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event
   * @return bool
   */
  function approve(address _spender, uint256 _amount) external override returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * @dev Returns the amount of tokens owned by @param _account.
   * @param _account - address of the account
   * @return uint256
   */
  function balanceOf(address _account) external override view returns (uint256) {
    Token.Instance memory token = _getToken();
    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);

    uint256 t = ElasticMath.t(tokenHolder.lambda, token.k, token.m);

    return t;
  }

  function balanceOfInShares(address _account) external override view returns (uint256 lambda) {
    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);
    return tokenHolder.lambda;
  }

  /**
   * @dev Returns the amount of tokens owned by @param _account at the specific @param _blockNumber
   * @param _account - address of the account
   * @return t uint256 - the number of tokens
   */
  function balanceOfAt(address _account, uint256 _blockNumber)
    external
    override
    view
    returns (uint256 t)
  {
    uint256 i = 0;
    uint256 lambda = 0;
    t = 0;

    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);
    BalanceChange.Instance memory balanceChange = _getBalanceChange(_account, i);

    while (
      i <= tokenHolder.counter &&
      balanceChange.blockNumber != 0 &&
      balanceChange.blockNumber <= _blockNumber
    ) {
      if (balanceChange.isIncreasing) {
        lambda = SafeMath.add(lambda, balanceChange.deltaLambda);
        t = ElasticMath.t(lambda, balanceChange.m, balanceChange.k);
      } else {
        lambda = SafeMath.sub(lambda, balanceChange.deltaLambda);
        t = ElasticMath.t(lambda, balanceChange.m, balanceChange.k);
      }

      i = SafeMath.add(i, 1);
      balanceChange = _getBalanceChange(_account, i);
    }

    return t;
  }

  function balanceOfInSharesAt(address _account, uint256 _blockNumber)
    external
    override
    view
    returns (uint256 lambda)
  {
    uint256 i = 0;
    lambda = 0;

    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);
    BalanceChange.Instance memory balanceChange = _getBalanceChange(_account, i);

    while (
      i <= tokenHolder.counter &&
      balanceChange.blockNumber != 0 &&
      balanceChange.blockNumber <= _blockNumber
    ) {
      if (balanceChange.isIncreasing) {
        lambda = SafeMath.add(lambda, balanceChange.deltaLambda);
      } else {
        lambda = SafeMath.sub(lambda, balanceChange.deltaLambda);
      }

      i = SafeMath.add(i, 1);
      balanceChange = _getBalanceChange(_account, i);
    }

    return lambda;
  }

  function burn(address _account, uint256 _amount) external override onlyDAO returns (bool) {
    _burn(_account, _amount);
    return true;
  }

  function burnShares(address _account, uint256 _amount) external override returns (bool) {
    _burnShares(_account, _amount);
    return true;
  }

  /**
   * @dev returns the number of decimals
   * @return 18
   */
  function decimals() external pure returns (uint256) {
    return 18;
  }

  /**
   * @dev decreases the allowance of @param _spender by @param _subtractedValue
   * @param _spender - address of the spender
   * @param _subtractedValue - the value the allowance has to be decreased by
   * @return bool
   */
  function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
    uint256 newAllowance = SafeMath.sub(_allowances[msg.sender][_spender], _subtractedValue);

    require(newAllowance > 0, 'ElasticDAO: Allowance decrease less than 0');

    _approve(msg.sender, _spender, newAllowance);
    return true;
  }

  /**
   * @dev increases the allowance of @param _spender by @param _addedValue
   * @param _spender - address of the spender
   * @param _addedValue - the value the allowance has to be increased by
   * @return bool
   */
  function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
    _approve(msg.sender, _spender, SafeMath.add(_allowances[msg.sender][_spender], _addedValue));
    return true;
  }

  /**
   * @dev mints @param _amount tokens for @param _account
   * @param _amount - the amount of tokens to be minted
   * @param _account - the address of the account for whom the token have to be minted to
   */
  function mint(address _account, uint256 _amount) external onlyDAO returns (bool) {
    _mint(_account, _amount);

    return true;
  }

  function mintShares(address _account, uint256 _amount) external override returns (bool) {
    _mintShares(_account, _amount);
    return true;
  }

  /**
   * @dev Returns the name of the token.
   * @return string - name of the token
   */
  function name() external view returns (string memory) {
    return _getToken().name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   * @return string - thr symbol of the toen
   */
  function symbol() external view returns (string memory) {
    return _getToken().symbol;
  }

  /**
   * @dev returns the totalSupply of tokens in thee DAO
   * t - the total number of tokens in the DAO
   * lambda - the total number of shares outstanding in the DAO currently
   * m - current value of the share modifier
   * k - constant
   * t = ( lambda * m * k )
   * @return uint256 - the value of t
   */
  function totalSupply() external override view returns (uint256) {
    Token.Instance memory token = _getToken();
    return SafeMath.mul(token.lambda, SafeMath.mul(token.k, token.m));
  }

  function totalSupplyInShares() external override view returns (uint256) {
    Token.Instance memory token = _getToken();
    return token.lambda;
  }

  /**
   * @dev Moves @param _amount tokens from the caller's account to @param _to address
   *
   * Returns a boolean value indicating whether the operation succeeded
   *
   * Emits a {Transfer} event
   * @return bool
   */
  function transfer(address _to, uint256 _amount) external override returns (bool) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  /**
   * @dev Moves @param _amount tokens from @param _from to @param _to using the
   * allowance mechanism. @param _amount is then deducted from the caller's
   * allowance
   *
   * Returns a boolean value indicating whether the operation succeeded
   *
   * Emits a {Transfer} event
   * @return bool
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) external override returns (bool) {
    require(msg.sender == _from || _amount <= _allowances[_from][msg.sender], 'ERC20: Bad Caller');

    _transfer(_from, _to, _amount);

    if (msg.sender != _from && _allowances[_from][msg.sender] != uint256(-1)) {
      _allowances[_from][msg.sender] = SafeMath.sub(_allowances[_from][msg.sender], _amount);

      emit Approval(msg.sender, _to, _allowances[_from][msg.sender]);
    }

    return true;
  }

  // Private

  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) internal {
    require(_owner != address(0), 'ERC20: approve from the zero address');
    require(_spender != address(0), 'ERC20: approve to the zero address');

    _allowances[_owner][_spender] = _amount;

    emit Approval(_owner, _spender, _amount);
  }

  function _burn(address _account, uint256 _deltaT) internal {
    Token.Instance memory token = _getToken();
    uint256 deltaLambda = SafeMath.div(_deltaT, SafeMath.div(token.k, token.m));
    _burnShares(_account, deltaLambda);
  }

  function _burnShares(address _account, uint256 _deltaLambda) internal {
    Token.Instance memory token = _getToken();
    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);

    tokenHolder = _updateBalance(token, tokenHolder, false, _deltaLambda);

    token.lambda = SafeMath.sub(token.lambda, _deltaLambda);

    Ecosystem.Instance memory ecosystem = _getEcosystem();
    Token tokenStorage = Token(ecosystem.tokenModelAddress);
    tokenStorage.serialize(token);

    TokenHolder tokenHolderStorage = TokenHolder(ecosystem.tokenHolderModelAddress);
    tokenHolderStorage.serialize(tokenHolder);
  }

  function _mint(address _account, uint256 _deltaT) internal {
    Token.Instance memory token = _getToken();
    uint256 deltaLambda = SafeMath.div(_deltaT, SafeMath.div(token.k, token.m));
    _mintShares(_account, deltaLambda);
  }

  function _mintShares(address _account, uint256 _deltaLambda) internal {
    Token.Instance memory token = _getToken();
    TokenHolder.Instance memory tokenHolder = _getTokenHolder(_account);

    uint256 deltaT = ElasticMath.t(_deltaLambda, token.k, token.m);

    tokenHolder = _updateBalance(token, tokenHolder, true, _deltaLambda);

    token.lambda = SafeMath.add(token.lambda, _deltaLambda);

    Ecosystem.Instance memory ecosystem = _getEcosystem();
    Token tokenStorage = Token(ecosystem.tokenModelAddress);
    tokenStorage.serialize(token);

    TokenHolder tokenHolderStorage = TokenHolder(ecosystem.tokenHolderModelAddress);
    tokenHolderStorage.serialize(tokenHolder);

    emit Transfer(address(0), _account, deltaT);
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _deltaT
  ) internal {
    Token.Instance memory token = _getToken();

    TokenHolder.Instance memory fromTokenHolder = _getTokenHolder(_from);
    TokenHolder.Instance memory toTokenHolder = _getTokenHolder(_to);

    uint256 deltaLambda = SafeMath.div(_deltaT, SafeMath.div(token.k, token.m));
    uint256 deltaT = ElasticMath.t(deltaLambda, token.k, token.m);

    fromTokenHolder = _updateBalance(token, fromTokenHolder, false, deltaLambda);
    toTokenHolder = _updateBalance(token, toTokenHolder, true, deltaLambda);

    TokenHolder tokenHolderStorage = TokenHolder(_getEcosystem().tokenHolderModelAddress);
    tokenHolderStorage.serialize(fromTokenHolder);
    tokenHolderStorage.serialize(toTokenHolder);

    emit Transfer(_from, _to, deltaT);
  }

  function _updateBalance(
    Token.Instance memory _token,
    TokenHolder.Instance memory _tokenHolder,
    bool _isIncreasing,
    uint256 _deltaLambda
  ) internal returns (TokenHolder.Instance memory) {
    BalanceChange.Instance memory balanceChange;
    balanceChange.blockNumber = block.number;

    balanceChange.deltaLambda = _deltaLambda;
    balanceChange.id = _tokenHolder.counter;
    balanceChange.isIncreasing = _isIncreasing;

    balanceChange.k = _token.k;

    balanceChange.m = _token.m;

    balanceChange.tokenAddress = _token.uuid;
    balanceChange.uuid = _tokenHolder.uuid;

    //_tokenHolder.balanceChanges.(balanceChange);

    _tokenHolder.counter = SafeMath.add(_tokenHolder.counter, 1);

    if (_isIncreasing) {
      _tokenHolder.lambda = SafeMath.add(_tokenHolder.lambda, _deltaLambda);
    } else {
      _tokenHolder.lambda = SafeMath.sub(_tokenHolder.lambda, _deltaLambda);
    }
    BalanceChange(_getEcosystem().balanceChangeModelAddress).serialize(balanceChange);

    return _tokenHolder;
  }

  // Private Getters

  function _getBalanceChange(address _uuid, uint256 _id)
    internal
    view
    returns (BalanceChange.Instance memory)
  {
    address balanceChangeModelAddress = _getEcosystem().balanceChangeModelAddress;

    return BalanceChange(balanceChangeModelAddress).deserialize(address(this), _uuid, _id);
  }

  function _getEcosystem() internal view returns (Ecosystem.Instance memory) {
    return Ecosystem(ecosystemModelAddress).deserialize(daoAddress);
  }

  function _getTokenHolder(address _uuid) internal view returns (TokenHolder.Instance memory) {
    return TokenHolder(_getEcosystem().tokenHolderModelAddress).deserialize(_uuid, address(this));
  }

  function _getToken() internal view returns (Token.Instance memory) {
    return Token(_getEcosystem().tokenModelAddress).deserialize(address(this));
  }
}
