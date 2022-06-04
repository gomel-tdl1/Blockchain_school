import hre, { ethers, network, upgrades, networkAddress } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";


describe('simple ERC20', () => {
    const totalSupply = ethers.utils.parseUnits('600000', 18)
    
    let provider: any;
    let accounts: SignerWithAddress[];

    before(async () => {
        provider = ethers.provider;
        
      });
})