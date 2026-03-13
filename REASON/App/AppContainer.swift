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

        let analysisService = AIRouterService(
            primary: OpenRouterAnalysisService(client: openRouterClient, qualityMode: qualityMode),
            fallback: MockAIAnalysisService()
        )

        let productRecommendationService = OpenRouterProductRecommendationService(
            client: openRouterClient,
            linkBuilder: linkBuilder,
            qualityMode: qualityMode
        )

        let visualizationService = OpenRouterVisualizationService(
            client: openRouterClient,
            qualityMode: qualityMode
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
