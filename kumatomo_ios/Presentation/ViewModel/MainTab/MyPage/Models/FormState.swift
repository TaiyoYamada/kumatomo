import Foundation
import PhotosUI
import SwiftUI
import UIKit

// MARK: - FormState

/// プロフィール編集フォームの状態を保持する構造体
/// ロールバックや状態比較に使用される
struct FormState {
    let email: String
    let name: String
    let username: String
    let bio: String
    let location: String
    let birthday: Date
    let profileImage: UIImage?
    let coverImage: UIImage?
    let hasUnsavedChanges: Bool
    let hasUnsavedProfileImage: Bool
    let hasUnsavedCoverImage: Bool
    let selectedProfileItem: PhotosPickerItem?
    let selectedCoverItem: PhotosPickerItem?
}
