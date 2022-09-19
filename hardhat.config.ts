import "@nomicfoundation/hardhat-toolbox"
import { config as dotenvConfig } from "dotenv"
import "hardhat-docgen"
import { HardhatUserConfig } from "hardhat/config"
import { resolve } from "path"

dotenvConfig({ path: resolve(__dirname, "./.env") })

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: <string>process.env.ETH_MAINNET_ALCHEMY_URL,
      },
    },
    goerli: {
      url: <string>process.env.ETH_GOERLI_ALCHEMY_URL,
    },
  },
  // etherscan: {
  //   apiKey: <string>process.env.ETHERSCAN_API_KEY,
  // },
  docgen: {
    path: "./docs",
    clear: true,
    runOnCompile: true,
  },
  mocha: {
    timeout: 40000,
  },
}

export default config
