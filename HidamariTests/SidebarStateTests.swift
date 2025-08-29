import XCTest
import SwiftUI
@testable import Hidamari

@MainActor
final class SidebarStateTests: XCTestCase {
    
    var sidebarState: SidebarState!
    
    override func setUp() {
        super.setUp()
        sidebarState = SidebarState()
    }
    
    override func tearDown() {
        sidebarState = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        // Given: A new SidebarState instance
        // When: Checking initial state
        // Then: Sidebar should be closed initially
        XCTAssertFalse(sidebarState.isPresented, "Sidebar should be closed initially")
    }
    
    // MARK: - Open Animation Tests (Requirement 3.1)
    
    func testOpenSidebar() {
        // Given: Sidebar is closed
        XCTAssertFalse(sidebarState.isPresented)
        
        // When: Opening sidebar
        sidebarState.open()
        
        // Then: Sidebar should be presented
        XCTAssertTrue(sidebarState.isPresented, "Sidebar should be open after calling open()")
    }
    
    func testOpenSidebarAnimation() {
        // Given: Sidebar is closed
        let expectation = XCTestExpectation(description: "Sidebar open animation")
        
        // When: Opening sidebar with animation
        sidebarState.open()
        
        // Then: Animation should complete and sidebar should be open
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.sidebarState.isPresented, "Sidebar should be open after animation")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Close Animation Tests (Requirement 3.2)
    
    func testCloseSidebar() {
        // Given: Sidebar is open
        sidebarState.open()
        XCTAssertTrue(sidebarState.isPresented)
        
        // When: Closing sidebar
        sidebarState.close()
        
        // Then: Sidebar should be closed
        XCTAssertFalse(sidebarState.isPresented, "Sidebar should be closed after calling close()")
    }
    
    func testCloseSidebarAnimation() {
        // Given: Sidebar is open
        sidebarState.open()
        let expectation = XCTestExpectation(description: "Sidebar close animation")
        
        // When: Closing sidebar with animation
        sidebarState.close()
        
        // Then: Animation should complete and sidebar should be closed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.sidebarState.isPresented, "Sidebar should be closed after animation")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Toggle Functionality Tests
    
    func testToggleFromClosed() {
        // Given: Sidebar is closed
        XCTAssertFalse(sidebarState.isPresented)
        
        // When: Toggling sidebar
        sidebarState.toggle()
        
        // Then: Sidebar should be open
        XCTAssertTrue(sidebarState.isPresented, "Sidebar should be open after toggle from closed state")
    }
    
    func testToggleFromOpen() {
        // Given: Sidebar is open
        sidebarState.open()
        XCTAssertTrue(sidebarState.isPresented)
        
        // When: Toggling sidebar
        sidebarState.toggle()
        
        // Then: Sidebar should be closed
        XCTAssertFalse(sidebarState.isPresented, "Sidebar should be closed after toggle from open state")
    }
    
    // MARK: - State Consistency Tests
    
    func testMultipleOpenCalls() {
        // Given: Sidebar is closed
        XCTAssertFalse(sidebarState.isPresented)
        
        // When: Calling open multiple times
        sidebarState.open()
        sidebarState.open()
        sidebarState.open()
        
        // Then: Sidebar should remain open
        XCTAssertTrue(sidebarState.isPresented, "Sidebar should remain open after multiple open calls")
    }
    
    func testMultipleCloseCalls() {
        // Given: Sidebar is open
        sidebarState.open()
        XCTAssertTrue(sidebarState.isPresented)
        
        // When: Calling close multiple times
        sidebarState.close()
        sidebarState.close()
        sidebarState.close()
        
        // Then: Sidebar should remain closed
        XCTAssertFalse(sidebarState.isPresented, "Sidebar should remain closed after multiple close calls")
    }
}