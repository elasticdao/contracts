// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './EternalStorage.sol';
import './ElasticStorage.sol';
import './libraries/ElasticMathLib.sol';
import './libraries/SafeMath.sol';
import './libraries/StringLib.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing Elastic Vote data
/// @dev ElasticDAO network contracts can read/write from this contract
/// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract ElasticVoteStorage is EternalStorage {
  constructor(address _owner) EternalStorage(_owner) {}

  modifier onlyOwnerOrVoteModule() {
    address voteModuleAddress = getAddress('dao.vote.address');
    require(
      msg.sender == owner || msg.sender == voteModuleAddress,
      'ElasticDAO: Not authorized to call that function.'
    );
    _;
  }

  /**
   * @dev grants a specific address the ability to create a vote
   * @param _uuid is the address the permission is to be granted to
   * lambda - the the total shares of the DAO
   * minSharesToCreate - the minimum number of shares required to create a vote in the DAO
   * checks if lambda >= minSharesToCreate
   * @return hasPermission bool
   */
  function canCreateVote(address _uuid)
    external
    view
    onlyOwnerOrVoteModule
    returns (bool hasPermission)
  {
    uint256 lambda = getUint(keccak256(abi.encode('dao.shares', _uuid)));
    uint256 minSharesToCreate = getUint('dao.vote.minSharesToCreate');
    return lambda >= minSharesToCreate;
  }

  /**
   * @dev creates the vote information
   * @param _vote is the vote itself
   * @param _voteInformation is the information regarding the current vote
   * @param _voteSettings are the settings which the current vote has to follow
   * The function takes in params and serializes vote, voteInformation
   * and sets the DAO's Vote counter.
   */
  function createVoteInformation(
    ElasticStorage.Vote memory _vote,
    ElasticStorage.VoteInformation memory _voteInformation,
    ElasticStorage.VoteSettings memory _voteSettings
  ) external onlyOwnerOrVoteModule {
    _serializeVote(_vote);
    _serializeVoteInformation(_voteInformation);
    setUint('dao.vote.counter', _voteSettings.counter);
  }

  /**
   * @dev Gets the vote using it's ID
   * @param _id - The id of the vote requested
   * @return vote Vote
   */
  function getVote(uint256 _id)
    external
    view
    onlyOwnerOrVoteModule
    returns (ElasticStorage.Vote memory vote)
  {
    return _deserializeVote(_id);
  }

  /**
   * @dev Gets the vote information
   * @param _id - The id of the vote
   * @return voteInformation VoteInformation
   */
  function getVoteInformation(uint256 _id)
    external
    view
    onlyOwnerOrVoteModule
    returns (ElasticStorage.VoteInformation memory voteInformation)
  {
    return _deserializeVoteInformation(_id);
  }

  /**
   * @dev Gets the Vote settings
   * @return voteSettings VoteSettings
   */
  function getVoteSettings()
    external
    view
    onlyOwnerOrVoteModule
    returns (ElasticStorage.VoteSettings memory voteSettings)
  {
    return _deserializeVoteSettings();
  }

  /**
   * @dev Gets the voteType based on its name
   * @param _name - The name of the vote
   * @return voteType VoteType
   */
  function getVoteType(string memory _name)
    external
    view
    onlyOwnerOrVoteModule
    returns (ElasticStorage.VoteType memory voteType)
  {
    return _deserializeVoteType(_name);
  }

  /**
   * @dev checks whether the vote is active or not
   * @param _id - the ID of the vote
   * @return bool
   */
  function isVoteActive(uint256 _id) external view onlyOwnerOrVoteModule returns (bool) {
    return _isVoteActive(_id);
  }

  function recordBallotChange(
    uint256 _id,
    uint256 _deltaLambda,
    bool _isIncreasing,
    string memory _ynaKey
  ) external onlyOwner {
    _recordBallotChange(_id, _deltaLambda, _isIncreasing, _ynaKey);
  }

  /**
   * @dev sets the vote module
   * @param _voteModuleAddress - the addresss of the vote module
   */
  function setVoteModule(address _voteModuleAddress) external onlyOwner {
    setAddress('dao.vote.address', _voteModuleAddress);
  }

  /**
   * @dev Sets the vote settings
   * @param voteSettings - the vote settings which have to be set
   */
  function setVoteSettings(ElasticStorage.VoteSettings memory voteSettings) external onlyOwner {
    _serializeVoteSettings(voteSettings);
  }

  /**
   * @dev Sets the type of the vote
   * @param voteType - the type of the vote itself
   */
  function setVoteType(ElasticStorage.VoteType memory voteType) external onlyOwner {
    _serializeVoteType(voteType);
  }

  function _deserializeVote(uint256 _id) internal view returns (ElasticStorage.Vote memory vote) {
    vote.abstainLambda = getUint(keccak256(abi.encode('dao.vote.', _id, '.abstainLambda')));
    vote.approval = getUint(keccak256(abi.encode('dao.vote.', _id, '.approval')));
    vote.endOnBlock = getUint(keccak256(abi.encode('dao.vote.', _id, '.endOnBlock')));
    vote.hasPenalty = getBool(keccak256(abi.encode('dao.vote.', _id, '.hasPenalty')));
    vote.hasReachedQuorum = false;
    vote.id = _id;
    vote.isActive = _isVoteActive(vote.id);
    vote.isApproved = false;
    vote.maxSharesPerAccount = getUint(
      keccak256(abi.encode('dao.vote.', _id, '.maxSharesPerAccount'))
    );
    vote.minBlocksForPenalty = getUint(
      keccak256(abi.encode('dao.vote.', _id, '.minBlocksForPenalty'))
    );
    vote.noLambda = getUint(keccak256(abi.encode('dao.vote.', _id, '.noLambda')));
    vote.penalty = getUint(keccak256(abi.encode('dao.vote.', _id, '.penalty')));
    vote.quorum = getUint(keccak256(abi.encode('dao.vote.', _id, '.quorum')));
    vote.reward = getUint(keccak256(abi.encode('dao.vote.', _id, '.reward')));
    vote.startOnBlock = getUint(keccak256(abi.encode('dao.vote.', _id, '.startOnBlock')));
    vote.voteType = getString(keccak256(abi.encode('dao.vote.', _id, '.voteType')));
    vote.yesLambda = getUint(keccak256(abi.encode('dao.vote.', _id, '.yesLambda')));

    ElasticStorage.Token memory token = ElasticStorage(owner).getToken();
    uint256 minimumQuorumLambda = ElasticMathLib.wmul(token.lambda, getUint('dao.vote.quorum'));
    uint256 minimumYesLambda = ElasticMathLib.wmul(token.lambda, getUint('dao.vote.approval'));
    uint256 quorumLambda = SafeMath.add(
      vote.yesLambda,
      SafeMath.add(vote.noLambda, vote.abstainLambda)
    );

    if (quorumLambda >= minimumQuorumLambda) {
      vote.hasReachedQuorum = true;
    }

    if (vote.yesLambda >= minimumYesLambda) {
      vote.isApproved = true;
    }

    return vote;
  }

  function _deserializeVoteInformation(uint256 _id)
    internal
    view
    returns (ElasticStorage.VoteInformation memory voteInformation)
  {
    voteInformation.id = _id;
    voteInformation.proposal = getString(
      keccak256(abi.encode('dao.vote.information.', _id, '.proposal'))
    );
    return voteInformation;
  }

  function _deserializeVoteSettings()
    internal
    view
    returns (ElasticStorage.VoteSettings memory voteSettings)
  {
    voteSettings.approval = getUint('dao.vote.approval');
    voteSettings.counter = getUint('dao.vote.counter');
    voteSettings.maxSharesPerAccount = getUint('dao.vote.maxSharesPerAccount');
    voteSettings.minBlocksForPenalty = getUint('dao.vote.minBlocksForPenalty');
    voteSettings.minSharesToCreate = getUint('dao.vote.minSharesToCreate');
    voteSettings.penalty = getUint('dao.vote.penalty');
    voteSettings.quorum = getUint('dao.vote.quorum');
    voteSettings.reward = getUint('dao.vote.reward');
    return voteSettings;
  }

  function _deserializeVoteType(string memory name)
    internal
    view
    returns (ElasticStorage.VoteType memory voteType)
  {
    voteType.name = name;
    voteType.hasPenalty = getBool(keccak256(abi.encode('dao.vote.type', name, 'hasPenalty')));
    voteType.minBlocks = getUint(keccak256(abi.encode('dao.vote.type', name, 'minBlocks')));
    return voteType;
  }

  function _isVoteActive(uint256 _id) internal view returns (bool) {
    uint256 endOnBlock = getUint(keccak256(abi.encode('dao.vote.', _id, '.endOnBlock')));
    uint256 startOnBlock = getUint(keccak256(abi.encode('dao.vote.', _id, '.endOnBlock')));
    return block.number >= startOnBlock && block.number <= endOnBlock;
  }

  function _recordBallotChange(
    uint256 _id,
    uint256 _deltaLambda,
    bool _isIncreasing,
    string memory _ynaKey
  ) internal {
    bytes32 key = keccak256(abi.encode('dao.vote.', _id, _ynaKey));
    if (_isIncreasing) {
      setUint(key, SafeMath.add(getUint(key), _deltaLambda));
    } else {
      setUint(key, SafeMath.sub(getUint(key), _deltaLambda));
    }
  }

  function _serializeVoteSettings(ElasticStorage.VoteSettings memory voteSettings) internal {
    setUint('dao.vote.approval', voteSettings.approval);
    setUint('dao.vote.counter', voteSettings.counter);
    setUint('dao.vote.maxSharesPerAccount', voteSettings.maxSharesPerAccount);
    setUint('dao.vote.minBlocksForPenalty', voteSettings.minBlocksForPenalty);
    setUint('dao.vote.minSharesToCreate', voteSettings.minSharesToCreate);
    setUint('dao.vote.penalty', voteSettings.penalty);
    setUint('dao.vote.quorum', voteSettings.quorum);
    setUint('dao.vote.reward', voteSettings.reward);
  }

  function _serializeVote(ElasticStorage.Vote memory vote) internal {
    setBool(keccak256(abi.encode('dao.vote.', vote.id, '.hasPenalty')), vote.hasPenalty);
    setString(keccak256(abi.encode('dao.vote.', vote.id, '.voteType')), vote.voteType);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.abstainLambda')), vote.abstainLambda);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.approval')), vote.approval);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.endOnBlock')), vote.endOnBlock);
    setUint(
      keccak256(abi.encode('dao.vote.', vote.id, '.maxSharesPerAccount')),
      vote.maxSharesPerAccount
    );
    setUint(
      keccak256(abi.encode('dao.vote.', vote.id, '.minBlocksForPenalty')),
      vote.minBlocksForPenalty
    );
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.noLambda')), vote.noLambda);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.penalty')), vote.penalty);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.quorum')), vote.quorum);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.reward')), vote.reward);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.startOnBlock')), vote.startOnBlock);
    setUint(keccak256(abi.encode('dao.vote.', vote.id, '.yesLambda')), vote.yesLambda);
  }

  function _serializeVoteInformation(ElasticStorage.VoteInformation memory voteInformation)
    internal
  {
    setString(
      keccak256(abi.encode('dao.vote.information.', voteInformation.id, '.proposal')),
      voteInformation.proposal
    );
  }

  function _serializeVoteType(ElasticStorage.VoteType memory voteType) internal {
    setBool(
      keccak256(abi.encode('dao.vote.type', voteType.name, 'hasPenalty')),
      voteType.hasPenalty
    );
    setUint(keccak256(abi.encode('dao.vote.type', voteType.name, 'minBlocks')), voteType.minBlocks);
  }
}
