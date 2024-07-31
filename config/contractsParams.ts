import { ethers } from "ethers";

export const LabzParams = {
    maxSupply: ethers.utils.parseEther("300000000000"),
    vipSupply: ethers.utils.parseEther("75000000"),
    akxCoreSafe: '0x5dA5aE3f9E4ee7682A2b0a233E4553A21b4f0044',
}

const now = new Date();
const saleEnd = Math.round(now.getTime()/1000) + (86400 * 30);

export const VipSaleParams = {
    unlockTime: saleEnd,
    minLockTime: 86400 *30,
}

export const  VipNftsParams = {
    minterRole: '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6',
}