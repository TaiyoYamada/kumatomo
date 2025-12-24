import Foundation

// MARK: - ProfileField

/// プロフィールの各フィールドを表す列挙型
/// 変更検出や表示名の取得に使用される
enum ProfileField: CaseIterable {
    case email
    case name
    case username
    case bio
    case location
    case birthday
    case profileImage
    case coverImage

    var displayName: String {
        switch self {
        case .email:
            return "メールアドレス"
        case .name:
            return "名前"
        case .username:
            return "ユーザーネーム"
        case .bio:
            return "自己紹介"
        case .location:
            return "出身地"
        case .birthday:
            return "誕生日"
        case .profileImage:
            return "プロフィール画像"
        case .coverImage:
            return "カバー画像"
        }
    }
}
