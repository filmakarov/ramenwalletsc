// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import "@std/console.sol";
import "@std/Script.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "../src/TLSCW.sol";

contract DeployIF is Script {

    using Strings for uint256;

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ANVIL");
        vm.startBroadcast(deployerPrivateKey);
        //vm.startBroadcast();

        TimelockSCW WalletFactory = new TimelockSCW();

        bytes memory initdata = abi.encodeWithSignature(
                            "initialize(string,string,address)", //function signature
                            string(abi.encodePacked("Timelock Wallet ", (WalletFactory.lastWalletId()+1).toString())), //name
                            "1", // version
                            0x14dC79964da2C08b23698B3D3cc7Ca32193d9955); // owner

        bytes32 salt = bytes32(abi.encodePacked(
                                    "Timelock Wallet", 
                                    (WalletFactory.lastWalletId()+1).toString(), 
                                    block.timestamp.toString()));

        address newWalletAddress = WalletFactory.predictDeterministicAddress(salt);

        WalletFactory.cloneDeterministic(salt, initdata);

        console.log("Factory at %s owner is %s", address(WalletFactory), WalletFactory.owner());
        console.log("Wallet %i at %s owner is %s", (WalletFactory.lastWalletId()), newWalletAddress, TimelockSCW(newWalletAddress).owner());
        console.logBytes32(TimelockSCW(newWalletAddress).exposedDomSep());


        // SECOND WALLET //

        initdata = abi.encodeWithSignature(
                            "initialize(string,string,address)", //function signature
                            string(abi.encodePacked("Timelock Wallet ", (WalletFactory.lastWalletId()+1).toString())), //name
                            "1", // version
                            0x976EA74026E726554dB657fA54763abd0C3a0aa9); // owner

        salt = bytes32(abi.encodePacked(
                                    "Timelock Wallet", 
                                    (WalletFactory.lastWalletId()+1).toString(), 
                                    block.timestamp.toString()));

        newWalletAddress = WalletFactory.predictDeterministicAddress(salt);

        WalletFactory.cloneDeterministic(salt, initdata);

        console.log("Wallet %i at %s owner is %s", (WalletFactory.lastWalletId()), newWalletAddress, TimelockSCW(newWalletAddress).owner());
        console.logBytes32(TimelockSCW(newWalletAddress).exposedDomSep());
        
        vm.stopBroadcast();

    }

}