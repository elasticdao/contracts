const { deployments } = require('hardhat');

module.exports = async () => {
  const [DAO, Ecosystem, Factory, Token, TokenHolder] = await Promise.all([
    deployments.get('DAO_Implementation'),
    deployments.get('Ecosystem_Implementation'),
    deployments.get('ElasticDAOFactory_Implementation'),
    deployments.get('Token_Implementation'),
    deployments.get('TokenHolder_Implementation'),
  ]);
  const env = {
    elasticDAO: {
      daoModelAddress: DAO.address,
      ecosystemModelAddress: Ecosystem.address,
      factoryAddress: Factory.address,
      tokenModelAddress: Token.address,
      tokenHolderModelAddress: TokenHolder.address,
    },
    fees: {
      deploy: 0.25,
    },
  };

  return env;
};
