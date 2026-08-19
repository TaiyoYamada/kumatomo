import SwiftUI

// MARK: - ModernProfileInfoView

/// プロフィール情報表示ビュー
/// 名前、ユーザーネーム、bio、位置情報、参加日を表示
struct ModernProfileInfoView: View {
    let user: User

    private func formatJoinDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.name ?? "名前未設定")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    if user.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.lightOrange)
                            .font(.title3)
                    }
                }

                if let username = user.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                } else {
                    Text("@username")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.6))
                        .fontWeight(.medium)
                }
            }

            // バイオ/自己紹介（展開可能）
            if let bio = user.bio, !bio.isEmpty {
                ExpandableBioView(bio: bio)
            }

            VStack(alignment: .leading, spacing: 12) {
                // 出身地情報
                if let location = user.location, !location.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "location")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // 参加日 - より詳細な表示
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 16)

                    Group {
                        if let joinedDate = user.joinedDate, !joinedDate.isEmpty {
                            Text("\(joinedDate)に参加")
                        } else if let createdAt = user.createdAt {
                            Text("\(formatJoinDate(createdAt))に参加")
                        } else {
                            Text("参加日不明")
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
