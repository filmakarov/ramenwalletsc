// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@std/Test.sol";
import "../src/TLSCW.sol";
import "../src/Mocks/ERC20Mock.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TLSCWTest is Test {

    using Strings for uint256;

    struct Deposit {
        address tokenAddress; // 0x00...00 means Native token
        uint256 amount;
        uint256 unlock_timestamp;
        bool claimed;
    }

    TimelockSCW public walletFactory;
    TimelockSCW public wallet1;

    address public wal1owner = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;

    ERC20Mock public ERC20Token;

    function setUp() public {

        // deploy Factory
        walletFactory = new TimelockSCW();

        //deplpy token
        ERC20Token = new ERC20Mock("MockToken", "MCT", address(1002), 1000*10**18);

        // make first clone
        bytes memory initdata = abi.encodeWithSignature(
                            "initialize(string,string,address)", //function signature
                            string(abi.encodePacked("Timelock Wallet ", (walletFactory.lastWalletId()+1).toString())), //name
                            "1", // version
                            wal1owner); // owner

        bytes32 salt = bytes32(abi.encodePacked(
                                    "Timelock Wallet", 
                                    (walletFactory.lastWalletId()+1).toString(), 
                                    block.timestamp.toString()));

        address wallet1Address = walletFactory.predictDeterministicAddress(salt);
        walletFactory.cloneDeterministic(salt, initdata);
        wallet1 = TimelockSCW(wallet1Address);
    }

    /**
        It is not possible to deposit to Factory
     */
    function testCannotDepositToFactory() public {
        vm.expectRevert("Function must be called through delegatecall");
        walletFactory.depositNative{value: 1000000000}(block.timestamp+15000);
    }

    /**
        Anyone can deposit Native Token to Clone and deposit is created
     */
    function testCanDepositNativeAndDepositIsCreated() public {
        uint256 amount = 181349737234823;
        uint256 unlock_timestamp = block.timestamp+65340012;
        wallet1.depositNative{value: amount}(unlock_timestamp);
        (address recAddress, 
         uint256 recAmount, 
         uint256 recUnlockTS, 
         bool recClaimed) = wallet1.deposits(wallet1.lastDepositId());
        assertEq(amount, recAmount);
        assertEq(unlock_timestamp, recUnlockTS);
        assertEq(address(0), recAddress);
        assertEq(false, recClaimed);
    }

    /**
        Non Owner can NOT claim Native token Deposit
     */
    function testNonOwnerCanNotClaim() public {
        uint256 amount = 181349737234823;
        uint256 unlock_timestamp = block.timestamp+65340012;

        //deposit
        wallet1.depositNative{value: amount}(unlock_timestamp);

        uint256 lastDepId = wallet1.lastDepositId();

        //claim
        vm.prank(address(1));

        vm.expectRevert("Ownable: caller is not the owner");
        wallet1.claimDeposit(lastDepId);

        (, , , bool recClaimed) = wallet1.deposits(lastDepId);
        
        // deposit is not marked as claimed
        assertEq(false, recClaimed);
    }

    /**
        Even Owner can NOT claim Native token Deposit that is NOT unlocked YET
     */
     function testOwnerCanNotClaimLockedNativeTokenDeposit() public {
        uint256 amount = 181349737234823;
        uint256 unlock_timestamp = block.timestamp+1332445453564;

        //deposit
        wallet1.depositNative{value: amount}(unlock_timestamp);

        uint256 lastDepId = wallet1.lastDepositId();

        //claim
        vm.startPrank(wal1owner);
        vm.expectRevert("TLSCW: Deposit not available yet");
        wallet1.claimDeposit(lastDepId);

        (, , , bool recClaimed) = wallet1.deposits(lastDepId);
        
        // deposit not marked as claimed
        assertEq(false, recClaimed);
    }

    /**
        Owner can claim Native token Deposit that is unlocked
     */
    function testOwnerCanClaimUnlockedNativeTokenDeposit() public {
        uint256 amount = 181349737234823;
        uint256 unlock_timestamp = block.timestamp+1332445453564;

        //deposit
        wallet1.depositNative{value: amount}(unlock_timestamp);

        uint256 lastDepId = wallet1.lastDepositId();
        uint256 blaOwnerBefore = wal1owner.balance;

        //claim
        vm.warp(unlock_timestamp+100);
        vm.prank(wal1owner);
        wallet1.claimDeposit(lastDepId);

        uint256 blaOwnerAfter = wal1owner.balance;

        (, , , bool recClaimed) = wallet1.deposits(lastDepId);
        
        // deposit marked as claimed
        assertEq(true, recClaimed);

        // owner received funds
        assertEq(amount, blaOwnerAfter-blaOwnerBefore);
    }

    /**
        Owner can NOT claim Native token Deposit that is unlocked but already Claimed
     */
    function testOwnerCannotClaimUnlockedNativeTokenDepositAlreadyClaimed() public {
        uint256 amount = 181349737234823;
        uint256 unlock_timestamp = block.timestamp+1332445453564;

        //deposit
        wallet1.depositNative{value: amount}(unlock_timestamp);

        uint256 lastDepId = wallet1.lastDepositId();
        uint256 blaOwnerBefore = wal1owner.balance;

        //claim
        vm.warp(unlock_timestamp+100);
        vm.startPrank(wal1owner);
        wallet1.claimDeposit(lastDepId);

        uint256 blaOwnerAfter = wal1owner.balance;

        (, , , bool recClaimed) = wallet1.deposits(lastDepId);
        
        // deposit marked as claimed
        assertEq(true, recClaimed);
        // owner received funds
        assertEq(amount, blaOwnerAfter-blaOwnerBefore);

        //try claim again
        vm.expectRevert("TLSCW: Deposit already claimed");
        wallet1.claimDeposit(lastDepId);
    }

    // ERC20 deposits and claims

    /**
        User can Deposit ERC20 token and deposit is created
     */
    function testCanDepositERC20() public {
        uint256 amount = 15*10**18; 
        uint256 unlock_timestamp = block.timestamp+1332445453564;

        vm.startPrank(address(1002));
        ERC20Token.approve(address(wallet1), amount);
        wallet1.depositERC20(address(ERC20Token), amount, unlock_timestamp);
        vm.stopPrank();

        uint256 lastDepId = wallet1.lastDepositId();

        (address recAddress, 
         uint256 recAmount, 
         uint256 recUnlockTS, 
         bool recClaimed) = wallet1.deposits(lastDepId);
        
        assertEq(amount, recAmount);
        assertEq(unlock_timestamp, recUnlockTS);
        assertEq(address(ERC20Token), recAddress);
        assertEq(false, recClaimed);

        assertEq(ERC20Token.balanceOf(address(wallet1)), amount);
    }

    /**
        Owner can claim ERC-20 token Deposit that is unlocked
     */
    function testOwnerCanClamERC20Deposit() public {
        uint256 amount = 15*10**18; 
        uint256 unlock_timestamp = block.timestamp+1332445453564;

        vm.startPrank(address(1002));
        ERC20Token.approve(address(wallet1), amount);
        wallet1.depositERC20(address(ERC20Token), amount, unlock_timestamp);
        vm.stopPrank();

        uint256 lastDepId = wallet1.lastDepositId();
        uint256 balOwnerBefore = ERC20Token.balanceOf(wal1owner);

        // Claim
        vm.warp(unlock_timestamp+100);
        vm.startPrank(wal1owner);
        wallet1.claimDeposit(lastDepId);

        uint256 balOwnerAfter = ERC20Token.balanceOf(wal1owner);

        (address recAddress, 
         uint256 recAmount, 
         uint256 recUnlockTS, 
         bool recClaimed) = wallet1.deposits(lastDepId);
        
         // deposit marked as claimed
        assertEq(true, recClaimed);
        // owner received funds
        assertEq(amount, balOwnerAfter-balOwnerBefore);
    }

    /**
        Deposit is not created when transfer fails
     */
    function testCanNotDepositNotApprovedERC20AndDepositNotCreated() public {
        uint256 amount = 15*10**18; 
        uint256 unlock_timestamp = block.timestamp+1332445453564;

        uint256 lastDepIdBefore = wallet1.lastDepositId();

        vm.startPrank(address(1002));
        //ERC20Token.approve(address(wallet1), amount);
        vm.expectRevert("ERC20: insufficient allowance");
        wallet1.depositERC20(address(ERC20Token), amount, unlock_timestamp);
        vm.stopPrank();

        uint256 lastDepIdAfter = wallet1.lastDepositId();

        assertEq(lastDepIdAfter, lastDepIdBefore);
    }

}
