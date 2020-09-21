// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;

import './EternalStorage.sol';

contract ElasticStorage is EternalStorage {
  function daoSummoned() external view returns (bool isSummoned) {}

  function isSummoner(address _account) external view returns (bool accountIsSummoner) {}
}
