import MetaForestAccessControl from "./MetaForestAccessControl.cdc"
import MetaForestTree from "./MetaForestTree.cdc"
import MetaForestCarbonEmission from "./MetaForestCarbonEmission.cdc"
import CET from "./CET.cdc"
import FungibleToken from "./FungibleToken.cdc"

pub contract MetaForestCore {
    
    access(self) var freeList : {Address:Bool}
    access(self) var growth : {UInt64:UInt64}
    access(self) var unHealthy : {UInt64:UFix64}
    access(self) var lastAttack : {Address:UFix64}

    access(contract) var tokenURI: {UInt64: String}
    access(contract) var tokenURICount: UInt64

    pub event Attack(account: Address, tokenId: UInt64, amount:UFix64)
    pub event Watering(account: Address, tokenId: UInt64, wateringAmount:UFix64)
    pub event NFTPurchased(account: Address, templateId: UInt64)


    pub resource interface CorePublic{ 
        pub fun watering(tokenId: UInt64, wateringAmount: UFix64, userAddress: Address, CET: @FungibleToken.Vault)
        pub fun attack(nftAccount: Address, tokenId:UInt64, attackAmount: UFix64, CET: @FungibleToken.Vault)
        pub fun purchaseNFTWithFlow(templateId: UInt64, recipientAddress: Address, flowPayment: @FungibleToken.Vault)
        pub fun purchaseNFTFree(templateId: UInt64, recipientAddress: Address)
    }

    pub resource Core : CorePublic {

        pub fun watering(tokenId: UInt64, wateringAmount: UFix64, userAddress: Address, CET: @FungibleToken.Vault){
            pre {
                tokenId != 0: "token id should be valid"
                wateringAmount > UFix64(0.0): "wateringAmount id should be valid"
                userAddress != nil: "userAddress should be valid"
                wateringAmount >= CET.balance :  "watering amount should be equal or greater than CET balance"
            }
            // get user nft get template id from data and then update token uri of user template
            //get refrence 
            let account = getAccount(userAddress)
            let acct1Capability = account.getCapability(MetaForestTree.CollectionPublicPath)
                                                .borrow<&{MetaForestTree.MetaForestTreeCollectionPublic}>()
                                                ?? panic("Could not get receiver reference to the NFT Collection")
            var nftIds =   acct1Capability.getIDs()
            assert(nftIds.contains(tokenId), message: "you don't have nft with this id")

            var nftData = MetaForestTree.getNFTDataById(nftId: tokenId)
            let templateTd = nftData.templateId
            
            if(wateringAmount <= 10.0) {
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[1])
            }else if(wateringAmount <= 20.0) {
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[2])
            }else if(wateringAmount <= 30.0) {
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[3])
            }else {
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[4])
            }
            
            // check the healthy and unhealthy amount 
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
        pub fun attack(nftAccount: Address, tokenId:UInt64, attackAmount: UFix64, CET: @FungibleToken.Vault){
            pre {
                tokenId != 0: "token id should be valid"
                attackAmount >= 20.0 : "attackAmount id should be valid"
                nftAccount != nil: "userAddress should be valid"
                attackAmount >= CET.balance : "attack amount should be equal or greater than CET balance"
                }
            // get user nft get template id from data and then update token uri of user template
            //get refrence 
                let account = getAccount(nftAccount)
            let acct1Capability = account.getCapability(MetaForestTree.CollectionPublicPath)
                                    .borrow<&{MetaForestTree.MetaForestTreeCollectionPublic}>()
                                    ?? panic("Could not get receiver reference to the NFT Collection")
            var nftIds =  acct1Capability.getIDs()
            assert(nftIds.contains(tokenId), message: "user doesn't have nft with this id which you want to attack")

            var nftData = MetaForestTree.getNFTDataById(nftId: tokenId)
            let templateTd = nftData.templateId
            //token greate then 20
            if(attackAmount == 20.0) {
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[2-1])
            }else if(attackAmount == 30.0) {
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[3-1])
            }else {
                MetaForestTree.updateTokenUri(templateId: templateTd, tokenUri: MetaForestCore.tokenURI[4-1])
            }
            

            MetaForestCore.unHealthy[tokenId] = MetaForestCore.unHealthy[tokenId]! + attackAmount
            MetaForestCore.lastAttack[nftAccount] = getCurrentBlock().timestamp

            destroy  CET

            emit Attack(account: self.owner!.address, tokenId: tokenId, amount: attackAmount)
        }

        // Method to Purchase an NFT with Flow Tokens
        pub fun purchaseNFTWithFlow(templateId: UInt64, recipientAddress: Address, flowPayment: @FungibleToken.Vault) {
            pre {
                templateId != 0: "template it must not be zero"
                recipientAddress != nil: "recript address must not be null"
            }
            
            let adminVaultReceiverRef = getAccount(self.account.address).getCapability(/public/CETReceiver)
                                        .borrow<&CET.Vault{FungibleToken.Receiver}>()
                                        ?? panic("Could not borrow reference to owner token vault!")
            adminVaultReceiverRef.deposit(from: <- flowPayment)
            
            MetaForestTree.mintNFT(templateId: templateId, account: recipientAddress)

            emit NFTPurchased(account: recipientAddress, templateId: templateId)
        }
        
        pub fun purchaseNFTFree(templateId: UInt64, recipientAddress: Address) {
            pre {
                templateId != 0: "template it must not be zero"
                recipientAddress != nil : "recript address must not be null"
                MetaForestCore.freeList[recipientAddress] != true: "you have already get free nft"
            }
            MetaForestTree.mintNFT(templateId: templateId, account: recipientAddress)
            MetaForestCore.freeList[recipientAddress] = true

            emit NFTPurchased(account: recipientAddress, templateId: templateId)
        }

        pub fun setTokenUriData(tokenUri: String){
            pre {
                tokenUri.length > 0: "token uri should be valid"
            }

            MetaForestCore.tokenURI[MetaForestCore.tokenURICount] = tokenUri
            MetaForestCore.tokenURICount = MetaForestCore.tokenURICount + 1

            
        }

    }
    pub fun getGrowthAmount(tokenId:UInt64): UInt64{
        pre {
            tokenId != 0:"token id must not be null"
        }
        return MetaForestCore.growth[tokenId]!
    }
    pub fun getAttackAmount(account:Address): UFix64{
        pre {
            account != nil : "account must not be null"
        }
        return MetaForestCarbonEmission.getlastBalanceOf(user: account)
    }

    pub fun getUnhealthyAmount(tokenId: UInt64): UFix64{
        return  MetaForestCore.unHealthy[tokenId]!
    }

    
    

    init(){
        self.freeList = {}
        self.growth = {}
        self.unHealthy = {}
        self.lastAttack = {}
        self.tokenURI = {}
        self.tokenURICount = 1

        self.account.save(<- create Core(), to: /storage/MetaForestCore)
        self.account.link<&{CorePublic}>(/public/MetaForestCore, target: /storage/MetaForestCore)
    }
    
}