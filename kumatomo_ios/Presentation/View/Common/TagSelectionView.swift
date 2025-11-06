import SwiftUI

private enum TagSelectionState: Equatable {
    case noTagsSelected
    case maxTagsReached
    case valid
}

struct TagSelectionView: View {
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    let maxSelection: Int = 5
    let minSelection: Int = 1

    private var validationState: TagSelectionState {
        if selectedTags.isEmpty {
            return .noTagsSelected
        } else if selectedTags.count >= maxSelection {
            return .maxTagsReached
        } else {
            return .valid
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            validationState == .noTagsSelected ? Color.red.opacity(0.3) :
                            validationState == .maxTagsReached ? Color.orange.opacity(0.3) :
                            Color.clear,
                            lineWidth: validationState == .valid ? 0 : 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: validationState)
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            if selectedTags.count > minSelection {
                selectedTags.remove(tag)
            }
        } else {
            if selectedTags.count < maxSelection {
                selectedTags.insert(tag)
            }
        }
    }
}

private struct EnhancedTagChip: View {
    let text: String
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ? Color.primaryOrange :
                        isDisabled ? Color.gray.opacity(0.1) :
                        Color(UIColor.systemBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.primaryOrange :
                                isDisabled ? Color.gray.opacity(0.3) :
                                Color.primaryOrange,
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(
                isSelected ? .white :
                isDisabled ? .gray :
                .primaryOrange
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

private struct TagValidationFeedback: View {
    let validationState: TagSelectionState
    let selectedCount: Int
    let maxCount: Int

    var body: some View {
        Group {
            switch validationState {
            case .noTagsSelected:
                ValidationMessage(
                    icon: "exclamationmark.triangle.fill",
                    message: "最低1つのタグを選択してください",
                    suggestion: "投稿に関連するタグを選択してください",
                    color: .red
                )

            case .maxTagsReached:
                ValidationMessage(
                    icon: "exclamationmark.triangle",
                    message: "最大\(maxCount)つまで選択できます",
                    suggestion: "不要なタグを削除してから新しいタグを選択してください",
                    color: .orange
                )

            case .valid:
                ValidationMessage(
                    icon: "checkmark.circle.fill",
                    message: "タグの選択が完了しました",
                    suggestion: "必要に応じて追加のタグを選択できます（最大\(maxCount)つまで）",
                    color: .green
                )
            }
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.easeInOut(duration: 0.2), value: validationState)
    }
}

private struct ValidationMessage: View {
    let icon: String
    let message: String
    let suggestion: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)

                Text(suggestion)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(6)
    }
}

#Preview {
    @Previewable @State var selectedTags: Set<String> = ["熊本県全体"]

    let availableTags = ["熊本県全体"] + City.allCases.map { $0.displayName }

    return VStack(spacing: 20) {
        Text("TagSelectionView Preview")
            .font(.headline)
            .padding()

        TagSelectionView(
            selectedTags: $selectedTags,
            availableTags: availableTags
        )

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
