import Foundation
import SwiftUI

@MainActor
final class SidebarState: ObservableObject {
    
    @Published var isPresented: Bool = false
    
    func open() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            isPresented = true
        }
    }
    
    func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            isPresented = false
        }
    }
    
    func toggle() {
        if isPresented {
            close()
        } else {
            open()
        }
    }
}
