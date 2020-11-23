module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const informationalVoteBallot = await deploy('InformationalVoteBallot', {
    from: agent,
    args: [],
  });

  const informationalVoteSettings = await deploy('InformationalVoteSettings', {
    from: agent,
    args: [],
  });

  const informationalVoteVote = await deploy('InformationalVote', {
    from: agent,
    args: [],
  });

  const informationalVoteFactory = await deploy('InformationalVoteFactory', {
    from: agent,
    args: [],
  });

  if (informationalVoteBallot.newlyDeployed) {
    log(
      `##### ElasticDAO: InformationalVoteBallot has been deployed: ${informationalVoteBallot.address}`,
    );
  }

  if (informationalVoteSettings.newlyDeployed) {
    log(
      `##### ElasticDAO: InformationalVoteSettings has been deployed: ${informationalVoteSettings.address}`,
    );
  }

  if (informationalVoteVote.newlyDeployed) {
    log(`##### ElasticDAO: InformationalVote has been deployed: ${informationalVoteVote.address}`);
  }

  if (informationalVoteFactory.newlyDeployed) {
    log(
      `##### ElasticDAO: InformationalVoteFactory has been deployed: ${informationalVoteFactory.address}`,
    );
  }
};
module.exports.tags = ['InformationalVote'];
