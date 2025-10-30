import SwiftUI

struct ShopProposalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ShopProposalFormViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("新しい店舗を提案")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("地域にある素敵なお店を皆さんと共有しませんか？提案いただいた店舗は管理者による確認後、アプリに追加されます。")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Form fields
                    VStack(spacing: 20) {
                        // Shop name field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("店舗名")
                                    .font(.headline)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            
                            TextField("例: 熊本ラーメン 太郎", text: $viewModel.shopName)
                                .textFieldStyle(ProposalTextFieldStyle())
                                .accessibilityIdentifier("ShopNameField")
                        }
                        
                        // Address field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("住所")
                                .font(.headline)
                            
                            TextField("例: 熊本市中央区○○町1-2-3", text: $viewModel.address)
                                .textFieldStyle(ProposalTextFieldStyle())
                                .accessibilityIdentifier("AddressField")
                        }
                        
                        // Genre selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ジャンル")
                                .font(.headline)
                            
                            Menu {
                                Button("選択なし") {
                                    viewModel.selectedGenre = nil
                                }
                                
                                ForEach(ShopGenre.allCases, id: \.self) { genre in
                                    Button(genre.displayName) {
                                        viewModel.selectedGenre = genre
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedGenre?.displayName ?? "ジャンルを選択")
                                        .foregroundColor(viewModel.selectedGenre != nil ? .primary : .secondary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .accessibilityIdentifier("GenreSelector")
                        }
                        
                        // Description field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("説明・おすすめポイント")
                                .font(.headline)
                            
                            Text("この店舗の魅力や特徴を教えてください（任意）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $viewModel.description)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .accessibilityIdentifier("DescriptionField")
                        }
                        
                        // Character count for description
                        HStack {
                            Spacer()
                            Text("\(viewModel.description.count)/1000")
                                .font(.caption)
                                .foregroundColor(viewModel.description.count > 1000 ? .red : .secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Submit button
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await viewModel.submitProposal()
                            }
                        }) {
                            HStack {
                                if viewModel.isSubmitting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                }
                                Text(viewModel.isSubmitting ? "送信中..." : "提案を送信")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                viewModel.canSubmit ? Color.primaryOrange : Color.gray
                            )
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
                        .accessibilityIdentifier("SubmitButton")
                        
                        // Guidelines text
                        Text("※ 提案された店舗は管理者による確認後、アプリに追加されます。虚偽の情報や不適切な内容は削除される場合があります。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("店舗提案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("提案完了", isPresented: $viewModel.showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("店舗提案が正常に送信されました。管理者による承認をお待ちください。")
            }
            .alert("エラー", isPresented: $viewModel.showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct ProposalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

// MARK: - View Model
@MainActor
@Observable
class ShopProposalFormViewModel {
    var shopName = ""
    var address = ""
    var selectedGenre: ShopGenre?
    var description = ""
    
    var isSubmitting = false
    var showingSuccessAlert = false
    var showingErrorAlert = false
    var errorMessage = ""
    
    private let shopAPIService = ShopAPIService.shared
    
    var canSubmit: Bool {
        !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        shopName.count <= 100 &&
        address.count <= 255 &&
        description.count <= 1000
    }
    
    func submitProposal() async {
        guard canSubmit else { return }
        
        isSubmitting = true
        
        do {
            let trimmedName = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            _ = try await shopAPIService.submitShopProposal(
                name: trimmedName,
                address: trimmedAddress.isEmpty ? nil : trimmedAddress,
                genre: selectedGenre,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription
            )
            
            // Success
            showingSuccessAlert = true
            
        } catch {
            // Handle specific error cases
            if let apiError = error as? APIError {
                switch apiError {
                case .rateLimitExceeded:
                    errorMessage = "1時間に3件以上の提案はできません。しばらく時間をおいてから再度お試しください。"
                case .serverError(let message):
                    errorMessage = message
                default:
                    errorMessage = "提案の送信中にエラーが発生しました。ネットワーク接続を確認してもう一度お試しください。"
                }
            } else {
                errorMessage = "提案の送信中にエラーが発生しました。もう一度お試しください。"
            }
            
            showingErrorAlert = true
        }
        
        isSubmitting = false
    }
}

// MARK: - Preview
struct ShopProposalFormView_Previews: PreviewProvider {
    static var previews: some View {
        ShopProposalFormView()
    }
}
