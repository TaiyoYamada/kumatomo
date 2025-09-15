import SwiftUI
import PhotosUI

struct InitialSetupView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var selectedLocation: String = ""
    @State private var birthday: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var displayImage: UIImage? = nil
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    let locations: [String] = Municipality.allCases.map { $0.displayName }
    
    // フォームが有効かチェック
    var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedLocation.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダー
                        Text("プロフィール設定")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
//                        Text("基本情報を設定して、アプリを始めましょう")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .padding(.bottom, 10)
                        
                        // プロフィール画像セクション
                        VStack(spacing: 16) {
                            ZStack {
                                if let displayImage = displayImage {
                                    Image(uiImage: displayImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        .shadow(radius: 3)
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60, height: 60)
                                                .foregroundColor(.gray)
                                        )
                                }
                                
                                PhotosPicker(selection: $selectedImage, matching: .images) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                    }
                                }
                                .buttonStyle(.plain)
                                .offset(x: 55, y: 40)
                            }
                            .padding(.top, 10)
                            
                            Text("プロフィール画像")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // フォームセクション
                        VStack(spacing: 20) {
                            // ユーザー名
                            FormField(
                                icon: "person.fill",
                                title: "ニックネーム",
                                placeholder: "ニックネームを入力",
                                text: $username
                            )
                            
                            // 住んでいる市
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.title3)
                                        .frame(width: 24)
                                    
                                    Text("お住まいの市町村")
                                        .font(.headline)
                                }
                                
                                Menu {
                                    ForEach(locations, id: \.self) { location in
                                        Button(action: {
                                            selectedLocation = location
                                        }) {
                                            Text(location)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedLocation.isEmpty ? "市町村を選択" : selectedLocation)
                                            .foregroundColor(selectedLocation.isEmpty ? .gray : .primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                            }
                            
                            // 生年月日
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.orange)
                                        .font(.title3)
                                        .frame(width: 24)
                                    
                                    Text("生年月日")
                                        .font(.headline)
                                }
                                
                                DatePicker("", selection: $birthday, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 送信ボタン
                        Button(action: handleSubmit) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("登録してはじめる")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.orange : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .shadow(color: isFormValid ? Color.orange.opacity(0.3) : Color.clear, radius: 5)
                        .disabled(!isFormValid || isSubmitting)
                        
                        Spacer().frame(height: 30)
                    }
                    .padding(.bottom, 40)
                }
                
                // ローディングオーバーレイ
                if viewModel.isLoading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text("保存しています...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 20)
                            }
                        )
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("エラー"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: selectedImage) { _ in
                loadSelectedImage()
            }
        }
    }
    
    private func loadSelectedImage() {
        Task {
            if let selectedImage = selectedImage,
               let data = try? await selectedImage.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    displayImage = uiImage
                    viewModel.profileImage = uiImage
                }
            }
        }
    }
    
    private func handleSubmit() {
        guard isFormValid else { return }
        isSubmitting = true
        
        // AuthViewModelに値を設定
        viewModel.name = username
        viewModel.location = selectedLocation
        viewModel.birthDate = birthday
        // プロフィール画像はloadSelectedImageメソッドで既にセット済み
        
        Task {
            let success = await viewModel.saveInitialSetup()
            
            await MainActor.run {
                isSubmitting = false
                
                if success {
                    // 成功したらMainTabViewに遷移するよう状態を更新
                    print("✅ 初期設定保存成功")
                    // 掲示板の市町村初期値をユーザーの選択に設定
                    UserDefaults.standard.set(selectedLocation, forKey: "selectedMunicipality")
                    // 初回は市町村タブを優先表示
                    UserDefaults.standard.set(true, forKey: "preferMunicipalityTabOnFirstOpen")
                    viewModel.hasCompletedSetup = true
                    viewModel.isAuthenticated = true
                    dismiss()
                } else if let error = viewModel.errorMessage {
                    alertMessage = error
                    showAlert = true
                } else {
                    alertMessage = "不明なエラーが発生しました"
                    showAlert = true
                }
            }
        }
    }
}

// フォームフィールドコンポーネント
struct FormField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .font(.title3)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
            }
            
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}
