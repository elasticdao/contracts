module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const ivBallot = await deploy('InformationalVoteBallot', {
    from: agent,
    args: [],
  });

  const ivSettings = await deploy('InformationalVoteSettings', {
    from: agent,
    args: [],
  });

  const ivVote = await deploy('InformationalVote', {
    from: agent,
    args: [],
  });

  const ivFactory = await deploy('InformationalVoteFactory', {
    from: agent,
    args: [],
  });

  if (ivBallot.newlyDeployed) {
    log(`##### ElasticDAO: InformationalVoteBallot has been deployed: ${ivBallot.address}`);
  }

  if (ivSettings.newlyDeployed) {
    log(`##### ElasticDAO: InformationalVoteSettings has been deployed: ${ivSettings.address}`);
  }

  if (ivVote.newlyDeployed) {
    log(`##### ElasticDAO: InformationalVote has been deployed: ${ivVote.address}`);
  }

  if (ivFactory.newlyDeployed) {
    log(`##### ElasticDAO: InformationalVoteFactory has been deployed: ${ivFactory.address}`);
  }
};
module.exports.tags = ['InformationalVote'];
