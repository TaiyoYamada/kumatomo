import SwiftUI

struct RegionalTagSelectionView: View {
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    @Environment(\.dismiss) private var dismiss
    
    // Regional tags (Kumamoto) using shared Municipality enum
    private var regionalTags: [String] {
        ["熊本県全体"] + Municipality.allCases.map { $0.displayName }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
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
                    .foregroundColor(.orange)
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
                
                // Selected tags count
                HStack {
                    Text("選択中: \(selectedTags.count)個")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if selectedTags.count >= 5 {
                        Text("最大5個まで選択可能")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Tag list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(regionalTags, id: \.self) { tag in
                            RegionalTagRow(
                                tag: tag,
                                isSelected: selectedTags.contains(tag),
                                canSelect: selectedTags.count < 5 || selectedTags.contains(tag),
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
            // Prevent removing last tag - minimum 1 tag required
            if selectedTags.count > 1 {
                selectedTags.remove(tag)
            }
        } else {
            // Prevent selecting more than 5 tags
            if selectedTags.count < 5 {
                selectedTags.insert(tag)
            }
        }
    }
}

// MARK: - Regional Tag Row
private struct RegionalTagRow: View {
    let tag: String
    let isSelected: Bool
    let canSelect: Bool
    let canDeselect: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            if isSelected && canDeselect {
                onTap()
            } else if !isSelected && canSelect {
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.orange : Color.gray.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Tag name
                Text(tag)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Status indicator
                if isSelected && !canDeselect {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if !isSelected && !canSelect {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
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
