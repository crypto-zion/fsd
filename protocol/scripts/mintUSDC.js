const Web3 = require('web3');
const web3 = new Web3();
const PrivateKeyProvider = require('truffle-privatekey-provider');

// set up provider
const privateKey = process.env.ESD_PRIVATE_KEY;
const infuraId = process.env.ESD_INFURA_ID;
web3.setProvider(new PrivateKeyProvider(privateKey, 'https://rinkeby.infura.io/v3/' + infuraId));

const toAddress = process.env.to;
const USDC = require('../build/contracts/TestnetUSDC.json');

const usdcContract = new web3.eth.Contract(USDC.abi, '0x28709Af9376191653bA671d3C74682cA6F46a4Fd');


async function getCurrentAccount() {
  return new Promise((resolve, reject) => {
    web3.eth.getAccounts((error, result) => {
      !error ? resolve(result[0]) : reject(error);
    });
  })
}

async function mint() {
  const currentAccount = await getCurrentAccount();

  // 10000 usdc
  console.log('minting usdc...', currentAccount)
  res = await usdcContract.methods.mint(currentAccount, '100000000000').send({
    from: currentAccount
  })
  console.log('mint usdc done', res);
}


mint();