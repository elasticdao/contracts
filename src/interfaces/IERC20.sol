// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Emitted when the allowance of a @param _spender for @param _owner is set by
   * a call to {approve}
   * @param _amount is the new allowance
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

  /**
   * @dev Emitted when @param _amount tokens are moved from the @param _from account
   * to @param _to account
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _amount);

  /**
   * @dev Returns the remaining number of tokens that @param _spender will be
   * allowed to spend on behalf of @param _owner through {transferFrom}. This is
   * zero by default
   *
   * This value changes when {approve} or {transferFrom} are called
   */
  function allowance(address _owner, address _spender) external view returns (uint256);

  /**
   * @dev Sets @param _amount as the allowance of @param _spender over the caller's tokens
   *
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
   */
  function approve(address _spender, uint256 _amount) external returns (bool);

  /**
   * @dev Returns the amount of tokens owned by @param _owner.
   */
  function balanceOf(address _owner) external view returns (uint256);

  /**
   * @dev Returns the amount of tokens in existence
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Moves @param _amount tokens from the caller's account to @param _to address
   *
   * Returns a boolean value indicating whether the operation succeeded
   *
   * Emits a {Transfer} event
   */
  function transfer(address _to, uint256 _amount) external returns (bool);

  /**
   * @dev Moves @param _amount tokens from @param _from to @param _to using the
   * allowance mechanism. @param _amount is then deducted from the caller's
   * allowance
   *
   * Returns a boolean value indicating whether the operation succeeded
   *
   * Emits a {Transfer} event
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) external returns (bool);
}
