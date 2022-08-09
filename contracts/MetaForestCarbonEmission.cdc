import CET from "./CET.cdc"
import FungibleToken from "./FungibleToken.cdc"
pub contract MetaForestCarbonEmission {

    access(self) var totalEmission : {Address: UFix64}
    access(self) var lastEmission : {Address: UFix64}
    access(self) var lastUpdate : {Address:UFix64}
    pub var blockNumOfOneDay: UFix64


    access(account) fun increaseMetaForestCarbonEmissions(user: Address, amount: UFix64){
        
        let convertedBlockNumber = MetaForestCarbonEmission.blockNumOfOneDay
        assert(convertedBlockNumber - MetaForestCarbonEmission.lastUpdate[user]! > convertedBlockNumber, message: "can't increase in limit time")
        MetaForestCarbonEmission.lastUpdate[user] = MetaForestCarbonEmission.blockNumOfOneDay
        MetaForestCarbonEmission.lastEmission[user] = amount
        MetaForestCarbonEmission.totalEmission[user] = MetaForestCarbonEmission.totalEmission[user]! + amount

        let tokenAdmin = self.account.borrow<&CET.Administrator>(from: /storage/CETAdmin)
            ?? panic("Signer is not the token admin")

        let tokenReceiver = getAccount(user)
            .getCapability(/public/CETReceiver)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")
        let minter <- tokenAdmin.createNewMinter(allowedAmount: amount)
        let mintedVault <- minter.mintTokens(amount: amount)
        let castedVault  <-mintedVault as! @FungibleToken.Vault
        tokenReceiver.deposit(from: <-castedVault)

        destroy minter
    }


    pub fun getlastBalanceOf(user: Address): UFix64 {
            let CETBalance = getAccount(user).getCapability(/public/CETBalance)
                                .borrow<&{FungibleToken.Balance}>() 
                                ??panic("could not borrow reference")
            MetaForestCarbonEmission.lastEmission[user] = CETBalance.balance
            return CETBalance.balance
            
        }

        pub fun getlastUpdateOf(user: Address):UFix64{
            let CETBalance = getAccount(user).getCapability(/public/CETBalance)
                                .borrow<&{FungibleToken.Balance}>() 
                                ??panic("could not borrow reference")
            MetaForestCarbonEmission.lastUpdate[user] = CETBalance.balance
            return CETBalance.balance
            
        }
        pub fun gettotalBalanceOf(user: Address): UFix64  {
            let CETBalance = getAccount(user).getCapability(/public/CETBalance)
                            .borrow<&{FungibleToken.Balance}>() 
                            ??panic("could not borrow reference")
            MetaForestCarbonEmission.totalEmission[user] = CETBalance.balance
            return CETBalance.balance
        }

    init(){
        self.totalEmission = {}
        self.lastEmission = {}
        self.lastUpdate = {}
        self.blockNumOfOneDay = getCurrentBlock().timestamp
    }
}