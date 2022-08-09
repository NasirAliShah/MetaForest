import CET from 0x179b6b1cb6755e31
import FungibleToken from 0xee82856bf20e2aa6
pub contract MetaForestCarbonEmission {

    access(self) var totalEmission : {Address: UInt64}
    access(self) var lastEmission : {Address: UInt64}
    access(self) var lastUpdate : {Address:UInt64}
    pub var blockNumOfOneDay: UFix64


    pub fun lastBalanceOf(user: Address):UInt64 {
        let CETBalance = getAccount(user).getCapability(/public/CETBalance)
                            .borrow<&CET.Vault{FungibleToken.Balance}>() 
                            ??panic("could not borrow reference")
        MetaForestCarbonEmission.lastEmission[user] = CETBalance.balance
        return CETBalance.balance
        // let convertedBlockNumber = MetaForestCarbonEmission.blockNumOfOneDay as! UInt64
        // if convertedBlockNumber - MetaForestCarbonEmission.lastUpdate[user]! > convertedBlockNumber{
        //     return 0
        // }
        // return MetaForestCarbonEmission.lastEmission[user]!
    }

    pub fun lastUpdateOf(user: Address):UInt64{
        let CETBalance = getAccount(user).getCapability(/public/CETBalance).borrow<&CET.Vault{FungibleToken.Balance}>() ??panic("could not borrow reference")
        MetaForestCarbonEmission.lastUpdate[user] = CETBalance.balance
        return CETBalance.balance
        // return  MetaForestCarbonEmission.lastUpdate[user]!
        
    }
    pub fun totalBalanceOf(user: Address):UInt64  {
        let CETBalance = getAccount(user).getCapability(/public/CETBalance).borrow<&CET.Vault{FungibleToken.Balance}>() ??panic("could not borrow reference")
        MetaForestCarbonEmission.totalEmission[user] = CETBalance.balance
        return CETBalance.balance
        // return MetaForestCarbonEmission.totalEmission[user]!
    }


    access(account) fun increaseMetaForestCarbonEmissions(user: Address, amount:UInt64){
        let convertedBlockNumber = MetaForestCarbonEmission.blockNumOfOneDay as! UInt64
        assert(convertedBlockNumber - MetaForestCarbonEmission.lastUpdate[user]! > convertedBlockNumber, message: "can't increase in limit time")
        MetaForestCarbonEmission.lastUpdate[user] = MetaForestCarbonEmission.blockNumOfOneDay as! UInt64
        MetaForestCarbonEmission.lastEmission[user] = amount
        MetaForestCarbonEmission.totalEmission[user] = MetaForestCarbonEmission.totalEmission[user]! + amount

    }




    init(){
        self.totalEmission = {}
        self.lastEmission = {}
        self.lastUpdate = {}
        self.blockNumOfOneDay = getCurrentBlock().timestamp
    }
}