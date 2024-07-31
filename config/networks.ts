import { NetworksUserConfig } from "hardhat/types";

if(process.env.NODE_ENV !== 'production') {
require('custom-env').env('development');
} else {
    require('custom-env').env('production');
}

export const Networks:NetworksUserConfig = {
    hardhat: {
        forking: {
            url: `${process.env.MUMBAI_URL}`
        }
    },
   
  mumbai: {
        url: `${process.env.MUMBAI_URL}`,
        accounts: [`${process.env.PRIVATE_KEY}`],
        gas: 30000,
        allowUnlimitedContractSize: true,
       
    },
    goerli: {
        url: `${process.env.GOERLI_URL}`,
        accounts: [`${process.env.PRIVATE_KEY}`],
        gas: 2100000,
        gasPrice: 8000000000,
       
    }
}

