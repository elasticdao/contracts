const { deployments } = require('hardhat');

module.exports = async () => {
  const [DAO, Ecosystem, Factory, Token, TokenHolder] = await Promise.all([
    deployments.get('DAO'),
    deployments.get('Ecosystem'),
    deployments.get('ElasticDAOFactory'),
    deployments.get('Token'),
    deployments.get('TokenHolder'),
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
