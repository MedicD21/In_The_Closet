import Foundation

@MainActor
protocol AnthropicCoachingProviding {
    func supportiveCoaching(for request: AnalysisRequest, analysis: SpaceAnalysis) async throws -> String
}

final class AnthropicCoachingProvider: AnthropicCoachingProviding {
    private let config: AppConfig
    private let session: URLSession

    init(config: AppConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func supportiveCoaching(for request: AnalysisRequest, analysis: SpaceAnalysis) async throws -> String {
        guard config.hasAnthropicKey else {
            throw AppError.configuration("Anthropic is not configured yet. Add ANTHROPIC_API_KEY to enable the coaching layer.")
        }

        let prompt = buildPrompt(for: request, analysis: analysis)

        let payload: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 300,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        let data = try await post(payload: payload)
        return try parseResponse(data: data)
    }

    // MARK: - Prompt

    private func buildPrompt(for request: AnalysisRequest, analysis: SpaceAnalysis) -> String {
        let roomName = request.customSpaceName?.isEmpty == false ? request.customSpaceName! : request.spaceType.displayName
        let score = analysis.score.totalScore
        let opportunitiesList = analysis.bestOpportunities.joined(separator: ", ")

        return """
        You are a warm, encouraging home organization coach helping someone reset their \(roomName).
        Their space scored \(score)/100. The biggest opportunities are: \(opportunitiesList).
        The project mode is: \(request.mode.longLabel).

        Write 2-3 sentences of genuinely supportive coaching that:
        - Acknowledges what they've already done or the effort it takes to start
        - Gives them confidence to take the next step
        - Feels personal and warm, not generic
        - Avoids toxic positivity — be real but kind

        Respond with just the coaching text. No greeting, no preamble, no sign-off.
        """
    }

    // MARK: - Network

    private func post(payload: [String: Any]) async throws -> Data {
        var urlRequest = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AppError.network("Anthropic returned an unexpected status. \(body)")
        }

        return data
    }

    // MARK: - Parsing

    private func parseResponse(data: Data) throws -> String {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let first = content.first,
            let text = first["text"] as? String
        else {
            throw AppError.parsing("Could not parse Anthropic response structure.")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
