// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;

// Contracts
import "./EternalStorage.sol";

contract ElasticVote {
  EternalStorage internal eternalStorage;

  modifier onlyMinShares() {
    uint256 voteMinSharesToCreate = eternalStorage.getBool(
      StorageLib.formatLocation("dao.vote.minSharesToCreate")
    );
    uint256 memberShares = eternalStorage.getUint(
      StorageLib.formatAddress("dao.shares", msg.sender)
    );

    require(
      memberShares >= voteMinSharesToCreate,
      "ElasticDAO: Not enough shares to create a vote"
    );
    _;
  }

  constructor(address _eternalStorageAddress) {
    eternalStorage = EternalStorage(_eternalStorageAddress);
  }

  function createVoteInformation(string _voteProposal, uint256 _blockNumber) public onlyMinShares {
    uint256 voteMinBlocksInformation = eternalStorage.getUint(
      StorageLib.formatLocation("dao.vote.minBlocksInformation")
    );
    uint256 voteQuorum = eternalStorage.getUint(StorageLib.formatLocation("dao.vote.quorum"));
    uint256 voteReward = eternalStorage.getUint(StorageLib.formatLocation("dao.vote.reward"));
    uint256 userShares = eternalStorage.getUint(StorageLib.formatAddress("dao.shares", msg.sender));

    // adjust blockNumber to blocks till expiration and store block vote is created on
    // all vote settings
  }
}
