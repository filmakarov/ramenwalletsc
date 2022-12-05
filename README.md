# Ramen wallet

Timelock Smart contract core implementation. 
* Instances (individual wallets) are created using Clones library by OZ.
* Ownership is allowed by simple Ownable pattern inspired by OZ.
* Not upgradeable for the quick prototyping purposes.

In production this approach can be shifted towards more flexibility via:
1) Introducing upgradeability via Beacon Proxies Pattern
2) Introducing ownership through Dharma's userSigningKey-like approach
  
Alternative approach is to make everything served by one contract, just storing the receiver for every deposit. However, keeping everyone's funds in the one centrally governed contract is always less secure, than having individually ownable personal wallets.   

## Functionality: 
*   Anyone can deposit ERC20 or Native tokens. 
*   Unlocking timestamp is set at the deposit. 
*   Owner can claim any deposit, that is unlocked.
*   Meta transactions enabled. So anyone can initiate claimDeposit as long as caller has owner's signature.


   ## Future work
*   Batch claims
*   Partial claims (claimAmount <= deposit.amount)  
*   Rescue mechanism for ERC20 tokens that user accidentally sends directly to this wallet