import SwiftUI
import UIKit

// MARK: - Sidebar Container
struct SidebarContainer<Content: View>: View {
    @Binding var isPresented: Bool
    let user: User?
    let content: () -> Content
    
    @State private var dragOffsetX: CGFloat = 0
    @GestureState private var isDetectingLongPress = false
    
    private let sidebarWidth: CGFloat = 300
    private let overlayOpacity: Double = 0.4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Main content with overlay
                content()
                    .offset(x: dragOffsetX)
                    .disabled(isPresented)
                
                // Full-screen overlay that covers entire screen including tab bar
                if isPresented {
                    Color.black
                        .opacity(overlayOpacity)
                        .ignoresSafeArea(.all) // Cover entire screen including tab bar
                        .onTapGesture { closeSidebar() }
                        .ignoresSafeArea(.all)
                        .zIndex(1) // Ensure overlay is above main content
                }
                
                // Sidebar panel with proper safe area handling
                SidebarPanel(user: user, onClose: closeSidebar)
                    .frame(width: sidebarWidth)
                    .background(Color(UIColor.systemBackground))
                    .offset(x: isPresented ? 0 : (dragOffsetX > 0 ? -sidebarWidth + dragOffsetX : -sidebarWidth))
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 2, y: 0)
                    .ignoresSafeArea(.all)
                    .zIndex(2) // Ensure sidebar is above overlay
            }
            /*.ignoresSafeArea(.all)*/ // Allow container to cover entire screen including tab bar
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .global) // Reduced minimum distance for better responsiveness
                    .onChanged { value in
                        let startX = value.startLocation.x
                        let translationX = value.translation.width
                        let screenWidth = geometry.size.width
                        
                        if isPresented {
                            // Allow closing gesture from anywhere on screen when sidebar is open
                            if translationX < 0 {
                                dragOffsetX = max(-sidebarWidth, translationX)
                            }
                        } else {
                            // Enhanced left edge detection for full-screen interaction
                            // Increase edge detection area for better accessibility
                            let edgeThreshold: CGFloat = 32
                            if startX < edgeThreshold && translationX > 0 {
                                dragOffsetX = min(translationX, sidebarWidth)
                            }
                        }
                    }
                    .onEnded { value in
                        let translationX = value.translation.width
                        let velocity = value.velocity.width
                        
                        // Improved threshold calculation considering velocity for better responsiveness
                        let baseThreshold = sidebarWidth * 0.25 // Reduced threshold for easier interaction
                        let velocityThreshold: CGFloat = 300
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
                            if isPresented {
                                // Close if dragged left beyond threshold or with sufficient velocity
                                if translationX < -baseThreshold || velocity < -velocityThreshold {
                                    closeSidebar()
                                } else {
                                    openSidebar()
                                }
                            } else {
                                // Open if dragged right beyond threshold or with sufficient velocity
                                if translationX > baseThreshold || velocity > velocityThreshold {
                                    openSidebar()
                                } else {
                                    closeSidebar()
                                }
                            }
                        }
                    }
            )
        }
    }
    
    private func openSidebar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            isPresented = true
            dragOffsetX = 0
        }
    }
    
    private func closeSidebar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            isPresented = false
            dragOffsetX = 0
        }
    }
}

// MARK: - Extensions
private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
