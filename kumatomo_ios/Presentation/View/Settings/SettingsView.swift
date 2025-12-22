import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CurrentUserManager.self) private var userManager

    @State private var showChangeEmail = false
    @State private var showChangePassword = false
    @State private var showDeleteAccount = false

    var body: some View {
        List {
            // MARK: - アカウント設定セクション

            Section {
                NavigationLink {
                    ChangeEmailView()
                        .environment(userManager)
                } label: {
                    SettingsRow(
                        icon: "envelope.fill",
                        iconColor: .blue,
                        title: "メールアドレス変更"
                    )
                }

                NavigationLink {
                    ChangePasswordView()
                } label: {
                    SettingsRow(
                        icon: "lock.fill",
                        iconColor: .green,
                        title: "パスワード変更"
                    )
                }
            } header: {
                Text("アカウント設定")
            }

            // MARK: - アプリ情報セクション

            Section {
                HStack {
                    SettingsRow(
                        icon: "info.circle.fill",
                        iconColor: .gray,
                        title: "バージョン"
                    )
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }

                Button {
                    openURL("https://example.com/terms")
                } label: {
                    HStack {
                        SettingsRow(
                            icon: "doc.text.fill",
                            iconColor: .orange,
                            title: "利用規約"
                        )
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    openURL("https://example.com/privacy")
                } label: {
                    HStack {
                        SettingsRow(
                            icon: "hand.raised.fill",
                            iconColor: .purple,
                            title: "プライバシーポリシー"
                        )
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("アプリ情報")
            }

            // MARK: - 危険ゾーンセクション

            Section {
                NavigationLink {
                    DeleteAccountView()
                        .environment(userManager)
                } label: {
                    SettingsRow(
                        icon: "trash.fill",
                        iconColor: .red,
                        title: "アカウント削除"
                    )
                }
            } header: {
                Text("危険ゾーン")
            } footer: {
                Text("アカウントを削除すると、すべてのデータが完全に削除され、復元できません。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .environment(CurrentUserManager.shared)
    }
}
