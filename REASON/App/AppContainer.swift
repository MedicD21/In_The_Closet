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
        let themeStore = ThemeStore()
        let clientFactory = SupabaseClientFactory(config: config)
        let localRepository = FileBackedProjectRepository()
        let remoteRepository = config.isSupabaseConfigured ? SupabaseProjectRepository(clientFactory: clientFactory) : nil
        let projectRepository = ResilientProjectRepository(primary: remoteRepository, fallback: localRepository)
        let authService: AuthService = config.isSupabaseConfigured
            ? SupabaseAuthService(clientFactory: clientFactory)
            : MockAuthService()
        let mockAI = MockAIAnalysisService()
        let analysisService = AIRouterService(
            primary: OpenAIAnalysisProvider(config: config),
            coach: AnthropicCoachingProvider(config: config),
            fallback: mockAI
        )
        let productRecommendationService = CuratedAmazonRecommendationService(
            linkBuilder: AmazonAffiliateLinkBuilder(
                baseURL: config.amazonBaseURL,
                associateTag: config.amazonAssociateTag.isEmpty ? "yourtag-20" : config.amazonAssociateTag
            )
        )

        return AppContainer(
            config: config,
            authService: authService,
            projectRepository: projectRepository,
            analysisService: analysisService,
            visualizationService: MockVisualizationService(),
            productRecommendationService: productRecommendationService,
            themeStore: themeStore
        )
    }
}
