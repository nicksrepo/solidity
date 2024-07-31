// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract InterestFormula {

    uint256 private constant mantissa = 1e18;
    uint256 private principal;
    uint256 private constant ratePerYear = 1_8_2_5; // 18.25%
    uint256 private ratePerBlock;
    uint256 private constant blocksPerYear = 2102400;
    uint256 private mulPerBlock;
    

    function setPrincipal(uint _principal) internal  {
        principal = _principal;
    }

    function calculateRatePerBlock() internal {
        ratePerBlock = ratePerYear / blocksPerYear;
        mulPerBlock = 1_0_0 / blocksPerYear;
    }

    function calculateCompoundRate(uint256 principal_, uint256 fromBlock) internal returns(uint256) {
        setPrincipal(principal_);
        calculateRatePerBlock();
        uint256 A = principal * (1 + ratePerBlock) ** ((block.number - fromBlock)*mulPerBlock) / mantissa;
        return A;
    }

}