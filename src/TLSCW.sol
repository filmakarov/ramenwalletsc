// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./EIP712MetaTransaction.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
*   Timelock Smart contract core implementation. 
*   Not upgradeable for the quick prototyping purposes.
*   Instances (individual wallets) are created using Clones library by OZ.
*   Ownership is allowed by simple Ownable pattern inspired by OZ.
*   In production this approach can be shifted towards more flexibility via:
*       1) Introducing upgradeability via Beacon Proxies Pattern
*       2) Introducing ownership through Dharma's userSigningKey-like approach
*   
*   Alternative approach is to make everything served by one contract, 
*   just storing the receiver for every deposit. However, keeping everyone's 
*   funds in the one centrally governed contract is always less secure, 
*   than having individually ownable personal wallets.   
*
*   Functionality: 
*   - Anyone can deposit ERC20 or Native tokens. 
*   - Unlocking timestamp is set at the deposit. 
*   - Owner can claim any deposit, that is unlocked.
*   - Meta transactions enabled. So anyone can initiate claimDeposit as long as caller has owner's signature.
*   
**/

contract TimelockSCW is EIP712MetaTransaction {

    event DepositCreated(uint256 indexed depositId, address indexed tokenAddress, uint256 amount, uint256 unlock_timestamp);
    event DepositClaimed(uint256 indexed depositId, address indexed tokenAddress, uint256 amount);
    event NewWallet(address instance, uint256 lastWalletId);

    using SafeERC20 for IERC20;
    using Address for address;
    using Clones for address;

    address private immutable __self = address(this);

    // struct : token, amount, unlock_timestamp, claimed
    struct Deposit {
        address tokenAddress; // 0x00...00 means Native token
        uint256 amount;
        uint256 unlock_timestamp;
        bool claimed;
    }

    mapping (uint256 => Deposit) public deposits;
    uint256 public lastDepositId;

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    uint256 public lastWalletId;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through clones. Because cloning the clone will create a broken clone
     * that delegatecalls to self until out of gas.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Check that the execution is being performed through a delegatecall call 
     *      Used to prevent deposits to Factory
     */
    modifier onlyClone() {
        require(address(this) != __self, "Function must be called through delegatecall");
        _;
    }

    /**
     * @dev Initializes the contract. Sets ownership and sets the required values for EIP712
     *      Should be called at the cloning to initialize the clone.
     */
    function initialize(string memory name, string memory version, address newOwner) initializer public {
        __EIP712MetaTx_init(name, version);
        _transferOwnership(newOwner);
    }

    /**
     * @dev Allows anyone to deposit ERC20 tokens to this smart contract wallet
     *      Emits DepositCreated event if successful.
     */
    function depositERC20(address tokenAddress, uint256 amount, uint256 unlock_timestamp) onlyClone public {
        IERC20(tokenAddress).safeTransferFrom(msgSender(), address(this), amount);
        Deposit memory dep = Deposit({
            tokenAddress: tokenAddress,
            amount: amount,
            unlock_timestamp: unlock_timestamp,
            claimed: false
        });
        deposits[++lastDepositId] = dep;
        emit DepositCreated(lastDepositId, tokenAddress, amount, unlock_timestamp);
    }

    /**
     * @dev Allows anyone to deposit Native tokens to this smart contract wallet.
     *      Emits DepositCreated event if successful.
     */
    function depositNative(uint256 unlock_timestamp) public onlyClone payable {
        uint256 nativeTokenReceived = msg.value;
        require (nativeTokenReceived > 0, "TLSCW: Can not deposit 0 Native tokens");
        Deposit memory dep = Deposit({
            tokenAddress: address(0),
            amount: nativeTokenReceived,
            unlock_timestamp: unlock_timestamp,
            claimed: false
        });
        deposits[++lastDepositId] = dep;
        emit DepositCreated(lastDepositId, address(0), nativeTokenReceived, unlock_timestamp);
    }

    /**
     * @dev Allows owner to claim the deposit by depositId. 
     *      Emits DepositClaimed event if successful.
     */
    function claimDeposit(uint256 depositId) public onlyOwner {
        Deposit memory dep = deposits[depositId];
        require(!dep.claimed, "TLSCW: Deposit already claimed");
        require(dep.unlock_timestamp <= block.timestamp, "TLSCW: Deposit not available yet");
        dep.claimed = true;
        deposits[depositId] = dep;
        if (dep.tokenAddress == address(0)) {
            // Native token claim flow
            (bool success, ) = _owner.call{value: dep.amount}("");
            if (!success) revert ("Native token claim failed");
        } else {
            // ERC20 token claim flow
            IERC20(dep.tokenAddress).safeTransfer(_owner, dep.amount);
        }
        emit DepositClaimed(depositId, dep.tokenAddress, dep.amount);
    }

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

    // **************
    //  Cloning
    // **************

    function clone(bytes calldata initdata) public payable notDelegated {
        lastWalletId++;
        _initAndEmit(address(this).clone(), initdata);
    }

    function cloneDeterministic(
        bytes32 salt,
        bytes calldata initdata
    ) public payable notDelegated {
        _initAndEmit(address(this).cloneDeterministic(salt), initdata);
        lastWalletId++;
    }

    function predictDeterministicAddress(bytes32 salt) public view returns (address predicted) {
        return address(this).predictDeterministicAddress(salt);
    }

    function _initAndEmit(address instance, bytes memory initdata) private {
        if (initdata.length > 0) {
            instance.functionCallWithValue(initdata, msg.value);
        }
        emit NewWallet(instance, lastWalletId);
    }

    /** 
    *           Implementation notes and future work
    *
    *   - Batch claims
    *   - Partial claims (claimAmount <= deposit.amount)  
    *   - Rescue mechanism for ERC20 tokens that user accidentally sends directly to this wallet
    *   - Setup backend to subscribe to events and keep track of deposits made/claimed
    *      in order to avoid looping thru the deposit mapping
    *
    **/

}