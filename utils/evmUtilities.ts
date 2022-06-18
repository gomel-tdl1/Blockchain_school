import { BigNumber } from "ethers";
import { network } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getSecondsFromDays } from "./mathUtilities";

export namespace evmSnapshot {
  let snapshotNumber: number | undefined;

  export const snapshot = async () => {
    snapshotNumber = await getSnapshot();
  };

  export const getSnapshot = async () => {
    return await network.provider.send("evm_snapshot", []);
  };

  export const revert = async () => {
    if (snapshotNumber) {
      const result = await network.provider.send("evm_revert", [
        snapshotNumber,
      ]);
      if (!result) {
        throw Error("Revert snapshot fail");
      }
      snapshotNumber = undefined;
    }
  };

  export const revertToSnapshot = async (number: number) => {
    console.log('Snapshot number: ', number);

    const result = await network.provider.send("evm_revert", [
      number,
    ]);
    
    if (!result) {
      throw Error("Revert snapshot fail");
    }
  };
}

export namespace evmHardhatReset {
  export const hardhatReset = async (
    hre: HardhatRuntimeEnvironment,
    block: number
  ): Promise<void> => {
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            blockNumber: block,
            jsonRpcUrl: hre.config.networks.hardhat.forking?.url,
          },
        },
      ],
    });
  };
}

export namespace evmBlockTimestamp {
  const getLastBlock = async () => {
    const blockNumber = await network.provider.send("eth_blockNumber", []);
    const block = await network.provider.send("eth_getBlockByNumber", [
      blockNumber,
      false,
    ]);

    return block;
  }

  export const nextBlockTimestamp = async (timeStamp: number, mine = false) => {
    let block = await getLastBlock();
    if (!block || parseInt(block.timestamp, 16) < timeStamp) {
      await network.provider.send("evm_setNextBlockTimestamp", [timeStamp]);
      if (mine) await network.provider.send("evm_mine");
    } else {
      console.warn(
        `Current block.timestamp > timeStamp; ${parseInt(
          block.timestamp,
          16
        )} > ${timeStamp}`
      );
    }
    block = await getLastBlock();
    return parseInt(block.timestamp, 16);
  };

  export const increaseTime = async (secondsToIncrease: number) => {
    await network.provider.send("evm_increaseTime", [secondsToIncrease]);
    await network.provider.send("evm_mine", []);

    console.log("Delay: ", secondsToIncrease / getSecondsFromDays(1), " days");
    const block = await getLastBlock();
    return parseInt(block.timestamp, 16);
  };
}

export namespace hardhatSetBalance {
  export const setBalance = async (address: string, hexBalance: string) => {
    await network.provider.send("hardhat_setBalance", [address, hexBalance]);
  };
}

export namespace addresses {
  export const generateAddresses = (count: number, skipFirst = 0) => {
    if (skipFirst < 0) throw new Error("skipFirst should be >= 0");
    return Array.from(Array(count).keys())
      .map((v) => v + 1 + skipFirst)
      .map(numberToAddress);
  };

  export const numberToAddress = (num: number): string =>
    "0x" +
    BigNumber.from(num.toString()).toHexString().substring(2).padStart(40, "0");
}


export namespace hardhatImpersonate {
  export const impersonateAccounts = async (account: string, setCodeZero = true) => {
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account],
    });

    if (!setCodeZero) return;

    await network.provider.request({
      method: "hardhat_setCode",
      params: [account, "0x"],
    });
  }

  export const stopImpersonate = async (...accounts: string[]) =>
    Promise.all(
      accounts.map((account) =>
        network.provider.request({
          method: "hardhat_stopImpersonatingAccount",
          params: [account],
        })
      )
    );
}
