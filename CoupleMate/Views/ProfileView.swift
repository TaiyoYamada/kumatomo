import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel = AuthViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                // プロフィールヘッダー
                VStack {
                    if let user = viewModel.currentUser {
                        if let profileImageUrl = user.profileImageURL, !profileImageUrl.isEmpty {
                            AsyncImage(url: URL(string: profileImageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 120, height: 120)
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(user.fullName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 8)
                        
                        if let birthDate = user.birthDate {
                            Text("誕生日: \(birthDate, formatter: dateFormatter)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ProgressView()
                    }
                }
                .padding(.top, 32)
                
                Spacer()
                
                // ログアウトボタン
                Button {
                    viewModel.signOut()
                } label: {
                    Text("ログアウト")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 360, height: 44)
                        .background(Color.pink)
                        .cornerRadius(10)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
}
