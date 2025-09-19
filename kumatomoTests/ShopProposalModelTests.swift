import XCTest
@testable import kumatomo

final class ShopProposalModelTests: XCTestCase {
    
    func testShopProposalInitialization() {
        let proposal = ShopProposal(
            id: 1,
            userId: 123,
            name: "テスト店舗",
            address: "熊本市中央区テスト町1-2-3",
            genre: .ramen,
            description: "美味しいラーメン店です",
            status: .pending,
            adminNotes: nil
        )
        
        XCTAssertEqual(proposal.id, 1)
        XCTAssertEqual(proposal.userId, 123)
        XCTAssertEqual(proposal.name, "テスト店舗")
        XCTAssertEqual(proposal.address, "熊本市中央区テスト町1-2-3")
        XCTAssertEqual(proposal.genre, .ramen)
        XCTAssertEqual(proposal.description, "美味しいラーメン店です")
        XCTAssertEqual(proposal.status, .pending)
        XCTAssertNil(proposal.adminNotes)
    }
    
    func testShopProposalMinimalInitialization() {
        let proposal = ShopProposal(
            id: 2,
            userId: 456,
            name: "ミニマル店舗",
            status: .pending
        )
        
        XCTAssertEqual(proposal.id, 2)
        XCTAssertEqual(proposal.userId, 456)
        XCTAssertEqual(proposal.name, "ミニマル店舗")
        XCTAssertNil(proposal.address)
        XCTAssertNil(proposal.genre)
        XCTAssertNil(proposal.description)
        XCTAssertEqual(proposal.status, .pending)
        XCTAssertNil(proposal.adminNotes)
    }
    
    func testProposalStatusDisplayNames() {
        XCTAssertEqual(ProposalStatus.pending.displayName, "承認待ち")
        XCTAssertEqual(ProposalStatus.approved.displayName, "承認済み")
        XCTAssertEqual(ProposalStatus.rejected.displayName, "却下")
    }
    
    func testProposalStatusIsActive() {
        XCTAssertTrue(ProposalStatus.pending.isActive)
        XCTAssertFalse(ProposalStatus.approved.isActive)
        XCTAssertFalse(ProposalStatus.rejected.isActive)
    }
    
    func testShopProposalCodingKeys() {
        let jsonData = """
        {
            "id": 1,
            "user_id": 123,
            "name": "テスト店舗",
            "address": "熊本市中央区テスト町1-2-3",
            "genre": "ラーメン",
            "description": "美味しいラーメン店です",
            "status": "pending",
            "admin_notes": null,
            "created_at": "2025-09-19T12:00:00.000000Z",
            "updated_at": "2025-09-19T12:00:00.000000Z"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            let proposal = try decoder.decode(ShopProposal.self, from: jsonData)
            
            XCTAssertEqual(proposal.id, 1)
            XCTAssertEqual(proposal.userId, 123)
            XCTAssertEqual(proposal.name, "テスト店舗")
            XCTAssertEqual(proposal.address, "熊本市中央区テスト町1-2-3")
            XCTAssertEqual(proposal.genre, .ramen)
            XCTAssertEqual(proposal.description, "美味しいラーメン店です")
            XCTAssertEqual(proposal.status, .pending)
            XCTAssertNil(proposal.adminNotes)
        } catch {
            XCTFail("Failed to decode ShopProposal: \(error)")
        }
    }
    
    func testShopProposalEquality() {
        let proposal1 = ShopProposal(
            id: 1,
            userId: 123,
            name: "テスト店舗",
            status: .pending
        )
        
        let proposal2 = ShopProposal(
            id: 1,
            userId: 123,
            name: "テスト店舗",
            status: .pending
        )
        
        let proposal3 = ShopProposal(
            id: 2,
            userId: 123,
            name: "テスト店舗",
            status: .pending
        )
        
        XCTAssertEqual(proposal1, proposal2)
        XCTAssertNotEqual(proposal1, proposal3)
    }
}