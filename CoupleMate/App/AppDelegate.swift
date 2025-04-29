import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Firebase の初期化
        FirebaseApp.configure()
        
        // Firestore のキャッシュ設定
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber) // 100MB のキャッシュサイズ
        Firestore.firestore().settings = settings
        
        print("Firebase の初期化と Firestore のキャッシュ設定が完了しました")
        
        return true
    }
}
