// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract FloatingPoint {

    using Strings for uint256;

    struct Float {
        uint256 decimalPlaces;
        uint256 quotient;
        uint256 remainder;
        string resultStr;
    }

    function divide(uint256 decimalPlaces, uint256 numerator, uint256 denominator) public pure  returns(Float memory) {
        uint256 factor = 10 ** decimalPlaces;
        uint256 quotient = numerator / denominator;
        bool rounding = 2 * ((numerator * factor) % denominator) >= denominator;
        uint256 remainder = (numerator * factor / denominator) % factor;
        if(rounding) {
            remainder += 1;
        }
        string memory result = string(abi.encodePacked(quotient.toString(), '.', numToFixedLengthString(decimalPlaces, remainder)));
        Float memory r = Float(decimalPlaces, quotient, remainder, result);
        return r;
    }

    function numToFixedLengthString(uint256 decimalPlaces, uint256 num) pure internal returns(string memory result) {
        bytes memory byteString;
        for (uint256 i = 0; i < decimalPlaces; i++) {
            uint256 remainder = num % 10;
            byteString = abi.encodePacked(remainder.toString(), byteString);
            num = num/10;
        }
        result = string(byteString);
    }

      function calculateRate(uint256 _price1, uint256 _price2) public pure returns(uint256 result) {
        if(_price1 > _price2) {
            FloatingPoint.Float memory _floating = divide(18, _price1, _price2);
            result = _floating.remainder;
        } else if(_price2 > _price1){
            FloatingPoint.Float memory  _floating = divide(18, _price2, _price1);
            result = _floating.remainder;
        }
        
    }

    function calculateExactTokensForMatics(uint256 tokenPrice, uint256 maticPrice, uint256 valueSentInMatics) external pure returns(uint256 result) {
        result = calculateRate(tokenPrice, maticPrice) * valueSentInMatics;
    }

    function calculateTokenUSDPrice(uint256 tokensForOneMatic, uint256 maticUSDPrice) public pure returns(uint256) {
       uint256 _amount = (tokensForOneMatic / maticUSDPrice) / 1e18;
        return _amount;
    }

    function calculateMaticQtyToUSDPrice(uint256 qty, uint256 maticUSDPrice) public pure returns(uint256) {
    uint _amount = (maticUSDPrice * qty) / 1e18;
        return _amount;
    }

}