import CET from 0x24b11736f820a1c8
import FungibleToken from 0x9a0766d93b6608b7
pub contract MetaForestCarbonEmission {

    // A dictionary that stores all token emissions against it's user.
    access(self) var totalEmission : {Address: UFix64}

    // A dictionary that stores last token emissions against it's user.
    access(self) var lastEmission : {Address: UFix64}

    // A dictionary that stores last token update emissions against it's user.
    access(self) var lastUpdate : {Address:UFix64}

    // variable for number of blocks produced in one day
    pub var blockNumOfOneDay: UFix64

    // Contract Event definitions
    pub event CarbonEmissionIncreased(user: Address, amount: UFix64)

    // function for increaseing the CET tokens of a user
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
            .borrow<&CET.Vault{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")
        let minter <- tokenAdmin.createNewMinter(allowedAmount: amount)
        let mintedVault <- minter.mintTokens(amount: amount)
        let castedVault  <-mintedVault as! @FungibleToken.Vault
        tokenReceiver.deposit(from: <-castedVault)
        destroy minter

        emit CarbonEmissionIncreased(user: user, amount: amount)
    }

    // get the CET balance for last emission against it's user
    pub fun getlastBalanceOf(user: Address): UFix64 {
            let CETBalance = getAccount(user).getCapability(/public/CETBalance)
                                .borrow<&CET.Vault{FungibleToken.Balance}>() 
                                ??panic("could not borrow reference")
            MetaForestCarbonEmission.lastEmission[user] = CETBalance.balance
            return CETBalance.balance
            
        }
        // get the CET balance for last update against it's user
        pub fun getlastUpdateOf(user: Address):UFix64{
            let CETBalance = getAccount(user).getCapability(/public/CETBalance)
                                .borrow<&CET.Vault{FungibleToken.Balance}>() 
                                ??panic("could not borrow reference")
            MetaForestCarbonEmission.lastUpdate[user] = CETBalance.balance
            return CETBalance.balance
            
        }
        // get the CET balance for total emission against it's user
        pub fun gettotalBalanceOf(user: Address): UFix64  {
            let CETBalance = getAccount(user).getCapability(/public/CETBalance)
                            .borrow<&CET.Vault{FungibleToken.Balance}>() 
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