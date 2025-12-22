import SwiftUI

struct TagChip: View {
    let text: String
    let isSelected: Bool
    let onTap: (() -> Void)?

    @State private var isPressed = false

    init(text: String, isSelected: Bool = false, onTap: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.onTap = onTap
    }

    init(text: String) {
        self.text = text
        isSelected = false
        onTap = nil
    }

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    tagContent
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                }, perform: {})
                .accessibilityLabel(text)
                .accessibilityHint(isSelected ? "選択中のタグ。タップして選択解除" : "タップして選択")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            } else {
                tagContent
                    .accessibilityLabel("タグ: \(text)")
            }
        }
    }

    private var tagContent: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.primaryOrange : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primaryOrange, lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? .white : .primaryOrange)
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("TagChip Preview")
            .font(.headline)
            .padding()

        HStack(spacing: 8) {
            TagChip(text: "熊本県全体", isSelected: true) {
                print("Selected tag tapped")
            }

            TagChip(text: "熊本市", isSelected: false) {
                print("Unselected tag tapped")
            }

            TagChip(text: "八代市", isSelected: false) {
                print("Another unselected tag tapped")
            }
        }

        HStack(spacing: 8) {
            TagChip(text: "人吉市", isSelected: true) {
                print("Another selected tag tapped")
            }

            TagChip(text: "荒尾市", isSelected: false) {
                print("Tag tapped")
            }
        }

        Spacer()
    }
    .padding()
}
