import SwiftUI

struct TagSelectionView: View {
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    let maxSelection: Int = 5
    let minSelection: Int = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with selection count
            HStack {
                Text("タグを選択")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(selectedTags.count)/\(maxSelection)")
                    .font(.caption)
                    .foregroundColor(selectedTags.count >= maxSelection ? .red : .secondary)
            }
            .padding(.horizontal, 16)
            
            // Scrollable tag collection
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(availableTags, id: \.self) { tag in
                        TagChip(
                            text: tag,
                            isSelected: selectedTags.contains(tag),
                            onTap: { toggleTag(tag) }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Validation message
            if selectedTags.isEmpty {
                Text("最低1つのタグを選択してください")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
            } else if selectedTags.count >= maxSelection {
                Text("最大\(maxSelection)つまで選択できます")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            // Prevent removing the last tag (minimum 1 requirement)
            if selectedTags.count > minSelection {
                selectedTags.remove(tag)
            }
        } else {
            // Prevent selecting more than maximum allowed tags
            if selectedTags.count < maxSelection {
                selectedTags.insert(tag)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTags: Set<String> = ["熊本県全体"]
    
    let availableTags = [
        "熊本県全体", "熊本市", "八代市", "人吉市", "荒尾市",
        "水俣市", "玉名市", "山鹿市", "菊池市", "宇土市",
        "上天草市", "宇城市", "阿蘇市", "天草市", "合志市"
    ]
    
    return VStack(spacing: 20) {
        Text("TagSelectionView Preview")
            .font(.headline)
            .padding()
        
        TagSelectionView(
            selectedTags: $selectedTags,
            availableTags: availableTags
        )
        
        // Debug info
        VStack(alignment: .leading, spacing: 4) {
            Text("Selected Tags:")
                .font(.caption)
                .fontWeight(.bold)
            
            ForEach(Array(selectedTags), id: \.self) { tag in
                Text("• \(tag)")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
        
        Spacer()
    }
}