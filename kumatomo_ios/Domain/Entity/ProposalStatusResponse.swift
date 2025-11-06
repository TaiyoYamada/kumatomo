import Foundation

struct ProposalStatusResponse: Codable {
    let data: [ShopProposal]
    let summary: ProposalSummary
}

struct ProposalSummary: Codable {
    let pending: Int
    let approved: Int
    let rejected: Int

    var total: Int {
        return pending + approved + rejected
    }

    var hasPendingProposals: Bool {
        return pending > 0
    }

    var hasApprovedProposals: Bool {
        return approved > 0
    }

    var hasRejectedProposals: Bool {
        return rejected > 0
    }
}