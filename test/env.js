const { deployments } = require('hardhat');

module.exports = async () => {
  const Factory = await deployments.get('ElasticDAOFactory');
  const env = {
    factoryAddress: Factory.address,
  };

  return env;
};
