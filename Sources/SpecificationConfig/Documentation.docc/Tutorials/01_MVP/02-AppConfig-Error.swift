import Foundation

enum AppConfigError: LocalizedError {
    case missingRequiredValue(key: String)

    var errorDescription: String? {
        switch self {
        case let .missingRequiredValue(key):
            "Missing required config value for key: \(key)"
        }
    }
}
