import SwiftUI

struct ShopProposalStatusView: View {
    @State private var viewModel = ShopProposalStatusViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage {
                        ProposalErrorView(message: errorMessage) {
                            Task {
                                await viewModel.loadProposalStatus()
                            }
                        }
                    } else {
                        SummaryCardsView(summary: viewModel.summary)

                        if !viewModel.proposals.isEmpty {
                            ProposalsListView(
                                proposals: viewModel.proposals,
                                onDelete: { proposal in
                                    Task {
                                        await viewModel.deleteProposal(proposal)
                                    }
                                }
                            )
                        } else {
                            EmptyProposalsView()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("提案状況")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.loadProposalStatus()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.loadProposalStatus()
            }
            .alert("削除完了", isPresented: $viewModel.showingDeleteSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("提案が正常に削除されました。")
            }
            .alert("エラー", isPresented: $viewModel.showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.alertErrorMessage)
            }
        }
        .task {
            await viewModel.loadProposalStatus()
        }
    }
}

struct SummaryCardsView: View {
    let summary: ProposalSummary?

    var body: some View {
        if let summary = summary {
            VStack(spacing: 12) {
                Text("提案状況")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    SummaryCard(
                        title: "承認待ち",
                        count: summary.pending,
                        color: .orange,
                        icon: "clock.fill"
                    )

                    SummaryCard(
                        title: "承認済み",
                        count: summary.approved,
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )

                    SummaryCard(
                        title: "却下",
                        count: summary.rejected,
                        color: .red,
                        icon: "xmark.circle.fill"
                    )
                }
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))

                Spacer()

                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProposalsListView: View {
    let proposals: [ShopProposal]
    let onDelete: (ShopProposal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("提案履歴")
                .font(.headline)

            LazyVStack(spacing: 12) {
                ForEach(proposals) { proposal in
                    ProposalCardView(
                        proposal: proposal,
                        onDelete: { onDelete(proposal) }
                    )
                }
            }
        }
    }
}

struct ProposalCardView: View {
    let proposal: ShopProposal
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(DateFormatter.proposalDate.string(from: proposal.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: proposal.status)
            }

            if let address = proposal.address {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if let genre = proposal.genre {
                Text(genre.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(genre.color.opacity(0.1))
                    .foregroundColor(genre.color)
                    .cornerRadius(6)
            }

            if let description = proposal.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if proposal.status == .rejected, let adminNotes = proposal.adminNotes {
                VStack(alignment: .leading, spacing: 4) {
                    Text("却下理由:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    Text(adminNotes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            if proposal.status == .pending {
                HStack {
                    Spacer()

                    Button("削除", action: {
                        showingDeleteAlert = true
                    })
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .alert("提案を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                onDelete()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この提案を削除してもよろしいですか？この操作は取り消せません。")
        }
    }
}

struct StatusBadge: View {
    let status: ProposalStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch status {
        case .pending:
            return .orange.opacity(0.2)
        case .approved:
            return .green.opacity(0.2)
        case .rejected:
            return .red.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
}

struct EmptyProposalsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("提案履歴がありません")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("新しい店舗を提案して、地域のお店情報を充実させましょう！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }
}

struct ProposalErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("エラーが発生しました")
                .font(.headline)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("再試行", action: onRetry)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.primaryOrange)
                .cornerRadius(8)
        }
        .padding(.vertical, 40)
    }
}

@MainActor
@Observable
class ShopProposalStatusViewModel {
    var proposals: [ShopProposal] = []
    var summary: ProposalSummary?
    var isLoading = false
    var errorMessage: String?
    var showingDeleteSuccessAlert = false
    var showingErrorAlert = false
    var alertErrorMessage = ""

    private let shopAPIService = ShopAPIService.shared

    func loadProposalStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await shopAPIService.fetchProposalStatus()
            proposals = response.data
            summary = response.summary
        } catch {
            errorMessage = "提案状況の読み込み中にエラーが発生しました。"
        }

        isLoading = false
    }

    func deleteProposal(_ proposal: ShopProposal) async {
        do {
            try await shopAPIService.deleteShopProposal(id: proposal.id)

            proposals.removeAll { $0.id == proposal.id }

            if let currentSummary = summary {
                summary = ProposalSummary(
                    pending: max(0, currentSummary.pending - 1),
                    approved: currentSummary.approved,
                    rejected: currentSummary.rejected
                )
            }

            showingDeleteSuccessAlert = true

        } catch {
            alertErrorMessage = "提案の削除中にエラーが発生しました。"
            showingErrorAlert = true
        }
    }
}

extension DateFormatter {
    static let proposalDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

struct ShopProposalStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ShopProposalStatusView()
    }
}
