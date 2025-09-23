import Foundation

struct AdminApproveResponse: Codable {
    let data: DataContainer
    let message: String?

    struct DataContainer: Codable {
        let shop: Shop
        let proposal: ShopProposal
    }
}

