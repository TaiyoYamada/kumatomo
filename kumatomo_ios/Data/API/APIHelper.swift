import Foundation

enum APIHelper {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()

        decoder.keyDecodingStrategy = .convertFromSnakeCase

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let iso8601 = ISO8601DateFormatter()
            if #available(iOS 11.0, *) {
                iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            } else {
                iso8601.formatOptions = [.withInternetDateTime]
            }
            iso8601.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = iso8601.date(from: dateString) { return date }

            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd HH:mm:ss"
            ]
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            for format in formats {
                df.dateFormat = format
                if let date = df.date(from: dateString) { return date }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "無効な日付形式: \(dateString)"
            )
        }

        return decoder
    }

    static func parseDate(_ dateString: String) -> Date? {
        let iso8601 = ISO8601DateFormatter()
        if #available(iOS 11.0, *) {
            iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        } else {
            iso8601.formatOptions = [.withInternetDateTime]
        }
        iso8601.timeZone = TimeZone(secondsFromGMT: 0)
        if let d = iso8601.date(from: dateString) { return d }

        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd HH:mm:ss"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        for format in formats {
            df.dateFormat = format
            if let d = df.date(from: dateString) { return d }
        }
        return nil
    }
}
