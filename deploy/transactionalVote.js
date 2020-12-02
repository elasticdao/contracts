module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const transactionalBallot = await deploy('TransactionalVoteBallot', {
    from: agent,
    args: [],
  });

  const transactionalSettings = await deploy('TransactionalVoteSettings', {
    from: agent,
    args: [],
  });

  const transactionalVote = await deploy('TransactionalVote', {
    from: agent,
    args: [],
  });

  const transactionalFactory = await deploy('TransactionalVoteFactory', {
    from: agent,
    args: [],
  });

  if (transactionalBallot.newlyDeployed) {
    log(
      `##### ElasticDAO: TransactionalVoteBallot has been deployed: ${transactionalBallot.address}`,
    );
  }

  if (transactionalSettings.newlyDeployed) {
    log(
      `##### ElasticDAO: TransactionalVoteSettings has been deployed: ${transactionalSettings.address}`,
    );
  }

  if (transactionalVote.newlyDeployed) {
    log(`##### ElasticDAO: TransactionalVote has been deployed: ${transactionalVote.address}`);
  }

  if (transactionalFactory.newlyDeployed) {
    log(
      `##### ElasticDAO: TransactionalVoteFactory has been deployed: ${transactionalFactory.address}`,
    );
  }
};
module.exports.tags = ['TransactionalVote'];
