import Foundation
import SwiftUI

class PortalErrorHandler: ObservableObject {
    static let shared = PortalErrorHandler()


    enum PortalError: LocalizedError {
        case invalidURL(String)
        case networkUnavailable
        case assetNotFound(String)
        case urlCannotOpen(String)
        case openingFailed(String)
        case timerError
        case configurationError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL(let url):
                return "無効なURLです: \(url)"
            case .networkUnavailable:
                return "インターネット接続がありません"
            case .assetNotFound(let assetName):
                return "画像が見つかりません: \(assetName)"
            case .urlCannotOpen(let url):
                return "このリンクを開くことができません: \(url)"
            case .openingFailed(let url):
                return "リンクを開くことができませんでした: \(url)"
            case .timerError:
                return "スライドショーの動作に問題があります"
            case .configurationError(let message):
                return "設定エラー: \(message)"
            }
        }

        var userFriendlyMessage: String {
            switch self {
            case .invalidURL:
                return "無効なURLです。\nサービス設定に問題があります。"
            case .networkUnavailable:
                return "インターネット接続がありません。\nWi-Fiまたはモバイルデータ接続を確認してください。"
            case .assetNotFound:
                return "画像を読み込めませんでした。\nアプリを再起動してお試しください。"
            case .urlCannotOpen:
                return "このリンクを開くことができません。\nURLスキームがサポートされていません。"
            case .openingFailed:
                return "リンクを開くことができませんでした。\nしばらく時間をおいて再度お試しください。"
            case .timerError:
                return "スライドショーの表示に問題があります。\nアプリを再起動してお試しください。"
            case .configurationError:
                return "アプリの設定に問題があります。\nアプリを更新してください。"
            }
        }

        var shouldShowRetry: Bool {
            switch self {
            case .networkUnavailable, .openingFailed, .timerError:
                return true
            default:
                return false
            }
        }

        var logLevel: LogLevel {
            switch self {
            case .invalidURL, .configurationError:
                return .error
            case .networkUnavailable:
                return .warning
            case .assetNotFound, .urlCannotOpen, .openingFailed:
                return .info
            case .timerError:
                return .debug
            }
        }
    }

    enum LogLevel: String {
        case debug = "🔍"
        case info = "ℹ️"
        case warning = "⚠️"
        case error = "❌"
    }


    @MainActor private let networkMonitor = NetworkMonitor.shared

    private init() {}



    func validateURL(_ urlString: String) throws -> URL {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            throw PortalError.invalidURL("空のURL")
        }

        if trimmedURL.contains("example.com") || trimmedURL.contains("TODO") {
            throw PortalError.configurationError("プレースホルダーURLが設定されています: \(trimmedURL)")
        }

        guard let url = URL(string: trimmedURL) else {
            throw PortalError.invalidURL(trimmedURL)
        }

        guard let scheme = url.scheme?.lowercased(),
              ["http", "https", "tel", "mailto"].contains(scheme) else {
            throw PortalError.invalidURL("サポートされていないURLスキーム: \(url.scheme ?? "なし")")
        }

        return url
    }


    func canOpenURL(_ url: URL) -> Bool {
        return UIApplication.shared.canOpenURL(url)
    }


    @MainActor
    func openURL(_ urlString: String, completion: @escaping (Result<Void, PortalError>) -> Void) {
        guard networkMonitor.isConnected else {
            completion(.failure(.networkUnavailable))
            return
        }

        do {
            let url = try validateURL(urlString)

            guard canOpenURL(url) else {
                completion(.failure(.urlCannotOpen(urlString)))
                return
            }

            UIApplication.shared.open(url) { success in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else {
                        completion(.failure(.openingFailed(urlString)))
                    }
                }
            }
        } catch let error as PortalError {
            completion(.failure(error))
        } catch {
            completion(.failure(.invalidURL(urlString)))
        }
    }



    func validateImageAsset(_ assetName: String) -> Bool {
        if UIImage(named: assetName) != nil {
            return true
        }

        if Bundle.main.path(forResource: assetName, ofType: nil) != nil {
            return true
        }

        let extensions = ["png", "jpg", "jpeg", "gif", "heic"]
        for ext in extensions {
            if Bundle.main.path(forResource: assetName, ofType: ext) != nil {
                return true
            }
        }

        return false
    }


    func getMissingAssets(_ assetNames: [String]) -> [String] {
        return assetNames.filter { !validateImageAsset($0) }
    }


    func validateAssets(_ assetNames: [String]) -> (isValid: Bool, missingAssets: [String]) {
        let missing = getMissingAssets(assetNames)
        return (missing.isEmpty, missing)
    }



    func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer? {
        guard interval > 0 else {
            logError(.timerError, "Invalid timer interval: \(interval)")
            return nil
        }

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
        return timer
    }


    func invalidateTimer(_ timer: Timer?) {
        timer?.invalidate()
    }



    func logError(_ error: PortalError, _ additionalInfo: String? = nil) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "\(error.logLevel.rawValue) [\(timestamp)] Portal Error: \(error.localizedDescription)"

        if let info = additionalInfo {
            print("\(logMessage) - \(info)")
        } else {
            print(logMessage)
        }

        #if DEBUG
        if error.logLevel == .error {
            print("🔍 Debug Info: \(String(describing: error))")
        }
        #endif
    }



    @MainActor
    func shouldRetryForError(_ error: PortalError) -> Bool {
        return error.shouldShowRetry && networkMonitor.isConnected
    }


    func getRetryDelay(for error: PortalError, attempt: Int) -> TimeInterval {
        guard error.shouldShowRetry else { return 0 }

        let baseDelay: TimeInterval = 1.0
        let maxDelay: TimeInterval = 10.0

        let delay = min(baseDelay * pow(2.0, Double(attempt - 1)), maxDelay)
        let jitter = Double.random(in: 0...0.5)

        return delay + jitter
    }



    func validatePortalConfiguration(
        slideImages: [String],
        linkCollectionURL: String,
        cardData: [PortalCardData]
    ) -> [PortalError] {
        var errors: [PortalError] = []

        let missingSlideImages = getMissingAssets(slideImages)
        for missing in missingSlideImages {
            errors.append(.assetNotFound(missing))
        }

        do {
            _ = try validateURL(linkCollectionURL)
        } catch let error as PortalError {
            errors.append(error)
        } catch {
            errors.append(.invalidURL(linkCollectionURL))
        }

        for card in cardData {
            do {
                _ = try validateURL(card.externalURL)
            } catch let error as PortalError {
                errors.append(error)
            } catch {
                errors.append(.invalidURL(card.externalURL))
            }

            if !validateImageAsset(card.imageName) {
                errors.append(.assetNotFound(card.imageName))
            }
        }

        return errors
    }
}


extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}


extension PortalCardData {

    func validate() -> [PortalErrorHandler.PortalError] {
        return PortalErrorHandler.shared.validatePortalConfiguration(
            slideImages: [],
            linkCollectionURL: "",
            cardData: [self]
        )
    }


    var isValid: Bool {
        return validate().isEmpty
    }
}
