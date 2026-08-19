import SwiftUI

// MARK: - ProfileProgressIndicator

struct ProfileProgressIndicator: View {
    let progress: Double
    let isUploading: Bool
    let uploadType: String
    let onCancel: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.lightOrange, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            VStack(spacing: 4) {
                Text(isUploading ? "\(uploadType)をアップロード中..." : "処理中...")
                    .font(.headline)
                    .foregroundColor(.primary)

                if isUploading {
                    Text("しばらくお待ちください")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let onCancel {
                Button("キャンセル") {
                    onCancel()
                }
                .foregroundColor(.red)
                .font(.system(size: 16, weight: .medium))
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - ImageUploadProgressView

struct ImageUploadProgressView: View {
    @Bindable var viewModel: ProfileViewModel
    let imageType: ImageUploadType

    enum ImageUploadType {
        case profile
        case cover

        var displayName: String {
            switch self {
            case .profile:
                return "プロフィール画像"
            case .cover:
                return "カバー画像"
            }
        }

        var progress: Double {
            return 0.0
        }

        var isUploading: Bool {
            return false
        }
    }

    var body: some View {
        if imageType.isUploading {
            ProfileProgressIndicator(
                progress: imageType.progress,
                isUploading: true,
                uploadType: imageType.displayName,
                onCancel: {
                    switch imageType {
                    case .profile:
                        viewModel.cancelProfileImageUpload()
                    case .cover:
                        viewModel.cancelCoverImageUpload()
                    }
                }
            )
        }
    }
}

// MARK: - ProfileSuccessIndicator

struct ProfileSuccessIndicator: View {
    let message: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            .scaleEffect(scale)

            VStack(spacing: 8) {
                Text("保存完了")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(opacity)

            Button("OK") {
                onDismiss()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.green, in: Capsule())
            .opacity(opacity)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - ValidationErrorView

struct ValidationErrorView: View {
    let errors: [String]
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.lightOrange)

                Text("入力エラー")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(errors, id: \.self) { error in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(error)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
            }

            Button("修正する") {
                onDismiss()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.lightOrange, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - ProfileLoadingOverlay

struct ProfileLoadingOverlay: View {
    let isLoading: Bool
    let message: String

    var body: some View {
        if isLoading {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text(message)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: isLoading)
        }
    }
}

#if DEBUG
struct ProfileProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            ProfileProgressIndicator(
                progress: 0.65,
                isUploading: true,
                uploadType: "プロフィール画像",
                onCancel: {}
            )

            ProfileSuccessIndicator(
                message: "プロフィールが正常に更新されました",
                onDismiss: {}
            )

            ValidationErrorView(
                errors: [
                    "名前を入力してください",
                    "メールアドレスの形式が正しくありません",
                    "ユーザーネームは3文字以上で入力してください"
                ],
                onDismiss: {}
            )
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
#endif
