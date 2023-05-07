require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

module.exports = {
  solidity: "0.8.19",
  networks: {
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/aUBF_4iZcTC6vp7vBdNa5f083XEqLhLt",
      accounts: [process.env.MUMBAI_PRIVATE_KEY],
    },
  },
};
