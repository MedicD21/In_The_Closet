import Foundation

@MainActor
final class OpenRouterAnalysisService: AIAnalysisService {
    private let client: OpenRouterClient
    private let qualityMode: AIQualityMode

    // Stage 1 — vision models (confirmed available 2026-03)
    private var visionModel: String {
        switch qualityMode {
        case .free:        "google/gemma-3-27b-it:free"
        case .budget:      "mistralai/mistral-small-3.1-24b-instruct:free"
        case .highQuality: "mistralai/mistral-small-3.1-24b-instruct:free"
        }
    }

    // Stage 2 — planner models (confirmed available 2026-03)
    private var plannerModel: String {
        switch qualityMode {
        case .free:        "meta-llama/llama-3.3-70b-instruct:free"
        case .budget:      "nousresearch/hermes-3-llama-3.1-405b:free"
        case .highQuality: "nousresearch/hermes-3-llama-3.1-405b:free"
        }
    }

    init(client: OpenRouterClient, qualityMode: AIQualityMode = .free) {
        self.client = client
        self.qualityMode = qualityMode
    }

    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis {
        guard !client.apiKey.isEmpty else {
            throw AppError.configuration("OPENROUTER_API_KEY is not configured.")
        }
        guard request.imageData != nil else {
            throw AppError.validation("Choose a photo before running a live analysis.")
        }

        AppConsole.analysis.notice("starting OpenRouter analysis stage1=\(self.visionModel, privacy: .public) stage2=\(self.plannerModel, privacy: .public) mode=\(request.mode.rawValue, privacy: .public) space=\(request.spaceType.rawValue, privacy: .public)")

        // Stage 1: Vision analysis
        let visionJSON = try await runStage1(request: request)
        AppConsole.analysis.notice("OpenRouter stage 1 complete chars=\(visionJSON.count, privacy: .public)")

        // Stage 2: Organization planner → full SpaceAnalysis (coaching included)
        let result = try await runStage2(request: request, visionJSON: visionJSON)
        AppConsole.analysis.notice("OpenRouter stage 2 complete score=\(result.score.totalScore, privacy: .public) opportunities=\(result.bestOpportunities.count, privacy: .public)")
        return result
    }

    // MARK: - Stage 1: Vision Analysis

    private func runStage1(request: AnalysisRequest) async throws -> String {
        let payload = try buildStage1Payload(request: request)
        return try await client.chat(payload: payload)
    }

    private func buildStage1Payload(request: AnalysisRequest) throws -> Data {
        let systemPrompt = """
        You are an interior organization expert.
        Analyze the uploaded room image.
        Return structured JSON with:
        - room_type (string)
        - organization_score (1-10, integer)
        - clutter_sources (array of short strings)
        - visible_surfaces (array of short strings)
        - storage_problems (array of short strings)
        - cable_visibility (boolean)
        - decor_mismatch (boolean)
        - safety_issues (array of strings, empty if none)
        - improvement_opportunities (array of short strings)
        Use realistic reasoning. Most real spaces score 4-7.
        """

        var content: [[String: Any]] = []

        let base64 = request.imageData?.base64EncodedString() ?? ""
        content.append([
            "type": "image_url",
            "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
        ])
        content.append(["type": "text", "text": systemPrompt])

        let payload: [String: Any] = [
            "model": visionModel,
            "max_tokens": 600,
            "response_format": ["type": "json_object"],
            "messages": [["role": "user", "content": content]]
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    // MARK: - Stage 2: Organization Planner

    private func runStage2(request: AnalysisRequest, visionJSON: String) async throws -> SpaceAnalysis {
        let payload = try buildStage2Payload(request: request, visionJSON: visionJSON)
        let result = try await client.chat(payload: payload)
        return try parseStage2(result, request: request)
    }

    private func buildStage2Payload(request: AnalysisRequest, visionJSON: String) throws -> Data {
        let roomName = request.customSpaceName?.isEmpty == false
            ? request.customSpaceName!
            : request.spaceType.displayName

        let modeContext: String
        switch request.mode {
        case .organize:
            modeContext = "Goal: practical organization and improved usability."
        case .stageForSelling:
            modeContext = "Goal: staging for real estate — visual clarity, minimal personal cues, buyer appeal."
        case .compareProgress:
            modeContext = "Goal: assess improvement since a previous reset."
        }

        var prompt = """
        You are a professional home organizer.
        Based on this room analysis:
        \(visionJSON)

        Room: \(roomName). Mode: \(request.mode.longLabel). \(modeContext)
        Score each dimension 0-100 (100=perfect). Most real spaces score 40-75.

        Return a single JSON object:
        {
          "rawInputSummary": "one sentence describing what you see",
          "clutterScore": <int 0-100>,
          "accessibilityScore": <int 0-100>,
          "zoningScore": <int 0-100>,
          "visibilityScore": <int 0-100>,
          "shelfEfficiencyScore": <int 0-100>,
          "visualCalmScore": <int 0-100>,
          "stagingReadinessScore": <int 0-100>,
          "summaryText": "2-3 sentence honest assessment",
          "supportiveCoachingText": "2-3 sentences warm personal coaching, not generic",
          "biggestProblems": ["problem 1", "problem 2", "problem 3"],
          "bestOpportunities": ["opportunity 1", "opportunity 2", "opportunity 3"],
          "resetPlanSteps": [
            {"order": 1, "title": "step title", "detail": "what to do", "estimatedMinutes": <int>, "impactNote": "why it matters"},
            {"order": 2, "title": "...", "detail": "...", "estimatedMinutes": <int>, "impactNote": "..."},
            {"order": 3, "title": "...", "detail": "...", "estimatedMinutes": <int>, "impactNote": "..."},
            {"order": 4, "title": "...", "detail": "...", "estimatedMinutes": <int>, "impactNote": "..."}
          ],
          "estimatedResetMinutes": <int>,
          "visualizationConcept": {
            "projectedImprovedScore": <int>,
            "promptSummary": "one sentence describing the ideal improved version",
            "whatImproved": ["improvement 1", "improvement 2"],
            "stillNeedsWork": ["remaining item 1"],
            "conceptCaption": "brief evocative caption"
          }
        """

        if request.mode == .stageForSelling {
            prompt += """
            ,
              "stagingAdvice": {
                "readinessScore": <int 0-100>,
                "removeItems": ["item 1", "item 2"],
                "hideItems": ["item 1"],
                "addItems": ["item 1"],
                "quickWins": ["win 1", "win 2"],
                "showingDayChecklist": [
                  {"title": "task 1", "priority": 1},
                  {"title": "task 2", "priority": 2}
                ]
              }
            """
        }
        prompt += "\n}"

        let payload: [String: Any] = [
            "model": plannerModel,
            "max_tokens": 2500,
            "response_format": ["type": "json_object"],
            "messages": [["role": "user", "content": prompt]]
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    // MARK: - Parsing

    private func parseStage2(_ content: String, request: AnalysisRequest) throws -> SpaceAnalysis {
        let normalizedContent = JSONResponseSanitizer.clean(content)
        guard
            let contentData = normalizedContent.data(using: .utf8),
            let parsed = try JSONSerialization.jsonObject(with: contentData) as? [String: Any]
        else {
            throw AppError.parsing("Could not parse OpenRouter planner response.")
        }

        let clutter = parsed["clutterScore"] as? Int ?? 50
        let accessibility = parsed["accessibilityScore"] as? Int ?? 50
        let zoning = parsed["zoningScore"] as? Int ?? 50
        let visibility = parsed["visibilityScore"] as? Int ?? 50
        let shelfEfficiency = parsed["shelfEfficiencyScore"] as? Int ?? 50
        let visualCalm = parsed["visualCalmScore"] as? Int ?? 50
        let stagingReadiness = parsed["stagingReadinessScore"] as? Int ?? 50
        let total = (clutter + accessibility + zoning + visibility + shelfEfficiency + visualCalm + stagingReadiness) / 7

        let breakdown = ScoreBreakdown(
            totalScore: total,
            clutterScore: clutter,
            accessibilityScore: accessibility,
            zoningScore: zoning,
            visibilityScore: visibility,
            shelfEfficiencyScore: shelfEfficiency,
            visualCalmScore: visualCalm,
            stagingReadinessScore: stagingReadiness
        )

        let resetPlanSteps = (parsed["resetPlanSteps"] as? [[String: Any]] ?? []).map { step in
            ResetPlanStep(
                id: UUID(),
                order: step["order"] as? Int ?? 1,
                title: step["title"] as? String ?? "",
                detail: step["detail"] as? String ?? "",
                estimatedMinutes: step["estimatedMinutes"] as? Int ?? 10,
                impactNote: step["impactNote"] as? String ?? ""
            )
        }

        var visualizationConcept: VisualizationConcept?
        if let vc = parsed["visualizationConcept"] as? [String: Any] {
            visualizationConcept = VisualizationConcept(
                projectedImprovedScore: vc["projectedImprovedScore"] as? Int ?? total + 15,
                promptSummary: vc["promptSummary"] as? String ?? "",
                whatImproved: vc["whatImproved"] as? [String] ?? [],
                stillNeedsWork: vc["stillNeedsWork"] as? [String] ?? [],
                conceptCaption: vc["conceptCaption"] as? String ?? "",
                generatedImageURL: nil
            )
        }

        var stagingAdvice: StagingAdvice?
        if request.mode == .stageForSelling, let sa = parsed["stagingAdvice"] as? [String: Any] {
            let checklistItems = (sa["showingDayChecklist"] as? [[String: Any]] ?? []).enumerated().map { idx, item in
                ChecklistItem(
                    id: UUID(),
                    title: item["title"] as? String ?? "",
                    isDone: false,
                    priority: item["priority"] as? Int ?? (idx + 1)
                )
            }
            stagingAdvice = StagingAdvice(
                readinessScore: sa["readinessScore"] as? Int ?? stagingReadiness,
                removeItems: sa["removeItems"] as? [String] ?? [],
                hideItems: sa["hideItems"] as? [String] ?? [],
                addItems: sa["addItems"] as? [String] ?? [],
                quickWins: sa["quickWins"] as? [String] ?? [],
                showingDayChecklist: checklistItems
            )
        }

        return SpaceAnalysis(
            id: UUID(),
            projectID: request.projectID,
            providerPrimary: .openRouter,
            providerSecondary: nil,
            rawInputSummary: parsed["rawInputSummary"] as? String ?? "",
            score: breakdown,
            summaryText: parsed["summaryText"] as? String ?? "",
            supportiveCoachingText: parsed["supportiveCoachingText"] as? String ?? "",
            biggestProblems: parsed["biggestProblems"] as? [String] ?? [],
            bestOpportunities: parsed["bestOpportunities"] as? [String] ?? [],
            resetPlan: resetPlanSteps,
            estimatedResetMinutes: parsed["estimatedResetMinutes"] as? Int ?? 30,
            confidenceNotes: [],
            budgetRecommendations: [],
            visualizationConcept: visualizationConcept,
            stagingAdvice: stagingAdvice,
            createdAt: .now
        )
    }
}
