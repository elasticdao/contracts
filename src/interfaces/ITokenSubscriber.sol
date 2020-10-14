// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;

interface ITokenSubscriber {
  function shareUpdateCallback(
    address _tokenAddress,
    address _accountAddress,
    uint256 _previousBalance,
    uint256 _nextBalance
  ) external;
}
