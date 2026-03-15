import Foundation
import OSLog

enum AppConsole {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.dustinschaaf.resetmyspace"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let analysis = Logger(subsystem: subsystem, category: "Analysis")
    static let recommendations = Logger(subsystem: subsystem, category: "Recommendations")
    static let visualization = Logger(subsystem: subsystem, category: "Visualization")
    static let projects = Logger(subsystem: subsystem, category: "Projects")
}
