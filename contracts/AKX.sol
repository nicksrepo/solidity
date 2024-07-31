// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Roles.sol";
import "./Oracles/AKXPriceOracle.sol";
import "./VipNfts/VipNft.sol";
import "./libraries/FloatingPoint.sol";
import "./LABZ.sol";

contract AKX is
    Initializable,
    UUPSUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    FloatingPoint
{
    uint public VERSION;
    string public NAME;
    address public labzToken;
    address public staking;
    address public vipNftManager;
    address public priceOracle;
   

    uint256 public maxLabzPerAccounts;
    uint256 public totalMinted;
    uint256 public tokenPerMatic;
    uint256 public unlockTime;

    bool public saleStarted;
    bool public saleEnded;
    uint256 public saleStartTime;
    uint256 public saleEndTime;

    bool private enableProtocolFee;
    uint256 public protocolFeeInPercent;
    address public feeWallet;

    address payable public multiWallet; // gnosis wallet multisignature to receive funds

    event MultiSignatureWalletSet(address multi);
    event PriceOracleSet(address priceOracle);
    event MaxSupplySet(uint256 maxSupply);
    event VipSaleSupplySet(uint256 vipSaleSupply);
    event VipSaleStarted(
        address indexed token,
        uint256 indexed startTime,
        uint256 indexed endTime,
        uint256 tokenPriceInMATICS,
        uint256 blockNumber
    );
    event VipSaleEnded(uint256 indexed blockTime, uint256 indexed blockNumber);
    event OwnershipChanged(address indexed oldOwner, address indexed newOwner);
    event ProtocolFeesEnabled(address indexed feeWallet, uint256 feePercent);
    event ProtocolFeeMinted(address indexed to, uint256 qty);

    event Buy(address indexed holder, uint256 amount, uint256 blockNum);

    modifier onlySaleStarted() {
        require(saleStartTime < block.timestamp, "sale is not started yet");
        _;
    }

    modifier onlySaleEnded() {
        require(saleEndTime < block.timestamp, "sale is not started yet");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
constructor() {
    _disableInitializers();
}

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyRole(ADMIN_ROLE)
    {}

    function upgradeTo(address newImplementation)   external override onlyProxy onlyRole(ADMIN_ROLE) {
        super._upgradeTo(newImplementation);
    }

    function initialize(
        address _priceOracle,
        address _labzToken,
        address vipNftManagerContract,
        address multi
    ) external initializer onlyProxy {
        __AKX_init(_priceOracle, _labzToken, vipNftManagerContract, multi);
    }

    function __AKX_init(
        address _priceOracle,
        address _labzToken,
        address vipNftManagerContract,
        address multi
    ) internal initializer onlyInitializing {
        VERSION = 1;
        NAME = "AKX CORE";
        __Context_init();
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        labzToken = _labzToken;
        vipNftManager = vipNftManagerContract;
        setPriceOracle(_priceOracle);
        setMultiSignatureWallet(multi);
        totalMinted = 0;
        startSale(block.timestamp + 30 days);
        saleEndTime = block.timestamp + 60 days;

        
    }

    function useLABZ() internal view returns (LABZ) {
        return LABZ(payable(labzToken));
    }

    function usePriceOracle() internal view returns (AKXPriceOracle) {
        return AKXPriceOracle(priceOracle);
    }

    function updateLabzTokenAddress(address _token)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(_token != address(0), "no zero address");
        labzToken = _token;
    }

    function updateStakingContractAddress(address _staking)
        external
        onlyRole(ADMIN_ROLE)
    {
        staking = _staking;
    }

    

    function incrementVersion() external onlyRole(ADMIN_ROLE) {
        VERSION += 1;
    }

    function buy() external payable nonReentrant returns(uint256) {
        LABZ labz = useLABZ();
        require(msg.value > 0 && msg.sender != address(0), "invalid params");
        uint256 qty = tokenPerMatic * msg.value;

        if (checkIfHasToken(msg.sender) != true) {
            VipNfts(vipNftManager).safeMint(msg.sender, qty, msg.sender);
        }
        uint256 numMinted = labz.buyPrivate(msg.sender, qty);

        if (enableProtocolFee) {
            uint256 _fee = _calcProtocolFee(numMinted / 1e18);
            uint256 result = LABZ(labzToken).mintProtocolFee(feeWallet, _fee);
            emit ProtocolFeeMinted(feeWallet, result);
        }

        require(numMinted > 0, "error buying labz");

        (bool success, bytes memory data) = multiWallet.call{value: msg.value}(
            ""
        );
        require(success, "error transfering matics to gnosis");
        emit Buy(msg.sender, numMinted, block.number);
        return qty;
    }

    function checkIfHasToken(address _sender) internal view returns (bool) {
        return VipNfts(vipNftManager)._hasVipToken(_sender) == true;
    }

    function TokenUSDRate() external  view returns (uint256 r) {
        r = usePriceOracle().AkxUSD() / 1e18;
    }

    function TokenTotalValue() external view returns (uint256 r) {
        r = totalMinted * this.TokenUSDRate();
    }

    function enableProtocolFees(uint256 percentFees, address _feeWallet)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(_feeWallet != address(0), "no zero address");
        enableProtocolFee = true;
        protocolFeeInPercent = percentFees;
        feeWallet = _feeWallet;
        emit ProtocolFeesEnabled(feeWallet, protocolFeeInPercent);
    }

    function startSale(uint256 unlockTime_) internal {
        unlockTime = unlockTime_;
        tokenPerMatic = 18;
        uint256 _tp = tokenPerMatic;
        uint256 currentTime = block.timestamp;
        uint256 currentBlock = block.number;
        uint256 __ut = unlockTime;
        saleStarted = true;
        saleEnded = false;
        saleStartTime = currentTime;

        emit VipSaleStarted(
            address(this),
            currentTime,
            __ut,
            _tp,
            currentBlock
        );
    }

    function TokenMaticRate() public pure returns (uint256 r) {
        r = 18;
    }

    function _calcProtocolFee(uint256 value) internal view returns (uint256 r) {
        uint256 _val = value * 10**18;
        uint256 percent = protocolFeeInPercent * 10**18;

        r = calculateRate(_val, percent) * 1e18;
    }

    function setMultiSignatureWallet(address multi) internal {
        address _m = multi;
        multiWallet = payable(_m);
    }

    function setPriceOracle(address _priceOracle) internal {
        priceOracle = _priceOracle;
    }

    receive() external payable {}
}
