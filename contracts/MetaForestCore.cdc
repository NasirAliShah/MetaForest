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
    access(contract) var tokenURI: {UInt64: String}
    access(contract) var tokenURICount: UInt64

    access(self) var price : UInt64
    pub event Attack(account: Address, tokenId: UInt64, amount:UInt64)
    pub event Watering(account: Address, tokenId: UInt64, wateringAmount:UInt64)


pub resource interface CorePublic{ 
    pub fun watering(tokenId: UInt64, wateringAmount: UInt64, userAddress: Address, CET: @FungibleToken.Vault)
    pub fun attack(account: Address, tokenId:UInt64, amount: UInt64)
    pub fun purchaseNFTWithFlow(templateId: UInt64, recipientAddress: Address, flowPayment: @FungibleToken.Vault)
}

   
    pub resource Core : CorePublic {

        pub fun watering(tokenId: UInt64, wateringAmount: UInt64, userAddress: Address, CET: @FungibleToken.Vault){
            pre {
                tokenId != 0: "token id should be valid"
                wateringAmount > 0: "wateringAmount id should be valid"
                userAddress != nil: "userAddress should be valid"
                wateringAmount >= CET.balance :  "CET balance id should be greater then zero"
            }

            // get user nft get template id from data and then update token uri of user template
            //get refrence 
            let account = getAccount(userAddress)
           let acct1Capability = account.getCapability(NFTContract.CollectionPublicPath)
                            .borrow<&{NonFungibleToken.CollectionPublic}>()
                            ??panic("could not borrow receiver reference ")
            var nftData = MetaForestTree.getNFTDataById(nftId: tokenId)
            let templateTd = nftData.templateID
            //token greate then 2o 
            if(wateringAmount >10){
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[1])
            }
            
            
            if MetaForestCore.unHealthy[tokenId]! >= wateringAmount {
                MetaForestCore.unHealthy[tokenId] =  MetaForestCore.unHealthy[tokenId]! - wateringAmount
            }else {
                MetaForestCore.growth[tokenId] = MetaForestCore.growth[tokenId]! + wateringAmount - MetaForestCore.unHealthy[tokenId]!
                MetaForestCore.unHealthy[tokenId] = 0
            }
            destroy  CET

            // withdraw and burn CET Token
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

        // Method to Purchase an NFT with Flow Tokens
    pub fun purchaseNFTWithFlow(templateId: UInt64, recipientAddress: Address, flowPayment: @FungibleToken.Vault) {
        pre {
            // flowPayment.balance == MetaForestTree.allTemplates[templateId]!.immutableData.price: "Your vault does not have enough balance to buy this Template!"
           // self.allTemplates.containsKey(templateId): "Template ID must have to be valid"
            }
            
        let adminVaultReceiverRef = getAccount(self.account.address).getCapability(self.AdminFlowTokenReceiver).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()
                    ?? panic("Could not borrow reference to owner token vault!")
        adminVaultReceiverRef.deposit(from: <- flowPayment)
        
        MetaForestTree.mintNFT(templateId: templateId, account: recipientAddress)
        }

        pub fun setTokenUriData(tokenUri: String){
            pre {
                tokenUri.length > 0: "token uri should be valid"
            }

            MetaForestCore.tokenURI[MetaForestCore.tokenURICount] = tokenUri
        }

    }


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
        self.tokenURI = {}
        self.tokenURICount = 1
    }
    
}