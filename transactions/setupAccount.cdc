import MetaForestTree from 0xf3fcd2c1a78f5eee

transaction {
    prepare(acct: AuthAccount) {
          // First, check to see if a collection already exists
        if acct.borrow<&MetaForestTree.Collection>(from: MetaForestTree.CollectionStoragePath) == nil{
        let collection  <- MetaForestTree.createEmptyCollection() as! @MetaForestTree.Collection
        // store the empty NFT Collection in account storage
        acct.save( <- collection, to:MetaForestTree.CollectionStoragePath)
        log("Collection created for account".concat(acct.address.toString()))
        // create a public capability for the Collection
        acct.link<&{MetaForestTree.MetaForestTreeCollectionPublic}>(MetaForestTree.CollectionPublicPath, target:MetaForestTree.CollectionStoragePath)
        log("Capability created")
        }
    }
}