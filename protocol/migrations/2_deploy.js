const fs = require('fs');
const path = require('path');

const Deployer1 = artifacts.require("Deployer1");
const Deployer2 = artifacts.require("Deployer2");
const Deployer3 = artifacts.require("Deployer3");
const Dollar = artifacts.require("Dollar");
const Oracle = artifacts.require("Oracle");

const contractCache = require('./contracts-cache.json')

const Implementation = artifacts.require("Implementation");
const Root = artifacts.require("Root");
const TestnetUSDC = artifacts.require("TestnetUSDC");

async function getCurrentAccount() {
  return new Promise((resolve, reject) => {
    web3.eth.getAccounts(function(err, res) { resolve(res[0]) });
  });
}

async function deployTestnetUSDC(deployer) {
  await deployer.deploy(TestnetUSDC);
}

// return: [contractInstance, hasDeployed]
async function getDeployed(deployer, name, Ctr, ...args) {
  let res;
  if (!contractCache[name]) {
    console.log(`========== not deployed contract: ${name}, deploying.. `);
    res = await deployer.deploy(Ctr, ...args);
    contractCache[name] = res.address;
    // write to file sync
    fs.writeFileSync(path.resolve(__dirname, './contracts-cache.json'), JSON.stringify(contractCache), 'utf8');
    console.log(`========== update address cache file: ${name}, address: ${res.address}`);
    return res;
  }
  else {
    return await Ctr.at(contractCache[name]);
  }
}

async function getAddresses(rootAddress) {
  const implement = await Implementation.at(rootAddress);
  const dollarAddress = await implement.dollar();
  const poolAddress = await implement.pool();
  const oracleAddress = await implement.oracle();

  const oracle = await Oracle.at(oracleAddress);
  const pairAddress = await oracle.pair();

  return {
    dollarAddress, 
    poolAddress, 
    pairAddress, 
    daoAddress: rootAddress,
  };
}

async function deployTestnet(deployer) {
  // deploy all logic contracts
  const d1 = await getDeployed(deployer, 'Deployer1', Deployer1);
  console.log(`============= d1 addr: ${d1.address}`);

  const root = await getDeployed(deployer, 'Root', Root, d1.address);
  console.log(`============= root addr: ${root.address}`);

  const d2 = await getDeployed(deployer, 'Deployer2', Deployer2);
  console.log(`============= d2 addr: ${d2.address}`);

  const d3 = await getDeployed(deployer, 'Deployer3', Deployer3);
  console.log(`============= d3 addr: ${d3.address}`);

  const implementation = await getDeployed(deployer, 'Implementation', Implementation);
  console.log(`============= impl addr: ${implementation.address}`);
  
  // check has upgraded to implementation, because sometimes `implement` fails...
  const rootAsD1 = await Deployer1.at(root.address);
  if ((await rootAsD1.implementation()) === d2.address) {
    console.log('============= d1\'s impl already upgraded to d2');
  } else {
    console.log(`============= d2 is not deployed, upgrade d1 to d2..`);
    await rootAsD1.implement(d2.address);
  }

  // check has upgraded to implementation, because sometimes `implement` fails...
  const rootAsD2 = await Deployer2.at(root.address);
  if (!(await rootAsD2.implementation()) === d3.address) {
    console.log('============= d2\'s impl already upgraded to d3');
  } else {
    console.log(`============= d3 is not deployed, upgrade d2 to d3..`);
    await rootAsD2.implement(d3.address);
  }

  // check has upgraded to implementation, because sometimes `implement` fails...
  const rootAsImpl = await Implementation.at(root.address);
  if ((await rootAsImpl.implementation()) === implementation.address) {
    console.log('============= already upgraded to implementation');
  } else {
    const rootAsD3 = await Deployer3.at(root.address);
    await rootAsD3.implement(implementation.address);
    console.log(`============= upgrade to implementation..`);
  }

  // get all contract addresses by extern methods
  const addresses = await getAddresses(root.address);
  console.log('============= address info:', addresses)

  // write addresses to files
  fs.writeFileSync(path.resolve(__dirname, '../scripts', 'addresses.json'), JSON.stringify(addresses), 'utf8');

}


async function newImplementation(deployer) {
  const implementation = await deployer.deploy(Implementation);
}

async function onlyUpgrade(deployer) {
  const implementation = await deployer.deploy(Implementation);
  console.log(Implementation)
  // const rootContract = new web3.eth.Contract(Implementation.abi, (await Root.deployed()).address);
  const rootContract = new web3.eth.Contract(Implementation.abi,'0xAabF00a16a3e90A7f959522fd6451676901e336E');
  const res = await rootContract.methods.upgradeToE(implementation.address).send({
    from: await getCurrentAccount(),
  });
  console.log('======== upgrade done', res, implementation.address);
}



async function onlyUpgrade2(deployer) {
  const implementation = await deployer.deploy(Implementation);
  
  // const rootContract = new web3.eth.Contract(Implementation.abi, (await Root.deployed()).address);
  const rootContract = new web3.eth.Contract(Implementation.abi,'0x90fFDf26571F9dC555DA35f3be1d571925302afd');
  const res = await rootContract.methods.upgradeToE('0x22Eae198CC1a2A6Ad83Ac2c4774E19b3e1b25A14').send({
    from: await getCurrentAccount(),
  });
  console.log('======== upgrade done', res, implementation.address);
}



async function mintUSDC(deployer){
  const usdcABI = require('../build/contracts/TestnetUSDC.json').abi
  const usdcContract = new web3.eth.Contract(usdcABI,'0x28709af9376191653ba671d3c74682ca6f46a4fd');
  const res = await usdcContract.methods.mint('0x5bC7Ae4AA4096e316E983222766e6FE2B727E3dd',1000000000000).send({
    from: await getCurrentAccount(),
  });
  console.log('======== mintUSDC done', res);
}

async function testAdvance(deployer) {

  for (i = 0; i < 100; i++) {
    const impABI = require('../build/contracts/Implementation.json').abi
    const rootContract = new web3.eth.Contract(impABI,'0xAabF00a16a3e90A7f959522fd6451676901e336E');
    const res = await rootContract.methods.advance().send({
      from: await getCurrentAccount(),
    });
    console.log("ok")
  } 

}

async function testEpochPrice(deployer) {

    const impABI = require('../build/contracts/Implementation.json').abi
    const rootContract = new web3.eth.Contract(impABI,'0xAabF00a16a3e90A7f959522fd6451676901e336E');

    const bonds = await rootContract.methods.totalBonds().call();
    console.log("total bonds: ",bonds)
    for (i = 66; i < 70; i++) {
    const epochPrice = await rootContract.methods.epochPrice(i).call();
    const redeemablePrice = await rootContract.methods.getRedeemablePrice(i).call();
    const bondPremium = await rootContract.methods.getBondPremium(i).call();
    console.log('======== epoch: ',i);
    console.log('======== epochPrice:', epochPrice/1e18);
    console.log('======== redeemablePrice: ',redeemablePrice/1e18);
    console.log('======== bondPremium: ',bondPremium/1e18);
    

    }
}

async function BondHistory(){
  const impABI = require('../build/contracts/Implementation.json').abi
  const rootContract = new web3.eth.Contract(impABI,'0xAabF00a16a3e90A7f959522fd6451676901e336E');

  const bonds = await rootContract.methods.totalBonds().call();
  console.log("total bonds: ",bonds/1e18)
  const totalBondRedeemable = await rootContract.methods.totalBondRedeemable().call();
  console.log("totalBondRedeemable: ",bonds/1e18)
  const balanceOfBonds = await rootContract.methods.balanceOfBonds('0xcdde3A8Da22500bE1df12715594d76bdcC2500AD',83).call();
  console.log("balanceOfBonds: ",balanceOfBonds/1e18)

  events = await rootContract.getPastEvents('BondPurchase',{  fromBlock: 0,toBlock: 'latest'});
  events.forEach(element => {
    const epoch = element.returnValues.epoch 
    const account = element.returnValues.account 
    const dollarAmount = element.returnValues.dollarAmount
    const bondAmount = element.returnValues.bondAmount
    const premium = element.returnValues.premium
    console.log(`BondPurchase -- epoch: ${epoch}, account :${account} , dollarAmount:: ${dollarAmount/1e18},bondAmount:: ${bondAmount/1e18}`)   
  })


  events2 = await rootContract.getPastEvents('BondRedemption',{  fromBlock: 0,toBlock: 'latest'});
  
  events2.forEach(element => {
    const epoch = element.returnValues.epoch 
    const account = element.returnValues.account 
    const dollarAmount = element.returnValues.dollarAmount
    const bondAmount = element.returnValues.bondAmount
    const premium = element.returnValues.premium
    console.log(`BondRedemption -- epoch: ${epoch}, account :${account} , dollarAmount:: ${dollarAmount/1e18},bondAmount:: ${bondAmount/1e18}`)   
  })
  

}


module.exports = function(deployer) {
  deployer.then(async() => {
    console.log(deployer.network);
    switch (deployer.network) {
      case 'mainnet':
        await deployTestnet(deployer);
        break;
      case 'development':
        await deployTestnet(deployer);
        break;
      case 'rinkeby':
      case 'ropsten':
        await onlyUpgrade(deployer);
        break;
      default:
        throw("Unsupported network");
    }
  })
};