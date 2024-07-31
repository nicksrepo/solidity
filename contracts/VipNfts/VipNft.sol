// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../LABZ.sol";

contract VipNfts is ERC721, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    event VIPNftMinted(address indexed holder, uint256 indexed tokenId, address indexed walletAddress);

     using Counters for Counters.Counter;
      Counters.Counter private _index;

     string private _baseTokenURI;

  
    bool public isVip = true;
    string public QRCodeBaseURI;

    struct VipNFT {
        uint256 id;
        address owner;
        uint256 labzQty;
        address vipWallet;
        bytes32 qrHash;
    }

    mapping(address => uint256) public _ownersToTokenIds;
    mapping(address => bool) public _hasVipToken;
    mapping(uint256 => uint256) private _nftCarryValue;
    mapping(uint256 => bytes32) private _qrHashes;
    mapping(uint256 => address) public _vipWallets;
    mapping(address => VipNFT) private _nftDataFromOwner;


    LABZ internal labzToken; // to verify balance



    constructor(address _labz) ERC721("AKX Vip NFT", "AKXVIP") {
        labzToken = LABZ(payable(_labz));
        _baseTokenURI = "https://akx3.com/vip/token/id/";
        QRCodeBaseURI = "https://akx3.com/priv/qrcodes/id/";
           _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(MINTER_ROLE, msg.sender);
        grantRole(MINTER_ROLE, _labz);
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _qrBaseURI() internal view returns(string memory) {
        return QRCodeBaseURI;
    }

    function safeMint(address to, uint256 labzQty, address vipWallet) public {
        require(_hasVipToken[to] != true, "you can only have one vip nft per address");
      //  require(labzToken.balanceOf(vipWallet) > 0, "you need to have vip labz to get a nft");
        uint256 id = _index.current();
        _mint(to, id);
        _setStruct(id, to, labzQty, vipWallet);
    }

    function _setStruct(uint256 id, address _owner, uint256 value, address vipWallet) internal {
        bytes32 _hash = keccak256(abi.encodePacked(id, _owner, vipWallet));
       VipNFT memory v = VipNFT(id, _owner, value, vipWallet, _hash);
       _nftDataFromOwner[_owner] = v;
       _vipWallets[id] = vipWallet;
       _qrHashes[id] = _hash;
       _nftCarryValue[id] = value;
       _hasVipToken[_owner] = true;
       _ownersToTokenIds[_owner] = id;
       _index.increment();

    }

    function MyNFTID(address myaddress) public view returns(uint256) {
        require(_hasVipToken[myaddress], "you do not have a token yet");
        return _ownersToTokenIds[myaddress];
    }

    function MyVIPWallet(address myaddress) public view returns(address) {
          require(_hasVipToken[myaddress], "you do not have a token yet");
        uint256 tokenId = _ownersToTokenIds[myaddress];
        return _vipWallets[tokenId];
    }

    function MyLABZBalance(address myaddress) public view returns(uint256) {
          require(_hasVipToken[myaddress], "you do not have a token yet");
        uint256 tokenId = _ownersToTokenIds[myaddress];
        return _nftCarryValue[tokenId];
    }


   
    function GetMyVIPWalletAddress(uint256 tokenId) public view returns(address) {
      
        return _vipWallets[tokenId];
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}