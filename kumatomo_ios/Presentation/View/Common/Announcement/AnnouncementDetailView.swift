import SwiftUI

struct AnnouncementDetailView: View {
    let announcement: Announcement

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Group
                VStack(alignment: .leading, spacing: 16) {
                    if let date = announcement.publishedAt {
                        Text(date.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    Text(announcement.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                }

                Divider()

                // Content
                Text(announcement.content)
                    .font(.body)
                    .lineSpacing(8)
                    .foregroundColor(.primary.opacity(0.9))
            }
            .padding(24)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.lightOrange, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        AnnouncementDetailView(announcement: Announcement(
            id: 1,
            title: "サービスメンテナンスのお知らせ",
            content: "平素より当サービスをご利用いただきありがとうございます。\n\n以下の日程でサーバーメンテナンスを実施いたします。\n\n日時：2025年1月1日 2:00 - 4:00\n\nご不便をおかけしますが、ご協力をお願いいたします。",
            publishedAt: Date(),
            isActive: true,
            priority: 1,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
