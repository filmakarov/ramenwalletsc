// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

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

contract TimelockSCW is Ownable {

    //  deposit_id => deposit_details
    // mapping (uint256 => struct);

    // struct : token, amount, unlock_timestamp, claimed

    // mapping : token => [deposit_ids]

    // or smthng enummed


    // Initializable custom ownership mechanism




    /** 
    *           Implementation notes and future work
    *
    *   dfsdf
    *   fgdfgdfg
    *
    **/



}