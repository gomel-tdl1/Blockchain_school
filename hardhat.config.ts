import { HardhatUserConfig } from 'hardhat/config';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import "hardhat-gas-reporter";

const gwei = 10 ** 9;

const config: HardhatUserConfig = {
  networks: {
    goerli: {
      chainId: 5,
      url: "https://eth-goerli.alchemyapi.io/v2/zLqeyoMwEDVFUNy9tR1DhixsMuiiVghk",
      initialBaseFeePerGas: 0,
      gasPrice: 10 * gwei,
      blockGasLimit: 300 * 10 ** 6,
    }
  },
  solidity: {
    compilers: [
      {
        version: '0.8.6',
      },
    ]
  },
  gasReporter: {
    enabled: true
  },
};

export default config;
