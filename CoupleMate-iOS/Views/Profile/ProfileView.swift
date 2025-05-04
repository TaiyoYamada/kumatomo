import SwiftUI
import PhotosUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel
    @State private var showEditProfile = false

    init() {
        if let uid = Auth.auth().currentUser?.uid {
            _viewModel = StateObject(wrappedValue: ProfileViewModel(userID: uid))
        } else {
            _viewModel = StateObject(wrappedValue: ProfileViewModel(userID: ""))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                profileDetails
                editButton
                signOutButton
            }
            .padding()
        }
        .navigationTitle("プロフィール")
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView(viewModel: viewModel)
            }
        }
        .alert("エラー", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラー")
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }

    private var profileHeader: some View {
        VStack {
            if let imageURLString = viewModel.profile.profileImageURL, let imageURL = URL(string: imageURLString) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 7)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 7)
            }

            Text(viewModel.profile.fullName)
                .font(.title)
                .fontWeight(.bold)

            Text(viewModel.profile.relationshipStatus)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 1)
        }
    }

    private var profileDetails: some View {
        VStack(alignment: .leading, spacing: 15) {
            detailSection(title: "自己紹介", content: viewModel.profile.bio)

            if let birthDate = viewModel.profile.birthDate {
                detailSection(title: "誕生日", content: formatDate(birthDate))
            }

            if !viewModel.profile.interests.isEmpty {
                VStack(alignment: .leading) {
                    Text("興味・関心事")
                        .font(.headline)

                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.profile.interests, id: \.self) { interest in
                            Text(interest)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
    }

    private func detailSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private var editButton: some View {
        Button(action: {
            showEditProfile = true
        }) {
            HStack {
                Image(systemName: "pencil")
                Text("プロフィールを編集")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }

    private var signOutButton: some View {
        Button {
            authViewModel.signOut()
        } label: {
            Text("ログアウト")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 360, height: 44)
                .background(Color.pink)
                .cornerRadius(10)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
