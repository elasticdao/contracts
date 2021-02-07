// // const { expect } = require('chai');
// // const { ethers } = require('ethers');
// // const { deployments } = require('hardhat');

// const { signers, summonedDAO } = require('./helpers');

// describe('ElasticDAO: TokenHolder Model', () => {
//   it.only('Should check to see if a token holder record exists by account address', async () => {
//     const dao = await summonedDAO();
//     const { summoner1 } = await signers();
//     const { TokenHolder } = dao.sdk.models;
//     const token = await dao.token();

//     console.log('token', token.uuid, await TokenHolder.exists(summoner1.address, token));
//     // const recordExists = await tokenHolderStorage.exists(summoner1.address, token);
//     // console.log('recordExits', recordExists);
//     // expect(recordExists).to.equal(true);
//   });
// });
