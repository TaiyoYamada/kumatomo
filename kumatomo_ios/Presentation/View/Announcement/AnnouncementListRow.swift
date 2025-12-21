import SwiftUI

struct AnnouncementListRow: View {
    let announcement: Announcement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                if let date = announcement.publishedAt {
                    Text(date.formatted(date: .numeric, time: .omitted))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(6)
                }

                Spacer()

                if announcement.priority > 0 {
                    Text("重要")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(4)
                }
            }

            Text(announcement.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(announcement.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}
