import Foundation
import Supabase

final class SupabaseClientFactory {
    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    func makeClient() throws -> SupabaseClient {
        guard let url = URL(string: config.supabaseURL), !config.supabaseAnonKey.isEmpty else {
            throw AppError.configuration("Supabase keys are missing. Add them to Secrets.xcconfig before enabling the live backend.")
        }

        return SupabaseClient(supabaseURL: url, supabaseKey: config.supabaseAnonKey)
    }
}
