import { BigNumber, utils } from "ethers";

export const getSecondsFromDays = (count: number): number => count * 86400;

export const getDaysFromSeconds = (count: number): number =>
  Math.round(count / 86400);

export const equalWithEpsilon = (
  a: BigNumber,
  b: BigNumber,
  eps: BigNumber
): boolean => a.sub(b).abs().lte(eps);

export module adbk {
  export const fromNum = (v: number) => utils.parseUnits(v.toString())
    .mul(BigNumber.from(2).pow(64))
    .div(BigNumber.from(10).pow(18));
  export const fromNums = (a: number[]) => a.map(item => fromNum(item));
  export const One = fromNum(1);
}