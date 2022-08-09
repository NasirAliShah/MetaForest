import MetaForestAccessControl from 0xf3fcd2c1a78f5eee
import MetaForestTree from 0xf3fcd2c1a78f5eee
import MetaForestCarbonEmission from 0xf3fcd2c1a78f5eee
import CET from 0xf3fcd2c1a78f5eee

pub contract MetaForestCore {
    
    access(self) var freeList : {Address:Bool}
    access(self) var growth : {UInt64:UInt64}
    access(self) var unHealthy : {UInt64:UInt64}
    access(self) var lastAttack : {Address:UFix64}

    access(self) var maxNFTCanBuy : UInt64
    access(self) var nftHasSale : UInt64
    access(self) var nftHasCollected : UInt64

    access(self) var price : UInt64
    pub event Attack(account: Address, tokenId: UInt64, amount:UInt64)
    pub event Watering(account: Address, tokenId: UInt64, wateringAmount:UInt64)



    access(account) fun setPrice(price: UInt64){
        self.price = price
    }
    pub fun getPrice():UInt64{
        return  self.price
    }
    pub fun getNFTHasSale():UInt64{
        return  self.nftHasSale
    }
    pub fun getNFTHasCollected():UInt64{
        return  self.nftHasCollected
    }

    pub fun getFreeNFT(user: Address) {
        MetaForestCore.freeList[user] = true
    }

    pub resource Core  {

        pub fun watering(tokenId: UInt64, wateringAmount: UInt64){
            let account = self.owner!.address
            let owner = getAccount(account)

            let balance = owner.getCapability(/public/CETBalance).borrow<&CET.Vault{FungibleToken.Balance}>() ??panic("could not borrow refrence")
            assert(wateringAmount <= balance, message: "insufficent carbo energy")

            if MetaForestCore.unHealthy[tokenId]! >= wateringAmount {
                MetaForestCore.unHealthy[tokenId] =  MetaForestCore.unHealthy[tokenId]! - wateringAmount
            }else {
                MetaForestCore.growth[tokenId] = MetaForestCore.growth[tokenId]! + wateringAmount - MetaForestCore.unHealthy[tokenId]!
                MetaForestCore.unHealthy[tokenId] = 0
            }
            emit Watering(account:account , tokenId: tokenId, wateringAmount:wateringAmount)
        }
        pub fun attack(account: Address, tokenId:UInt64, amount: UInt64){
            let lastEmissionBalance = MetaForestCarbonEmmision.lastBalanceOf(account:account)
            assert(account == self.owner!.address, message: "account not the token owner")
            assert(MetaForestCore.lastAttack[account] < MetaForestCarbonEmmision.lastUpdateOf(account), message: "has attacked")
            assert(amount <= lastEmissionBalance, message: "insufficient carbo emission")

            MetaForestCore.unHealthy[tokenId] = MetaForestCore.unHealthy[tokenId]! + amount
            MetaForestCore.lastAttack[account] = getCurrentBlock().timestamp

            emit Attack(account: self.owner!.address, tokenId: tokenId, amount:amount)
        }
    }
    pub fun getGrowthAmount(tokenId:UInt64): UInt64{
        pre {
            tokenId!=nil:"token id must not be null"
        }
        return MetaForestCore.growth[tokenId]!
    }
    pub fun getAttackAmount(account:Address): UFix64{
        pre {
            account != nil : "account must not be null"
        }
        return MetaForestCarbonEmmision.lastBalanceOf(account:account)
    }

    pub fun getUnhealthyAmount(tokenId: UInt64):UInt64{
        return  MetaForestCore.unHealthy[tokenId]!
    }

    
    

    init(){
        self.freeList = {}
        self.growth = {}
        self.unHealthy = {}
        self.lastAttack = {}
        self.maxNFTCanBuy = 1
        self.nftHasSale = 1
        self.nftHasCollected = 1
        self.price = 1
    }
    
}