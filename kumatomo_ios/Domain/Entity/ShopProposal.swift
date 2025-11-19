import Foundation

struct ShopProposal: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    let name: String
    let address: String?
    let genre: ShopGenre?
    let description: String?
    let status: ProposalStatus
    let adminNotes: String?
    let createdAt: Date
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, address, genre, description, status
        case adminNotes = "admin_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum ProposalStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"

    var displayName: String {
        switch self {
        case .pending:
            return "承認待ち"
        case .approved:
            return "承認済み"
        case .rejected:
            return "却下"
        }
    }

    var isActive: Bool {
        return self == .pending
    }
}

extension ShopProposal {
    init(id: Int = 0, userId: Int, name: String, address: String? = nil, genre: ShopGenre? = nil, description: String? = nil, status: ProposalStatus = .pending, adminNotes: String? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.address = address
        self.genre = genre
        self.description = description
        self.status = status
        self.adminNotes = adminNotes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}