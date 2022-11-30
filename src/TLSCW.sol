// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./EIP712MetaTransaction.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
*   Timelock Smart contract core implementation. 
*   Not upgradeable for the quicker prototyping purposes.
*   Instances are created using Clones library by OZ.
*   Ownership is allowed by simple Ownable pattern by OZ.
*   In production this approach can be shifted towards more flexibility via:
*       1) Introducing upgradeability via Beacon Proxies Pattern
*       2) Introducing ownership through Dharma's userSigningKey-like approach
*
*   Functionality:
*   
**/

contract TimelockSCW is EIP712MetaTransaction {

    event DepositCreated(address indexed tokenAddress, uint256 indexed amount, uint256 indexed unlock_timestamp);

    using SafeERC20 for IERC20;

    //  deposit_id => deposit_details

    // struct : token, amount, unlock_timestamp, claimed
     struct Deposit {
        address tokenAddress; // 0x00...00 means Native token
        uint256 amount;
        uint256 unlock_timestamp;
        bool claimed;
    }

    mapping (uint256 => Deposit) public Deposits;
    uint256 public lastDepositId;

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory version, address newOwner) initializer public {
        __EIP712MetaTx_init(name, version);
        _transferOwnership(newOwner);
    }

    function depositERC20(address tokenAddress, uint256 amount, uint256 unlock_timestamp) public {
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msgSender(), address(this), amount);
        Deposit memory dep = Deposit({
            tokenAddress: tokenAddress,
            amount: amount,
            unlock_timestamp: unlock_timestamp,
            claimed: false
        });
        Deposits[++lastDepositId] = dep;
        emit DepositCreated(tokenAddress, amount, unlock_timestamp);
    }

    function depositNative(uint256 unlock_timestamp) public payable {
        uint256 nativeTokenReceived = msg.value;
        require (nativeTokenReceived > 0, "TLSCW: Can not deposit 0 Native tokens");
        Deposit memory dep = Deposit({
            tokenAddress: address(0),
            amount: nativeTokenReceived,
            unlock_timestamp: unlock_timestamp,
            claimed: false
        });
        Deposits[++lastDepositId] = dep;
        emit DepositCreated(address(0), nativeTokenReceived, unlock_timestamp);
    }

    // CLAIMS

    // Receiver that blocks the direct reception of native token

    // **************
    //  Ownable section
    // **************

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


    /** 
    *           Implementation notes and future work
    *
    *   1) Batch claims
    *   2) Rescue mechanism for ERC20 tokens that user accidentally sends directly to this wallet
    * 
    *
    **/



}