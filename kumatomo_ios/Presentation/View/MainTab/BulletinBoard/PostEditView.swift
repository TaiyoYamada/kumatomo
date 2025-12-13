import SwiftUI
import Observation

struct PostEditView: View {
    @Bindable var viewModel: PostViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sheetDestination: SheetDestination?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ContentEditCard(
                            content: $viewModel.postContent,
                            characterCount: viewModel.postContent.count
                        )

                        TagsEditCard(
                            tags: $viewModel.tags,
                            tagInput: $viewModel.tagInput,
                            onAddTag: {
                                let result = viewModel.addTag()
                                if case .failure(let error) = result {
                                    viewModel.errorMessage = error.localizedDescription
                                }
                            },
                            onRemoveTag: viewModel.removeTag
                        )

                        ImageEditNote()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("投稿を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    UpdateButton(
                        isEnabled: canUpdate,
                        isLoading: viewModel.isUpdating
                    ) {
                        handleUpdate()
                    }
                }
            }
        }
        .overlay {
            OverlayContent(viewModel: viewModel) {
                dismiss()
            }
        }
        .withSheetRouter(sheet: $sheetDestination)
    }
}

private extension PostEditView {
    var canUpdate: Bool {
        !viewModel.postContent.isEmpty &&
        viewModel.postContent.count <= 300 &&
        !viewModel.isUpdating
    }
}

private extension PostEditView {
    func handleUpdate() {
        Task {
            let success = await viewModel.updatePost()
            if success {
                dismiss()
            }
        }
    }
}

private struct ContentEditCard: View {
    @Binding var content: String
    let characterCount: Int

    private var isOverLimit: Bool {
        characterCount > 300
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("投稿内容")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer()

                Text("必須")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
            }

            TextEditor(text: $content)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.secondarySystemBackground))
                .frame(minHeight: 120)
                .cornerRadius(12)
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 1,
                    y: 1
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isOverLimit ? Color.red : Color.clear, lineWidth: 1)
                )

            CharacterCounter(
                count: characterCount,
                maxCount: 300,
                isOverLimit: isOverLimit
            )
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: .black.opacity(0.05),
            radius: 2,
            y: 1
        )
    }
}

private struct TagsEditCard: View {
    @Binding var tags: [String]
    @Binding var tagInput: String
    let onAddTag: () -> Void
    let onRemoveTag: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("タグ")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer()

                Text("任意")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary)
                    .cornerRadius(4)
            }

            HStack {
                TextField("タグを入力", text: $tagInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        onAddTag()
                    }

                Button("追加") {
                    onAddTag()
                }
                .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || tags.count >= 5)
            }

            if !tags.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundStyle(.orange)

                            Spacer()

                            Button(action: { onRemoveTag(tag) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }

            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("最大5個まで追加できます (\(tags.count)/5)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: .black.opacity(0.05),
            radius: 2,
            y: 1
        )
    }
}

private struct ImageEditNote: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(.orange)

                Text("画像について")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }

            Text("現在、投稿の編集では画像の変更はできません。画像を変更したい場合は、投稿を削除して新しく作成してください。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct CharacterCounter: View {
    let count: Int
    let maxCount: Int
    let isOverLimit: Bool

    var body: some View {
        HStack {
            if isOverLimit {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.red)

                Text("文字数制限を超えています")
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }

            Spacer()

            Text("\(count)/\(maxCount)")
                .font(.caption)
                .foregroundStyle(isOverLimit ? Color.red : Color.secondary)
                .animation(.easeInOut(duration: 0.3), value: isOverLimit)
        }
    }
}

private struct UpdateButton: View {
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button("更新", action: action)
            .disabled(!isEnabled)
            .foregroundStyle(isEnabled ? Color.orange : Color.secondary)
            .opacity(isLoading ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isEnabled)
            .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

private struct OverlayContent: View {
    @Bindable var viewModel: PostViewModel
    let onDismiss: () -> Void

    var body: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                ErrorOverlay(
                    message: errorMessage,
                    onClose: {
                        viewModel.errorMessage = nil
                    }
                )
            }

            if viewModel.showSuccessModal {
                SuccessOverlay(onDismiss: onDismiss)
            }

            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
}

private struct ErrorOverlay: View {
    let message: String
    let onClose: () -> Void

    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.red)

                    Text(message)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("閉じる") {
                        onClose()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.red)
                }
                .padding(30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                .padding(.horizontal, 40)
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: message)
    }
}

private struct SuccessOverlay: View {
    let onDismiss: () -> Void
    @State private var checkmarkScale: CGFloat = 0

    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.green)
                            .scaleEffect(checkmarkScale)
                    }

                    VStack(spacing: 8) {
                        Text("更新しました！")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("変更が反映されました")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                .padding(.horizontal, 40)
            }
            .onAppear {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30).delay(0.1)) {
                    checkmarkScale = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onDismiss()
                }
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
    }
}

private struct LoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)

                    Text("更新中...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: true)
    }
}
