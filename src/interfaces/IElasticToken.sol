// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;

import './IERC20.sol';

interface IElasticToken is IERC20 {
  /**
   * @dev Returns the amount of shares owned by @param _account.
   * @param _account - address of the account
   * @return lambda uint256 - lambda is the number of shares
   */
  function balanceOfInShares(address _account) external view returns (uint256 lambda);

  /**
   * @dev Returns the amount of tokens owned by @param _account at @param _blockNumber.
   * @param _account - address of the account
   * @param _blockNumber - the blockNumber at which the balance is to be checked at
   * @return t uint256  - t is the number of tokens
   */
  function balanceOfAt(address _account, uint256 _blockNumber) external view returns (uint256 t);

  /**
   * @dev Returns the amount of shares owned by @param _account at @param _blockNumber.
   * @param _account - address of the account
   * @param _blockNumber - the blockNumber at which the balance of shares is to be checked at
   * @return lambda uint256 - lambda is the number of shares
   */
  function balanceOfInSharesAt(address _account, uint256 _blockNumber)
    external
    view
    returns (uint256 lambda);

  /**
   * @dev Reduces the balance(tokens) of @param _account by @param _amount
   * @param _account address of the account
   * @param _amount - the amount by which the number of tokens has to be reduced
   * @return bool
   */
  function burn(address _account, uint256 _amount) external returns (bool);

  /**
   * @dev Reduces the balance(shares) of @param _account by @param _amount
   * @param _account - address of the account
   * @param _amount - the amount by which the number of shares has to be reduced
   * @return bool
   */
  function burnShares(address _account, uint256 _amount) external returns (bool);

  /**
   * @dev mints @param _amount of shares for @param _account
   * @param _account address of the account
   * @param _amount - the amount of shares to be minted
   * @return bool
   */
  function mintShares(address _account, uint256 _amount) external returns (bool);

  /**
   * @dev returns total number of token holders
   * @return uint256
   */
  function numberOfTokenHolders() external view returns (uint256);

  /**
   * @dev Returns the total supply of shares in the DAO
   * @return lambda uint256 - lambda is the number of shares
   */
  function totalSupplyInShares() external view returns (uint256 lambda);
}
