import SwiftUI

struct GenreChip: View {
    let genre: ShopGenre
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Text(genre.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primaryOrange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.primaryOrange : Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.primaryOrange : Color.clear, lineWidth: 1)
                        )
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityIdentifier("GenreChip_\(genre.rawValue)")
        .accessibilityLabel(genre.displayName)
        .accessibilityHint(isSelected ? "選択中のジャンル。タップして選択解除" : "タップして選択")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "選択中" : "未選択")
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("GenreChip Preview")
            .font(.headline)
            .padding()

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                GenreChip(genre: .cafe, isSelected: true) {
                    print("Cafe selected")
                }

                GenreChip(genre: .ramen, isSelected: false) {
                    print("Ramen selected")
                }

                GenreChip(genre: .restaurant, isSelected: true) {
                    print("Restaurant selected")
                }

                GenreChip(genre: .izakaya, isSelected: false) {
                    print("Izakaya selected")
                }

                GenreChip(genre: .sweets, isSelected: false) {
                    print("Sweets selected")
                }
            }
            .padding(.horizontal, 16)
        }

        Spacer()
    }
}