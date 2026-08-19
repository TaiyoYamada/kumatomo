import SwiftUI

// MARK: - RegionalTagSelectionView

struct RegionalTagSelectionView: View {
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    @Environment(\.dismiss) private var dismiss

    private var regionalTags: [String] {
        City.allCases.map(\.displayName)
    }

    private var visibleSelectedCount: Int {
        selectedTags.filter { $0 != "熊本県全体" }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.primary)

                    Spacer()

                    Text("地域タグを選択")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(.lightOrange)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(UIColor.separator)),
                    alignment: .bottom
                )

                HStack {
                    Text("選択中: \(visibleSelectedCount)個")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if visibleSelectedCount >= 5 {
                        Text("最大5個まで選択可能")
                            .font(.caption)
                            .foregroundColor(.lightOrange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(regionalTags, id: \.self) { tag in
                            RegionalTagRow(
                                tag: tag,
                                isSelected: selectedTags.contains(tag),
                                canSelect: visibleSelectedCount < 5 || selectedTags.contains(tag),
                                canDeselect: selectedTags.count > 1 || !selectedTags.contains(tag)
                            ) {
                                toggleTag(tag)
                            }
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            if selectedTags.count > 1 {
                selectedTags.remove(tag)
            }
        } else {
            if selectedTags.filter({ $0 != "熊本県全体" }).count < 5 {
                selectedTags.insert(tag)
            }
        }
    }
}

// MARK: - RegionalTagRow

private struct RegionalTagRow: View {
    let tag: String
    let isSelected: Bool
    let canSelect: Bool
    let canDeselect: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            if isSelected, canDeselect {
                onTap()
            } else if !isSelected, canSelect {
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.lightOrange : Color.gray.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(Color.lightOrange)
                            .frame(width: 12, height: 12)
                    }
                }

                Text(tag)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected, !canDeselect {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if !isSelected, !canSelect {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.lightOrange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(UIColor.separator)),
                alignment: .bottom
            )
        }
        .disabled((!isSelected && !canSelect) || (isSelected && !canDeselect))
        .opacity((!isSelected && !canSelect) || (isSelected && !canDeselect) ? 0.6 : 1.0)
    }
}
