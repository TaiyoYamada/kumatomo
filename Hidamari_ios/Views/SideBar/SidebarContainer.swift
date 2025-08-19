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
                    .overlay(
                        Group {
                            if isPresented {
                                Color.black
                                    .opacity(overlayOpacity)
                                    .ignoresSafeArea()
                                    .onTapGesture { closeSidebar() }
                                    .accessibilityIdentifier("sidebar_overlay")
                            }
                        }
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("overlay_content")
                
                // Sidebar panel with proper safe area handling
                SidebarPanel(user: user, onClose: closeSidebar)
                    .frame(width: sidebarWidth)
                    .background(Color(UIColor.systemBackground))
                    .offset(x: isPresented ? 0 : (dragOffsetX > 0 ? -sidebarWidth + dragOffsetX : -sidebarWidth))
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 2, y: 0)
                    .accessibilityIdentifier("twitter_sidebar_panel")
            }
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .global)
                    .onChanged { value in
                        let startX = value.startLocation.x
                        let translationX = value.translation.width
                        
                        if isPresented {
                            // Only allow closing gesture
                            if translationX < 0 {
                                dragOffsetX = max(-sidebarWidth, translationX)
                            }
                        } else {
                            // Only allow opening gesture from left edge
                            if startX < 24 && translationX > 0 {
                                dragOffsetX = min(translationX, sidebarWidth)
                            }
                        }
                    }
                    .onEnded { value in
                        let translationX = value.translation.width
                        let threshold = sidebarWidth * 0.3
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
                            if isPresented {
                                if translationX < -threshold {
                                    closeSidebar()
                                } else {
                                    openSidebar()
                                }
                            } else {
                                if translationX > threshold {
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
