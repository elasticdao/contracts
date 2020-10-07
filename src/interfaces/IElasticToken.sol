// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;

import './IERC20.sol';

interface IElasticToken is IERC20 {
  function balanceOfInShares(address _account) external view returns (uint256 lambda);

  function balanceOfAt(address _account, uint256 _blockNumber) external view returns (uint256 t);

  function balanceOfInSharesAt(address _account, uint256 _blockNumber)
    external
    view
    returns (uint256 lambda);

  function burn(address _account, uint256 _amount) external returns (bool);

  function burnShares(address _account, uint256 _amount) external returns (bool);

  function mintShares(address _account, uint256 _amount) external returns (bool);

  function totalSupplyInShares() external view returns (uint256 lambda);
}
