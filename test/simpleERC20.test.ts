import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import {
  SimpleERC20,
  SimpleERC20__factory
} from "../typechain-types";
import { BigNumber } from "@ethersproject/bignumber";
import { evmBlockTimestamp, evmSnapshot } from "../utils/evmUtilities";

import increaseTime = evmBlockTimestamp.increaseTime;
import { getSecondsFromDays } from "../utils/mathUtilities";


const fmt = (amount: BigNumber) => {
  return ethers.utils.formatUnits(amount);
};

describe("Simple ERC20", () => {
  let provider: any;
  let accounts: SignerWithAddress[];

  let simple: SimpleERC20;
    const timeToVote = getSecondsFromDays(3);
    const initialSupply = ethers.utils.parseUnits('10000', 18);
    const startPrice = ethers.utils.parseUnits('0.01', 18);

  before(async () => {

    provider = ethers.provider;
    accounts = await ethers.getSigners();

    simple = await new SimpleERC20__factory(accounts[0]).deploy(
      timeToVote,
      startPrice,
      initialSupply,
      'Arina',
      'AR',
    );
  });

  it('buy token', async () => {
    console.log('balance before buy: ', await simple.balanceOf(accounts[0].address))
    
    await (await simple.buy({value: ethers.utils.parseUnits('1')})).wait()

    const afterBuyBalance = await simple.balanceOf(accounts[0].address)
    console.log('balance after buy: ', afterBuyBalance)
    expect(afterBuyBalance.eq(afterBuyBalance.mul(ethers.utils.parseUnits('1')).div(startPrice)))
  })

  it('sell token', async () => {
    console.log('balance before buy: ', await simple.balanceOf(accounts[1].address))
    
    await simple.connect(accounts[1]).buy({value: ethers.utils.parseUnits('1')})

    const afterBuyBalance = await simple.balanceOf(accounts[1].address)
    console.log('balance after buy: ', afterBuyBalance)
    expect(afterBuyBalance.eq(afterBuyBalance.mul(ethers.utils.parseUnits('1')).div(startPrice)))

    const amountForSell = ethers.utils.parseUnits('50')
    
    await simple.connect(accounts[1]).approve(simple.address, amountForSell)
    await simple.connect(accounts[1]).sell(amountForSell)

    const balanceAfterSell = await simple.balanceOf(accounts[1].address)
    console.log("Balance after sell:", balanceAfterSell);
    
    expect(balanceAfterSell.eq(afterBuyBalance.div(amountForSell)))
  })
  
});
