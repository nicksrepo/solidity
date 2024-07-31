// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract LABZ is
    ERC20("AKX LABZ", "LABZ"),
    ERC20Permit("AKX LABZ"),
    ReentrancyGuard,
    AccessControlEnumerable
{
    uint256 public maxSupply;

    using Address for address;

    bytes32 private __state;

    bytes32 public constant SALE_STARTED = keccak256("SALE_STARTED");
    bytes32 public constant SALE_COMPLETED = keccak256("SALE_COMPLETED");
    bytes32 public constant PENDING_STATE = keccak256("PENDING_STATE");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes4 public constant MINT_PROTOCOL_FEE_SIG = bytes4(0x67dfa5b0);
    bytes4 public constant BUY_PRIVATE_SIG = bytes4(0xccea1aef);

    mapping(bytes32 => bool) private _activestate;
    address public _minter;

    event SaleStartedLog(address indexed minter, bytes32 state, bool started);
    event SaleCompletedLog(address indexed minter, bytes32 state, bool stopped);
    event StatePendingLog(address indexed minter, bytes32 state, bool pending);
    event NewPrivateSale(address indexed from, address indexed to, uint256 amount, uint256 ts);
    event ProtocolFeeMinted(address indexed to, uint256 amount, uint256 ts);


    constructor(
        address minter
    ) {
     
    require(minter != address(0), "no zero address");
      _minter = minter;
       _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
       grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, minter);
         grantRole(MINTER_ROLE, msg.sender);
         maxSupply = 300000000000 * 10 ** 18;
         setState(SALE_STARTED);
    }

    function setState(bytes32 _state) public onlyRole(MINTER_ROLE) {
        __state = _state;
        _activestate[_state] = true;
        if(_state == SALE_STARTED) {
            emit SaleStartedLog(_minter, SALE_STARTED, true);
        } else if(_state == SALE_COMPLETED) {
            emit SaleCompletedLog(_minter, SALE_COMPLETED, true);
        } else {
            emit StatePendingLog(_minter, PENDING_STATE, true);
        }
    }

  
    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20)
    {
        
        super._mint(account, amount);
       
    }

    function mintProtocolFee(address to, uint256 amount) external onlyRole(MINTER_ROLE) returns(uint256) {
        super._mint(to, amount);
        emit ProtocolFeeMinted(to, amount, block.timestamp);
        return amount;
    }


    function _burn(address account, uint256 amount)
        internal
        virtual
        override(ERC20)
    {
        super._burn(account, amount);
    }

    function buyPrivate(address _sender, uint256 amount)
        public
        nonReentrant
        onlyRole(MINTER_ROLE)
        onlyStateActive(SALE_STARTED)
        returns (uint256)
    {
        uint256 tokenAmount = amount;
        _mint(_sender, tokenAmount);
        emit NewPrivateSale(address(this), _sender, tokenAmount, block.timestamp);
        return tokenAmount;
    }

    function mint(address _to, uint256 amount) public onlyRole(MINTER_ROLE){
        _mint(_to, amount);
    }

    function transferOwner(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    function setNewMinter(address newMinter) public onlyRole(MINTER_ROLE) {
        grantRole(MINTER_ROLE, newMinter);
    }

    function _transfer(address from, address to, uint256 amount) internal override onlyStateActive(SALE_STARTED) {
        require(from == address(this) || __state == SALE_COMPLETED || from == address(0), "cannot transfer");
        super._transfer(from, to, amount);
    }

    modifier onlyStateActive(bytes32 state) {
        require(__state == state && _activestate[__state] == true, "invalid state");
        _;
    }

}
