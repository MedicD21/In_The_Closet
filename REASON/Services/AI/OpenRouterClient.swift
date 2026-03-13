import Foundation

struct OpenRouterClient: Sendable {
    let apiKey: String
    private let session: URLSession

    private static let chatEndpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private static let imageEndpoint = URL(string: "https://openrouter.ai/api/v1/images/generations")!

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Send a pre-serialized JSON payload to the chat completions endpoint.
    /// Callers serialize to Data on their own actor to satisfy Swift 6 sendability.
    func chat(payload: Data) async throws -> String {
        let data = try await post(body: payload, to: Self.chatEndpoint)
        return try extractTextContent(from: data)
    }

    /// Send a pre-serialized JSON payload to the image generations endpoint.
    func generateImage(payload: Data) async throws -> URL {
        let data = try await post(body: payload, to: Self.imageEndpoint)
        return try extractImageURL(from: data)
    }

    // MARK: - Private

    private func post(body: Data, to url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Reset My Space iOS", forHTTPHeaderField: "X-Title")
        request.httpBody = body

        let (responseData, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: responseData, encoding: .utf8) ?? "(empty)"
            throw AppError.network("OpenRouter error: \(String(body.prefix(300)))")
        }
        return responseData
    }

    private func extractTextContent(from data: Data) throws -> String {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw AppError.parsing("Unexpected OpenRouter chat response structure.")
        }
        return content
    }

    private func extractImageURL(from data: Data) throws -> URL {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let dataArr = json["data"] as? [[String: Any]],
            let first = dataArr.first,
            let urlString = first["url"] as? String,
            let url = URL(string: urlString)
        else {
            throw AppError.parsing("Unexpected OpenRouter image response structure.")
        }
        return url
    }
}
