const HDWalletProvider = require('@truffle/hdwallet-provider');
// create a file at the root of your project and name it .env -- there you can set process variables
// like the mnemomic and Infura project key below. Note: .env is ignored by git to keep your private information safe
require('dotenv').config();
const mnemonic_test = process.env["MNEMONIC_TESTNET"];
const mnemonic_main = process.env["MNEMONIC_MAINNET"];
// const private_key = process.env["PRIVATE_KEY"];
const infuraProjectId = process.env["INFURA_PROJECT_ID"];

module.exports = {

  /**
  * contracts_build_directory tells Truffle where to store compiled contracts
  */
  contracts_build_directory: './build/contracts',

  /**
  * contracts_directory tells Truffle where the contracts you want to compile are located
  */
  contracts_directory: './contracts',


  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
      gas: 5000000,
    },
    polygon_infura_mainnet: {
      provider: () => new HDWalletProvider({
        mnemonic: {
          phrase: mnemonic_main
        },
        providerOrUrl:
          "https://polygon-mainnet.infura.io/v3/" + infuraProjectId,
          addressIndex: 0
      }),
      network_id: 137,
      gas: 20000000,
      gasPrice: 50000000000,
      confirmations: 2,
    },
    //polygon Infura testnet
    polygon_infura_testnet: {
      provider: () => new HDWalletProvider({
        mnemonic: {
          phrase: mnemonic_test
        },
        providerOrUrl:
         "https://polygon-mumbai.infura.io/v3/" + infuraProjectId
      }),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      chainId: 80001,
    },
    ropsten:  {
     network_id: 3,
     host: "localhost",
     port:  8545
    },
    binance_testnet: {
      provider: () => new HDWalletProvider(mnemonic_test, 'https://data-seed-prebsc-1-s1.binance.org:8545/'),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    binance_mainnet: {
      provider: () => new HDWalletProvider(mnemonic_main, 'https://bsc-dataseed1.binance.org'),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: '0.8.12',
      settings: {
        evmVersion: 'byzantium' // Default: "petersburg"
      },
      optimizer: {
        enabled: true,
        runs: 999999
      }
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    polygonscan: 'PN22E6BRMAWTY7YDRJZYMJP1KD2P1BP98Z'
  }
}
