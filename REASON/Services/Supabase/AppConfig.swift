import Foundation

enum AIQualityMode {
    case free        // Confirmed free OpenRouter models — zero cost
    case budget      // Inexpensive paid models — small cost, better quality
    case highQuality // Best paid models — higher cost, best results
}

struct AppConfig {
    let supabaseURL: String
    let supabaseAnonKey: String
    let openAIAPIKey: String
    let anthropicAPIKey: String
    let openRouterAPIKey: String
    let amazonAssociateTag: String
    let amazonAffiliateBaseURL: String

    static func fromBundle(_ bundle: Bundle = .main) -> AppConfig {
        AppConfig(
            supabaseURL: bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "",
            supabaseAnonKey: bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? "",
            openAIAPIKey: bundle.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? "",
            anthropicAPIKey: bundle.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? "",
            openRouterAPIKey: bundle.object(forInfoDictionaryKey: "OPENROUTER_API_KEY") as? String ?? "",
            amazonAssociateTag: bundle.object(forInfoDictionaryKey: "AMAZON_ASSOCIATE_TAG") as? String ?? "",
            amazonAffiliateBaseURL: bundle.object(forInfoDictionaryKey: "AMAZON_AFFILIATE_BASE_URL") as? String ?? "https://www.amazon.com"
        )
    }

    var isSupabaseConfigured: Bool {
        guard
            isConfigured(supabaseURL, rejecting: ["https://your-project.supabase.co"]),
            let url = URL(string: supabaseURL),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            return false
        }

        return isConfigured(supabaseAnonKey, rejecting: ["your-supabase-anon-key"])
    }

    var hasOpenAIKey: Bool { isConfigured(openAIAPIKey, rejecting: ["your-openai-api-key"]) }
    var hasAnthropicKey: Bool { isConfigured(anthropicAPIKey, rejecting: ["your-anthropic-api-key"]) }
    var hasOpenRouterKey: Bool { isConfigured(openRouterAPIKey, rejecting: ["your-openrouter-api-key"]) }

    var amazonBaseURL: URL {
        URL(string: amazonAffiliateBaseURL) ?? URL(string: "https://www.amazon.com")!
    }

    private func isConfigured(_ value: String, rejecting placeholders: Set<String> = []) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else { return false }
        return !placeholders.contains(trimmed)
    }
}
