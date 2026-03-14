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
        let remoteRepository = config.isSupabaseConfigured
            ? SupabaseProjectRepository(clientFactory: clientFactory)
            : nil
        let projectRepository = ResilientProjectRepository(primary: remoteRepository, fallback: localRepository)
        let authService: AuthService = config.isSupabaseConfigured
            ? SupabaseAuthService(clientFactory: clientFactory)
            : MockAuthService()

        let openRouterClient = OpenRouterClient(apiKey: config.openRouterAPIKey)
        let linkBuilder = AmazonAffiliateLinkBuilder(
            baseURL: config.amazonBaseURL,
            associateTag: config.amazonAssociateTag.isEmpty ? "Reasonhome-20" : config.amazonAssociateTag
        )

        let mockAnalysisService = MockAIAnalysisService()
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
                fallback: openAIFallback ?? mockAnalysisService
            )
        } else if let openAIFallback {
            analysisService = openAIFallback
        } else {
            analysisService = mockAnalysisService
        }

        let productRecommendationService: ProductRecommendationService = config.hasOpenRouterKey
            ? OpenRouterProductRecommendationService(
                client: openRouterClient,
                linkBuilder: linkBuilder,
                qualityMode: qualityMode
            )
            : CuratedAmazonRecommendationService(linkBuilder: linkBuilder)

        let visualizationService: VisualizationService = config.hasOpenRouterKey
            ? OpenRouterVisualizationService(
                client: openRouterClient,
                qualityMode: qualityMode
            )
            : MockVisualizationService()

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
