import SwiftUI

struct AnnouncementListView: View {
    let announcements: [Announcement]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if announcements.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("お知らせはありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(announcements) { announcement in
                        NavigationLink(value: RouterDestination.announcementDetail(announcement: announcement)) {
                            AnnouncementListRow(announcement: announcement)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())

                        if announcement.id != announcements.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("お知らせ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.lightOrangeColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
