import Foundation

@MainActor
protocol OpenAIAnalyzing {
    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis
}

final class OpenAIAnalysisProvider: OpenAIAnalyzing {
    private let config: AppConfig
    private let session: URLSession

    init(config: AppConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis {
        guard config.hasOpenAIKey else {
            throw AppError.configuration("OpenAI is not configured yet. Add OPENAI_API_KEY to enable the live provider.")
        }

        let prompt = buildPrompt(for: request)
        let messages = buildMessages(prompt: prompt, imageData: request.imageData)

        let payload: [String: Any] = [
            "model": "gpt-4o",
            "response_format": ["type": "json_object"],
            "max_tokens": 2000,
            "messages": messages
        ]

        let data = try await post(payload: payload)
        return try parseResponse(data: data, request: request)
    }

    // MARK: - Prompt construction

    private func buildPrompt(for request: AnalysisRequest) -> String {
        let roomName = request.customSpaceName?.isEmpty == false ? request.customSpaceName! : request.spaceType.displayName

        let modeContext: String
        switch request.mode {
        case .organize:
            modeContext = "The goal is practical organization and improved usability."
        case .stageForSelling:
            modeContext = "The goal is staging for real estate photos or showings — prioritize visual clarity, minimal personal cues, and buyer appeal."
        case .compareProgress:
            modeContext = "The goal is to assess improvement since a previous reset."
        }

        var prompt = """
        You are an expert home organization and staging consultant. Analyze this photo of a \(roomName).
        \(modeContext)

        Score each dimension from 0–100 (100 = perfect). Be honest and calibrated — most real spaces score 40–75.

        Respond with a single JSON object with these exact keys:
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
          "biggestProblems": ["problem 1", "problem 2", "problem 3"],
          "bestOpportunities": ["opportunity 1", "opportunity 2", "opportunity 3"],
          "resetPlanSteps": [
            {"order": 1, "title": "step title", "detail": "what to do", "estimatedMinutes": <int>, "impactNote": "why it matters"},
            {"order": 2, "title": "step title", "detail": "what to do", "estimatedMinutes": <int>, "impactNote": "why it matters"},
            {"order": 3, "title": "step title", "detail": "what to do", "estimatedMinutes": <int>, "impactNote": "why it matters"},
            {"order": 4, "title": "step title", "detail": "what to do", "estimatedMinutes": <int>, "impactNote": "why it matters"}
          ],
          "estimatedResetMinutes": <int>,
          "visualizationConcept": {
            "projectedImprovedScore": <int>,
            "promptSummary": "describe the ideal improved version in one sentence",
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
                "removeItems": ["item 1", "item 2", "item 3"],
                "hideItems": ["item 1", "item 2"],
                "addItems": ["item 1", "item 2"],
                "quickWins": ["win 1", "win 2", "win 3"],
                "showingDayChecklist": [
                  {"title": "task 1", "priority": 1},
                  {"title": "task 2", "priority": 1},
                  {"title": "task 3", "priority": 2}
                ]
              }
            """
        }

        prompt += "\n}"
        return prompt
    }

    private func buildMessages(prompt: String, imageData: Data?) -> [[String: Any]] {
        var content: [[String: Any]] = [
            ["type": "text", "text": prompt]
        ]

        if let imageData {
            let base64 = imageData.base64EncodedString()
            content.insert([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(base64)", "detail": "high"]
            ], at: 0)
        } else {
            content.insert([
                "type": "text",
                "text": "[No image provided — generate a plausible demonstration analysis.]"
            ], at: 0)
        }

        return [["role": "user", "content": content]]
    }

    // MARK: - Network

    private func post(payload: [String: Any]) async throws -> Data {
        var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AppError.network("OpenAI returned an unexpected status. \(body)")
        }

        return data
    }

    // MARK: - Response parsing

    private func parseResponse(data: Data, request: AnalysisRequest) throws -> SpaceAnalysis {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String,
            let contentData = JSONResponseSanitizer.clean(content).data(using: .utf8),
            let parsed = try JSONSerialization.jsonObject(with: contentData) as? [String: Any]
        else {
            throw AppError.parsing("Could not parse OpenAI response structure.")
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
                conceptCaption: vc["conceptCaption"] as? String ?? ""
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
            providerPrimary: .openAI,
            providerSecondary: nil,
            rawInputSummary: parsed["rawInputSummary"] as? String ?? "",
            score: breakdown,
            summaryText: parsed["summaryText"] as? String ?? "",
            supportiveCoachingText: "",
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
