import XCTest
@testable import kumatomo

final class ProposalStatusResponseTests: XCTestCase {
    
    func testProposalSummaryProperties() {
        let summary = ProposalSummary(pending: 2, approved: 1, rejected: 1)
        
        XCTAssertEqual(summary.pending, 2)
        XCTAssertEqual(summary.approved, 1)
        XCTAssertEqual(summary.rejected, 1)
        XCTAssertEqual(summary.total, 4)
        XCTAssertTrue(summary.hasPendingProposals)
        XCTAssertTrue(summary.hasApprovedProposals)
        XCTAssertTrue(summary.hasRejectedProposals)
    }
    
    func testProposalSummaryEmptyState() {
        let summary = ProposalSummary(pending: 0, approved: 0, rejected: 0)
        
        XCTAssertEqual(summary.total, 0)
        XCTAssertFalse(summary.hasPendingProposals)
        XCTAssertFalse(summary.hasApprovedProposals)
        XCTAssertFalse(summary.hasRejectedProposals)
    }
    
    func testProposalStatusResponseDecoding() {
        let jsonData = """
        {
            "data": [
                {
                    "id": 1,
                    "user_id": 123,
                    "name": "テスト店舗1",
                    "address": "熊本市中央区テスト町1-2-3",
                    "genre": "ラーメン",
                    "description": "美味しいラーメン店です",
                    "status": "pending",
                    "admin_notes": null,
                    "created_at": "2025-09-19T12:00:00.000000Z",
                    "updated_at": "2025-09-19T12:00:00.000000Z"
                },
                {
                    "id": 2,
                    "user_id": 123,
                    "name": "テスト店舗2",
                    "address": null,
                    "genre": null,
                    "description": null,
                    "status": "approved",
                    "admin_notes": "承認しました",
                    "created_at": "2025-09-19T11:00:00.000000Z",
                    "updated_at": "2025-09-19T11:30:00.000000Z"
                }
            ],
            "summary": {
                "pending": 1,
                "approved": 1,
                "rejected": 0
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            let response = try decoder.decode(ProposalStatusResponse.self, from: jsonData)
            
            XCTAssertEqual(response.data.count, 2)
            XCTAssertEqual(response.summary.pending, 1)
            XCTAssertEqual(response.summary.approved, 1)
            XCTAssertEqual(response.summary.rejected, 0)
            XCTAssertEqual(response.summary.total, 2)
            
            // Test first proposal
            let firstProposal = response.data[0]
            XCTAssertEqual(firstProposal.id, 1)
            XCTAssertEqual(firstProposal.name, "テスト店舗1")
            XCTAssertEqual(firstProposal.status, .pending)
            XCTAssertNil(firstProposal.adminNotes)
            
            // Test second proposal
            let secondProposal = response.data[1]
            XCTAssertEqual(secondProposal.id, 2)
            XCTAssertEqual(secondProposal.name, "テスト店舗2")
            XCTAssertEqual(secondProposal.status, .approved)
            XCTAssertEqual(secondProposal.adminNotes, "承認しました")
            XCTAssertNil(secondProposal.address)
            XCTAssertNil(secondProposal.genre)
            XCTAssertNil(secondProposal.description)
            
        } catch {
            XCTFail("Failed to decode ProposalStatusResponse: \(error)")
        }
    }
}