// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@gsn/ERC2771Recipient.sol";
// change to eip712

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

contract TimelockSCW is ERC2771Recipient, Ownable {

    //  deposit_id => deposit_details
    // mapping (uint256 => struct);

    // struct : token, amount, unlock_timestamp, claimed

    // mapping : token => [deposit_ids]

    // or smthng enummed


    // Initializable custom ownership mechanism



    /**
    * @dev Use ERC2771Recipient msgSender() in all cases to support Meta txns
    **/
    function _msgSender() internal view virtual override(Context, ERC2771Recipient) returns (address) {
        return ERC2771Recipient._msgSender();
    }

    /**
     * @dev Use ERC2771Recipient msgData() in all cases to support Meta txns
    **/
    function _msgData() internal view virtual override(Context, ERC2771Recipient) returns (bytes calldata) {
        return ERC2771Recipient._msgData();
    }


    /** 
    *           Implementation notes and future work
    *
    *   dfsdf
    *   fgdfgdfg
    *
    **/



}