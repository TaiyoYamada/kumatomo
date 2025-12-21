import Foundation
import Alamofire // For HTTPMethod if needed in base, but here we likely use custom enum or Alamofire's

enum AnnouncementEndpoint: APIEndpoint {
    case fetchAnnouncements

    var path: String {
        switch self {
        case .fetchAnnouncements:
            return "/announcements"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchAnnouncements:
            return .get
        }
    }

    var requiresAuth: Bool {
        // Public endpoint, but typically we send token if available.
        // Based on api_user.php, it's public.
        return true
    }
}
