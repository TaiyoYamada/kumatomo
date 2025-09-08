import Foundation
import SwiftUI

/// Centralized state management for sidebar presentation and animations
@MainActor
final class SidebarState: ObservableObject {
    /// Published property indicating whether the sidebar is currently presented
    @Published var isPresented: Bool = false
    
    /// Opens the sidebar with smooth spring animation
    func open() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            isPresented = true
        }
    }
    
    /// Closes the sidebar with smooth spring animation
    func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            isPresented = false
        }
    }
    
    /// Toggles the sidebar state with animation
    func toggle() {
        if isPresented {
            close()
        } else {
            open()
        }
    }
}