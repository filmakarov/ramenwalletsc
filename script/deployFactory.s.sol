// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import "@std/console.sol";
import "@std/Script.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "../src/TLSCW.sol";

contract DeployFactory is Script {

    using Strings for uint256;

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_GOERLI");
        vm.startBroadcast(deployerPrivateKey);

        TimelockSCW WalletFactory = new TimelockSCW();

        console.log("Factory at %s owner is %s", address(WalletFactory), WalletFactory.owner());
       
        vm.stopBroadcast();

    }

}