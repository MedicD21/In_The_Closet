import Foundation

enum AppError: LocalizedError {
    case configuration(String)
    case unavailable(String)
    case validation(String)
    case persistence(String)

    var errorDescription: String? {
        switch self {
        case .configuration(let message),
                .unavailable(let message),
                .validation(let message),
                .persistence(let message):
            message
        }
    }
}

struct AppNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
