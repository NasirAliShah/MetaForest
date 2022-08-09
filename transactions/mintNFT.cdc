import FungibleToken from 0xee82856bf20e2aa6
import CET from 0x179b6b1cb6755e31

transaction(templateId: UInt64, account:Address){

    prepare(acct: AuthAccount) {
        let adminRef = acct.borrow<&AFLAdmin.Admin>(from: /storage/AFLAdmin)
            ??panic("could not borrow reference")

        adminRef.openPack( templateId: templateId, account: account)
    }
}