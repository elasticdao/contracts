// [
//   ethers.BigNumber.from('100000000000000000000'), // k
//   ethers.BigNumber.from('100000000000000000'), // capitalDelta
//   ethers.BigNumber.from('20000000000000000'), // elasticity
//   ethers.BigNumber.from('1000000000000000000'), // initialShares
//   ethers.BigNumber.from('600000000000000000'), // approval
//   ethers.BigNumber.from('1000000000000000000'), // maxSharesPerAccount
//   ethers.BigNumber.from('120'), // contractVoteTypeMinBlocks
//   ethers.BigNumber.from('180'), // financeVoteTypeMinBlocks
//   ethers.BigNumber.from('60'), // informationVoteTypeMinBlocks
//   ethers.BigNumber.from('240'), // minBlocksForPenalty
//   ethers.BigNumber.from('90'), // permissionVoteTypeMinBlocks
//   ethers.BigNumber.from('1000000000000000000'), // minSharesToCreate
//   ethers.BigNumber.from('50000000000000000'), // penalty
//   ethers.BigNumber.from('500000000000000000'), // quorum
//   ethers.BigNumber.from('100000000000000000'), // reward
// ]

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const daoModel = await deploy('DAO', {
    from: agent,
    args: [],
  });

  if (daoModel.newlyDeployed) {
    log(`##### ElasticDAO: DAO Model has been deployed: ${daoModel.address}`);
  }
};
module.exports.tags = ['DAO'];
