import MetaForestTree from "./MetaForestTree.cdc"
import MetaForestCarbonEmission from "./MetaForestCarbonEmission.cdc"
import MetaForestCore from "./MetaForestCore.cdc"
pub contract MetaForestAccessControl {
    
    pub let AdminStoragePath: StoragePath

    pub resource Admin {

        pub fun createTemplate(maxSupply: UInt64, immutableData: {String:AnyStruct}){
            MetaForestTree.createTemplate(maxSupply:maxSupply, immutableData: immutableData)
        }

        pub fun increaseMetaForestCarbonEmissions(user: Address, amount:UInt8){
            MetaForestCarbonEmission.increaseMetaForestCarbonEmissions(user:user, amount: amount)
        }
        pub fun mintNFT(templateId:UInt64, receiptAccount:Address){
            MetaForestTree.mintNFT(templateId:templateId, account:receiptAccount)
        }
        pub fun watering(tokenId: UInt64, wateringAmount: UInt64){
            MetaForestCore.watering(tokenId:tokenId, wateringAmount: wateringAmount)
        }
        pub fun attack(account: Address, tokenId:UInt64, amount: UInt64){
            MetaForestCore.attack(account:account, tokenId:tokenId, amount:amount)
        }
        
    }

    init(){  
        self.AdminStoragePath = /storage/MetaForestAdmin
        self.account.save(<- create Admin(), to:  self.AdminStoragePath)
    }
    
}