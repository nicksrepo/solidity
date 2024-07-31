// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFee {
    function getFeeInfo(address _proxy, uint256 _type) external view returns (address recipient, uint256 bps);
}