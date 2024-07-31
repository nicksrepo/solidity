// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "apeone/node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract CrazyApeCollection is ERC1155 {
    uint256 public constant CrazyApe = 1;
    uint256 public constant PresaleNFT = 2;
    uint256 public constant Legendary = 3;

    constructor() ERC1155("https://bafybeig63wxg75nhr4t2qwsnfva4x3gmlgpdacxf6tvypqeh7vdptxj6xa.ipfs.akx.info/metadata/") {

        _mint(msg.sender, CrazyApe, 1, "");
        _mint(msg.sender, PresaleNFT, 1, "");
        _mint(msg.sender, Legendary, 1, "");


    }

      function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://bafybeig63wxg75nhr4t2qwsnfva4x3gmlgpdacxf6tvypqeh7vdptxj6xa.ipfs.akx.info/metadata/",
                Strings.toString(_tokenid),".json"
            )
        );
    }

}
