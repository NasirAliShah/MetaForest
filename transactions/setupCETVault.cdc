// This script is used to add a Vault resource to their account so that they can use FiatToken 
//
// If the Vault already exist for the account, the script will return immediately without error
// 
// If not onchain-multisig is required, pubkeys and key weights can be empty
// Vault resource must follow the FuntibleToken interface where initialiser only takes the balance
// As a result, the Vault owner is required to directly add public keys to the OnChainMultiSig.Manager
// via the `addKeys` method in the OnchainMultiSig.KeyManager interface.
// 
// Therefore if multisig is required for the vault, the account itself should have the same key weight
// distribution as it does for the Vault.
import FungibleToken from 0xee82856bf20e2aa6
import CET from 0x179b6b1cb6755e31



transaction() {

    prepare(signer: AuthAccount) {

        // Return early if the account already stores a FiatToken Vault
        if signer.borrow<&CET.Vault>(from: /storage/CETVault) == nil {
             // Create a new ExampleToken Vault and put it in storage
            signer.save(
                <-CET.createEmptyVault(),
                to: /storage/CETVault
            )

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            signer.link<&CET.Vault{FungibleToken.Receiver}>(
                /public/CETReceiver,
                target: /storage/CETVault
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            signer.link<&CET.Vault{FungibleToken.Balance}>(
                /public/CETBalance,
                target: /storage/CETVault
            )   
        }

    }
}