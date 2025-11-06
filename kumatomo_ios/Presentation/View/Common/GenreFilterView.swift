import SwiftUI

struct GenreFilterView: View {
    let selectedGenres: Set<ShopGenre>
    let onGenreToggled: (ShopGenre) -> Void
    let onClearAll: () -> Void

    private let allGenres = ShopGenre.allGenres

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ジャンルで絞り込み")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                if !selectedGenres.isEmpty {
                    Button("クリア", action: onClearAll)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryOrange)
                        .accessibilityIdentifier("ClearGenresButton")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(allGenres, id: \.self) { genre in
                        GenreChip(
                            genre: genre,
                            isSelected: selectedGenres.contains(genre),
                            onTap: { onGenreToggled(genre) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .accessibilityIdentifier("GenreChipsScrollView")
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4)),
            alignment: .bottom
        )
        .accessibilityIdentifier("GenreFilterView")
    }
}

#Preview {
    VStack {
        GenreFilterView(
            selectedGenres: [.cafe, .restaurant],
            onGenreToggled: { genre in
                print("Toggled genre: \(genre.displayName)")
            },
            onClearAll: {
                print("Clear all genres")
            }
        )

        Spacer()
    }
}