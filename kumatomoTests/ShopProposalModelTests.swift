import XCTest
@testable import kumatomo

final class ShopProposalModelTests: XCTestCase {
    
    func testShopProposalInitialization() {
        // Test basic shop proposal initialization
        let proposal = ShopProposal(
            id: 1,
            userId: 100,
            name: "New Ramen Shop",
            address: "123 Ramen Street",
            genre: .ramen,
            description: "Best ramen in town",
            status: .pending,
            adminNotes: "Under review"
        )
        
        XCTAssertEqual(proposal.id, 1)
        XCTAssertEqual(proposal.userId, 100)
        XCTAssertEqual(proposal.name, "New Ramen Shop")
        XCTAssertEqual(proposal.address, "123 Ramen Street")
        XCTAssertEqual(proposal.genre, .ramen)
        XCTAssertEqual(proposal.description, "Best ramen in town")
        XCTAssertEqual(proposal.status, .pending)
        XCTAssertEqual(proposal.adminNotes, "Under review")
    }
    
    func testShopProposalDefaultValues() {
        // Test shop proposal initialization with default values
        let proposal = ShopProposal(userId: 100, name: "Minimal Proposal")
        
        XCTAssertEqual(proposal.id, 0)
        XCTAssertEqual(proposal.userId, 100)
        XCTAssertEqual(proposal.name, "Minimal Proposal")
        XCTAssertNil(proposal.address)
        XCTAssertNil(proposal.genre)
        XCTAssertNil(proposal.description)
        XCTAssertEqual(proposal.status, .pending)
        XCTAssertNil(proposal.adminNotes)
    }
    
    func testProposalStatusDisplayNames() {
        // Test proposal status display names
        XCTAssertEqual(ProposalStatus.pending.displayName, "承認待ち")
        XCTAssertEqual(ProposalStatus.approved.displayName, "承認済み")
        XCTAssertEqual(ProposalStatus.rejected.displayName, "却下")
    }
    
    func testProposalStatusIsActive() {
        // Test proposal status isActive property
        XCTAssertTrue(ProposalStatus.pending.isActive)
        XCTAssertFalse(ProposalStatus.approved.isActive)
        XCTAssertFalse(ProposalStatus.rejected.isActive)
    }
    
    func testProposalStatusCodable() {
        // Test that ProposalStatus can be encoded and decoded
        let status = ProposalStatus.pending
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(status)
            let decodedStatus = try decoder.decode(ProposalStatus.self, from: data)
            XCTAssertEqual(status, decodedStatus)
        } catch {
            XCTFail("ProposalStatus should be codable: \(error)")
        }
    }
    
    func testProposalStatusAllCases() {
        // Test that all proposal status cases are available
        let allCases = ProposalStatus.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.pending))
        XCTAssertTrue(allCases.contains(.approved))
        XCTAssertTrue(allCases.contains(.rejected))
    }
    
    func testShopProposalCodable() {
        // Test that ShopProposal can be encoded and decoded
        let originalProposal = ShopProposal(
            id: 1,
            userId: 100,
            name: "Codable Proposal",
            address: "Test address",
            genre: .cafe,
            description: "Test description",
            status: .approved,
            adminNotes: "Approved by admin"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(originalProposal)
            let decodedProposal = try decoder.decode(ShopProposal.self, from: data)
            
            XCTAssertEqual(originalProposal.id, decodedProposal.id)
            XCTAssertEqual(originalProposal.userId, decodedProposal.userId)
            XCTAssertEqual(originalProposal.name, decodedProposal.name)
            XCTAssertEqual(originalProposal.address, decodedProposal.address)
            XCTAssertEqual(originalProposal.genre, decodedProposal.genre)
            XCTAssertEqual(originalProposal.description, decodedProposal.description)
            XCTAssertEqual(originalProposal.status, decodedProposal.status)
            XCTAssertEqual(originalProposal.adminNotes, decodedProposal.adminNotes)
        } catch {
            XCTFail("ShopProposal should be codable: \(error)")
        }
    }
    
    func testShopProposalEquatable() {
        // Test that ShopProposal conforms to Equatable
        let proposal1 = ShopProposal(
            id: 1,
            userId: 100,
            name: "Test Proposal",
            status: .pending
        )
        
        let proposal2 = ShopProposal(
            id: 1,
            userId: 100,
            name: "Test Proposal",
            status: .pending
        )
        
        let proposal3 = ShopProposal(
            id: 2,
            userId: 200,
            name: "Different Proposal",
            status: .approved
        )
        
        XCTAssertEqual(proposal1, proposal2)
        XCTAssertNotEqual(proposal1, proposal3)
    }
}