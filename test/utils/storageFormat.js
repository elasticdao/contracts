const ethers = require("ethers");
const { defaultAbiCoder, keccak256 } = ethers.utils;

module.exports = {
  storageFormat: (storageTypes, storageLocation) => {
    return keccak256(defaultAbiCoder.encode(storageTypes, storageLocation));
  },
};
