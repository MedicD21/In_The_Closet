import Foundation

struct AppContainer {
    let config: AppConfig
    let authService: AuthService
    let projectRepository: ProjectRepository
    let analysisService: AIAnalysisService
    let visualizationService: VisualizationService
    let productRecommendationService: ProductRecommendationService
    let themeStore: ThemeStore

    @MainActor
    static func bootstrap() -> AppContainer {
        let config = AppConfig.fromBundle()
        let qualityMode: AIQualityMode = .free

        let themeStore = ThemeStore()
        let clientFactory = SupabaseClientFactory(config: config)
        let localRepository = FileBackedProjectRepository()
        let projectRepository: ProjectRepository = if config.isSupabaseConfigured {
            SyncedProjectRepository(
                remote: SupabaseProjectRepository(clientFactory: clientFactory),
                cache: localRepository
            )
        } else {
            localRepository
        }
        let authService: AuthService = config.isSupabaseConfigured
            ? SupabaseAuthService(clientFactory: clientFactory)
            : UnavailableAuthService(message: "Supabase auth is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY to sign in.")

        let openRouterClient = OpenRouterClient(apiKey: config.openRouterAPIKey)
        let linkBuilder = AmazonAffiliateLinkBuilder(
            baseURL: config.amazonBaseURL,
            associateTag: config.amazonAssociateTag.isEmpty ? "Reasonhome-20" : config.amazonAssociateTag
        )

        let openAIFallback: AIAnalysisService? = config.hasOpenAIKey
            ? OpenAIAnthropicAnalysisService(
                analyzer: OpenAIAnalysisProvider(config: config),
                coachingProvider: config.hasAnthropicKey ? AnthropicCoachingProvider(config: config) : nil
            )
            : nil

        let analysisService: AIAnalysisService
        if config.hasOpenRouterKey {
            analysisService = AIRouterService(
                primary: OpenRouterAnalysisService(client: openRouterClient, qualityMode: qualityMode),
                fallback: openAIFallback ?? UnavailableAIAnalysisService(
                    message: "No live AI analysis provider is configured. Add OPENAI_API_KEY or keep OPENROUTER_API_KEY enabled."
                )
            )
        } else if let openAIFallback {
            analysisService = openAIFallback
        } else {
            analysisService = UnavailableAIAnalysisService(
                message: "No live AI analysis provider is configured. Add OPENROUTER_API_KEY or OPENAI_API_KEY to analyze spaces."
            )
        }

        let productRecommendationService: ProductRecommendationService = config.hasOpenRouterKey
            ? OpenRouterProductRecommendationService(
                client: openRouterClient,
                linkBuilder: linkBuilder,
                qualityMode: qualityMode
            )
            : UnavailableProductRecommendationService(
                message: "OPENROUTER_API_KEY is required for live product recommendations."
            )

        let visualizationService: VisualizationService = config.hasOpenAIKey
            ? OpenAIVisualizationService(config: config)
            : UnavailableVisualizationService(
                message: "OPENAI_API_KEY is required for live concept previews."
            )

        AppConsole.app.notice(
            """
            bootstrap complete | supabaseConfigured=\(config.isSupabaseConfigured, privacy: .public) \
            | openRouterConfigured=\(config.hasOpenRouterKey, privacy: .public) \
            | openAIConfigured=\(config.hasOpenAIKey, privacy: .public) \
            | anthropicConfigured=\(config.hasAnthropicKey, privacy: .public) \
            | qualityMode=\(String(describing: qualityMode), privacy: .public)
            """
        )

        return AppContainer(
            config: config,
            authService: authService,
            projectRepository: projectRepository,
            analysisService: analysisService,
            visualizationService: visualizationService,
            productRecommendationService: productRecommendationService,
            themeStore: themeStore
        )
    }
}
