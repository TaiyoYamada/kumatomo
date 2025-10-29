import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Scroll Offset Reader

struct ScrollOffsetReader<Content: View>: View {
    let coordinateSpace: String
    let onOffsetChange: (CGFloat) -> Void
    let content: () -> Content
    
    init(
        coordinateSpace: String = "scroll",
        onOffsetChange: @escaping (CGFloat) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.coordinateSpace = coordinateSpace
        self.onOffsetChange = onOffsetChange
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            content()
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named(coordinateSpace)).minY
                            )
                    }
                )
        }
        .coordinateSpace(name: coordinateSpace)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            onOffsetChange(offset)
        }
    }
}

// MARK: - Scroll Offset Modifier

extension View {
    func onScrollOffsetChange(
        coordinateSpace: String = "scroll",
        perform action: @escaping (CGFloat) -> Void
    ) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named(coordinateSpace)).minY
                    )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: action)
    }
}