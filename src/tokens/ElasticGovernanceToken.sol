// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;

import '../ElasticStorage.sol';

import '../libraries/StorageLib.sol';
import '../libraries/SafeMath.sol';

import '../interfaces/IERC20.sol';

contract ElasticGovernanceToken is IERC20 {
  ElasticStorage internal elasticStorage;

  mapping(address => mapping(address => uint256)) private _allowances;

  constructor(address _elasticStorageAddress) IERC20() {
    elasticStorage = ElasticStorage(_elasticStorageAddress);
  }

  function name() external view returns (string memory) {
    ElasticStorage.Token token = elasticStorage.getToken();
    return token.name;
  }

  function symbol() external view returns (string memory) {
    ElasticStorage.Token token = elasticStorage.getToken();
    return token.symbol;
  }

  function decimals() external pure returns (uint256) {
    return 18;
  }

  function totalSupply() external override view returns (uint256) {
    ElasticStorage.MathData mathData = elasticStorage.getMathData();
    return mathData.t;
  }

  function balanceOf(address _account) external override view returns (uint256) {
    ElasticStorage.AccountBalance memory accountBalance = elasticStorage.getAccountBalance(
      _account
    );
    return SafeMath.mul(walletLambda, SafeMath.mul(k, m));
  }

  function allowance(address _owner, address _spender)
    public
    virtual
    override
    view
    returns (uint256)
  {
    return _allowances[_owner][_spender];
  }

  function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
    _approve(msg.sender, _spender, SafeMath.add(_allowances[msg.sender][spender], _addedValue));
    return true;
  }

  function decreaseAllowance(address _spender, uint256 _subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 newAllowance = SafeMath.sub(_allowances[msg.sender][_spender], _subtractedValue);

    require(newAllowance > 0, 'ElasticDAO: Allowance decrease less than 0');

    _approve(msg.sender, _spender, newAllowance);
    return true;
  }

  function transfer(address _to, uint256 _amount) external override returns (bool) {
    _transfer(msg.sender, _to, _amount);

    return true;
  }

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

  function _transfer(
    address _from,
    address _to,
    uint256 _deltaT
  ) internal {
    ElasticStorage.AccountBalance memory accountBalance = elasticStorage.getAccountBalance(_from);

    uint256 deltaLambda = SafeMath.div(_deltaT, SafeMath.div(accountBalance.k, accountBalance.m));

    elasticStorage.updateBalance(_from, false, deltaLambda);
    elasticStorage.updateBalance(_to, true, deltaLambda);

    emit Transfer(_from, _to, _deltaT);
  }

  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) internal virtual {
    require(_owner != address(0), 'ERC20: approve from the zero address');
    require(_spender != address(0), 'ERC20: approve to the zero address');

    _allowances[_owner][_spender] = _amount;

    emit Approval(_owner, _spender, _amount);
  }
}
