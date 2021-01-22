const { deployments } = require('hardhat');

module.exports = async () => {
  const [
    Balance,
    BalanceMultipliers,
    DAO,
    Ecosystem,
    ElasticModule,
    Factory,
    Token,
    TokenHolder,
    InformationalVote,
    InformationalVoteBallot,
    InformationalVoteFactory,
    InformationalVoteSettings,
    TransactionalVote,
    TransactionalVoteBallot,
    TransactionalVoteFactory,
    TransactionalVoteSettings,
  ] = await Promise.all([
    deployments.get('Balance'),
    deployments.get('BalanceMultipliers'),
    deployments.get('DAO'),
    deployments.get('Ecosystem'),
    deployments.get('ElasticModule'),
    deployments.get('ElasticDAOFactory'),
    deployments.get('Token'),
    deployments.get('TokenHolder'),
    deployments.get('InformationalVote'),
    deployments.get('InformationalVoteBallot'),
    deployments.get('InformationalVoteFactory'),
    deployments.get('InformationalVoteSettings'),
    deployments.get('TransactionalVote'),
    deployments.get('TransactionalVoteBallot'),
    deployments.get('TransactionalVoteFactory'),
    deployments.get('TransactionalVoteSettings'),
  ]);
  const env = {
    elasticDAO: {
      balanceModelAddress: Balance.address,
      balanceMultipliersModelAddress: BalanceMultipliers.address,
      daoModelAddress: DAO.address,
      ecosystemModelAddress: Ecosystem.address,
      elasticModuleModelAddress: ElasticModule.address,
      factoryAddress: Factory.address,
      tokenModelAddress: Token.address,
      tokenHolderModelAddress: TokenHolder.address,

      modules: {
        informationalVote: {
          ballotModelAddress: InformationalVoteBallot.address,
          factoryAddress: InformationalVoteFactory.address,
          settingsModelAddress: InformationalVoteSettings.address,
          voteModelAddress: InformationalVote.address,
        },
        transactionalVote: {
          ballotModelAddress: TransactionalVoteBallot.address,
          factoryAddress: TransactionalVoteFactory.address,
          settingsModelAddress: TransactionalVoteSettings.address,
          voteModelAddress: TransactionalVote.address,
        },
      },
    },
    fees: {
      deploy: 0.25,
    },
  };

  return env;
};
