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
        URL(string: supabaseURL) != nil && !supabaseAnonKey.isEmpty
    }

    var hasOpenAIKey: Bool { !openAIAPIKey.isEmpty }
    var hasAnthropicKey: Bool { !anthropicAPIKey.isEmpty }
    var hasOpenRouterKey: Bool { !openRouterAPIKey.isEmpty }

    var amazonBaseURL: URL {
        URL(string: amazonAffiliateBaseURL) ?? URL(string: "https://www.amazon.com")!
    }
}
