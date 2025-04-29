import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class PairingViewModel: ObservableObject {
    @Published var inviteCode: String = ""
    @Published var inputCode: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    init() {
        generateInviteCodeIfNeeded()
    }
    
    // 招待コードを生成
    func generateInviteCodeIfNeeded() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // 既にペアIDが存在するか確認
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                if let pairId = document.data()?["pairId"] as? String {
                    self.inviteCode = pairId
                } else {
                    // 新しいペアIDを生成
                    let newPairId = UUID().uuidString.prefix(6).uppercased()
                    self.inviteCode = String(newPairId)
                    
                    // Firestoreに新しいペアを作成
                    self.db.collection("pairs").document(self.inviteCode).setData([
                        "members": [userId],
                        "createdAt": FieldValue.serverTimestamp()
                    ]) { error in
                        if let error = error {
                            self.errorMessage = "ペアの作成に失敗しました: \(error.localizedDescription)"
                        } else {
                            // ユーザーのドキュメントにpairIdを設定
                            self.db.collection("users").document(userId).updateData([
                                "pairId": self.inviteCode
                            ]) { error in
                                if let error = error {
                                    self.errorMessage = "ユーザー情報の更新に失敗しました: \(error.localizedDescription)"
                                }
                            }
                        }
                    }
                }
            } else {
                self.errorMessage = "ユーザー情報の取得に失敗しました。"
            }
        }
    }
    
    // 招待コードを共有
    func shareInviteCode() {
        let message = "私たちの招待コード: \(inviteCode)"
        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        
        // iOS 13以降の対応
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func copyInviteCode() {
        UIPasteboard.general.string = inviteCode
    }
    
    // 招待コードを使用してペアに参加
    func joinPair() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        errorMessage = nil
        
        let pairRef = db.collection("pairs").document(inputCode.uppercased())
        
        pairRef.getDocument { document, error in
            if let document = document, document.exists {
                // ペアにユーザーを追加
                pairRef.updateData([
                    "members": FieldValue.arrayUnion([userId])
                ]) { error in
                    if let error = error {
                        self.errorMessage = "ペアへの参加に失敗しました: \(error.localizedDescription)"
                    } else {
                        // ユーザーのドキュメントにpairIdを設定
                        self.db.collection("users").document(userId).updateData([
                            "pairId": self.inputCode.uppercased()
                        ]) { error in
                            if let error = error {
                                self.errorMessage = "ユーザー情報の更新に失敗しました: \(error.localizedDescription)"
                            }
                        }
                    }
                    self.isLoading = false
                }
            } else {
                self.errorMessage = "無効な招待コードです。"
                self.isLoading = false
            }
        }
    }
}
