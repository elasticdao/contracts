// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../../../models/EternalModel.sol';
import '../../../libraries/SafeMath.sol';

/// @author ElasticDAO - https://ElasticDAO.org
/// @notice This contract is used for storing information vote data
/// @dev ElasticDAO network contracts can read/write from this contract
// Serialize -> Translation of data from the concerned struct to key-value pairs
/// Deserialize -> Translation of data from the key-value pairs to a struct
contract Ballot is EternalModel {
  constructor() EternalModel() {}

  struct Instance {
    address uuid;
    uint256 lambda;
    uint256 voteId;
    uint256 yna;
  }

  /**
   * @dev deserializes Instance struct
   * @param _uuid - address of the unique manager instance
   * @param _voteId - the counter value of this vote
   * @return record Instance
   */
  function deserialize(address _uuid, uint256 _voteId)
    external
    view
    returns (Instance memory record)
  {
    record.uuid = _uuid;
    record.voteId = _voteId;

    if (_exists(_uuid, _voteId)) {
      record.lambda = getUint(keccak256(abi.encode('lambda', _uuid, _voteId)));
      record.voteId = getUint(keccak256(abi.encode('voteId', _uuid, _voteId)));
      record.yna = getUint(keccak256(abi.encode('yna', _uuid, _voteId)));
    }

    return record;
  }

  function exists(address _uuid, uint256 _voteId) external view returns (bool recordExists) {
    return _exists(_uuid, _voteId);
  }

  /**
   * @dev serializes Instance struct
   * @param record Instance
   */
  function serialize(Instance memory record) external {
    setUint(keccak256(abi.encode('lambda', record.uuid, record.voteId)), record.lambda);
    setUint(keccak256(abi.encode('voteId', record.uuid, record.voteId)), record.voteId);
    setUint(keccak256(abi.encode('yna', record.uuid, record.voteId)), record.yna);

    setBool(keccak256(abi.encode('exists', record.uuid, record.voteId)), true);
  }

  function _exists(address _uuid, uint256 _voteId) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode('exists', _uuid, _voteId)));
  }
}
