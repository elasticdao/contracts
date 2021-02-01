const { deployments } = require('hardhat');

describe('0_init_contracts_for_testing', () => {
  // this is required to make solidity-coverage work
  it('Should await fixtures to enable coverage tests', async () => {
    await deployments.fixture();
  });
});
