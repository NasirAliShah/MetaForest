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
                wateringAmount >= CET.balance :  "watering amount should be equal or greater than CET balance"
            }
            // get user nft get template id from data and then update token uri of user template
            //get refrence 
            let account = getAccount(userAddress)
            let acct1Capability = account.getCapability(MetaForestTree.CollectionPublicPath)
                                                .borrow<&{MetaForestTree.MetaForestTreeCollectionPublic}>()
                                                ?? panic("Could not get receiver reference to the NFT Collection")
            var nftData = MetaForestTree.getNFTDataById(nftId: tokenId)
            let templateTd = nftData.templateId
            //token greate then 20
            if wateringAmount > 1 || wateringAmount <= 10 {
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[1])
            }else if wateringAmount > 10 || wateringAmount <= 20{
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[2])
            }else if  wateringAmount > 20 || wateringAmount <= 30 {
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[3])
            }else {
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[4])
            }
            
            
            if MetaForestCore.unHealthy[tokenId]! >= wateringAmount {
                MetaForestCore.unHealthy[tokenId] =  MetaForestCore.unHealthy[tokenId]! - wateringAmount
            }else {
                MetaForestCore.growth[tokenId] = MetaForestCore.growth[tokenId]! + wateringAmount - MetaForestCore.unHealthy[tokenId]!
                MetaForestCore.unHealthy[tokenId] = 0
            }
            destroy  CET

            // withdraw and burn CET Token
            emit Watering(account:userAddress , tokenId: tokenId, wateringAmount:wateringAmount)
        }
        pub fun attack(account: Address, tokenId:UInt64, amount: UInt64){
            pre {
                tokenId != 0: "token id should be valid"
                amount > 0: "wateringAmount id should be valid"
                account != nil: "userAddress should be valid"
                }
            // get user nft get template id from data and then update token uri of user template
            //get refrence 
            let account1 = getAccount(account)
            let acct1Capability = account1.getCapability(/public/CETBalance)
                                                .borrow<&CET.Vault{FungibleToken.Balance}>()
                                                ?? panic("Could not get receiver reference to the NFT Collection")
            let acc1Balance = acct1Capability.balance            
            let lastEmissionBalance = MetaForestCarbonEmmision.lastBalanceOf(account:account)
            assert(account == self.owner!.address, message: "account not the token owner")
            assert(MetaForestCore.lastAttack[account] < MetaForestCarbonEmmision.lastUpdateOf(account), message: "has attacked")
            assert(amount <= acc1Balance, message: "insufficient carbo emission")

            MetaForestCore.unHealthy[tokenId] = MetaForestCore.unHealthy[tokenId]! + amount
            MetaForestCore.lastAttack[account] = getCurrentBlock().timestamp

            emit Attack(account: self.owner!.address, tokenId: tokenId, amount:amount)
        }

        // Method to Purchase an NFT with Flow Tokens
        pub fun purchaseNFTWithFlow(templateId: UInt64, recipientAddress: Address, flowPayment: @FungibleToken.Vault) {
            pre {
            templateId != 0: "template it must not be zero"
            recipientAddress != nil : "recript address must not be null"
            flowPayment.balance >= MetaForestCore.price: "flow payment must be greater than price of the nft"

            // flowPayment.balance == MetaForestTree.allTemplates[templateId]!.immutableData.price: "Your vault does not have enough balance to buy this Template!"
           // self.allTemplates.containsKey(templateId): "Template ID must have to be valid"
            }
            
            let adminVaultReceiverRef = getAccount(self.account.address).getCapability(/public/CETReceiver)
                                                .borrow<&CET.Vault{FungibleToken.Receiver}>()
                                                ?? panic("Could not borrow reference to owner token vault!")
            adminVaultReceiverRef.deposit(from: <- flowPayment)
            
            MetaForestTree.mintNFT(templateId: templateId, account: recipientAddress)
        }
        
        pub fun purchaseNFTFree(templateId: UInt64, recipientAddress: Address) {
            pre {
                templateId != 0: "template it must not be zero"
                recipientAddress != nil : "recript address must not be null"
            }
            assert(MetaForestCore.freeList[recipientAddress] == true, message: "already minted free nft")
            MetaForestTree.mintNFT(templateId: templateId, account: recipientAddress)
            MetaForestCore.freeList[recipientAddress] = true
                
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

        self.account.save(<- create Core(), to: /storage/MetaForestCore)
        self.account.link<&{CorePublic}>(/public/MetaForestCore, target: /storage/MetaForestCore)
    }
    
}