import SwiftUI

struct RegionalTagSelectionView: View {
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    @Environment(\.dismiss) private var dismiss
    
    // Regional tags specific to Kumamoto
    private let regionalTags = [
        "熊本県全体", "熊本市中央区", "熊本市東区", "熊本市西区", "熊本市南区", "熊本市北区",
        "八代市", "人吉市", "荒尾市", "水俣市", "玉名市", "山鹿市", "菊池市", "宇土市",
        "上天草市", "宇城市", "阿蘇市", "天草市", "合志市", "美里町", "玉東町", "南関町",
        "長洲町", "和水町", "大津町", "菊陽町", "南小国町", "小国町", "産山村", "高森町",
        "西原村", "南阿蘇村", "御船町", "嘉島町", "益城町", "甲佐町", "山都町", "氷川町",
        "芦北町", "津奈木町", "錦町", "多良木町", "湯前町", "水上村", "相良村", "五木村",
        "山江村", "球磨村", "あさぎり町", "苓北町"
    ]
    
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
                    .foregroundColor(.blue)
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
                            isSelected ? Color.blue : Color.gray.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
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
