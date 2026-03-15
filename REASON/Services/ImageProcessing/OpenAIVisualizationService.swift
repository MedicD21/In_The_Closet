import Foundation
import UIKit

@MainActor
final class OpenAIVisualizationService: VisualizationService {
    private let config: AppConfig
    private let session: URLSession

    init(config: AppConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func generateVisualization(for project: SpaceProject, analysis: SpaceAnalysis) async throws -> VisualizationConcept {
        guard config.hasOpenAIKey else {
            throw AppError.configuration("OPENAI_API_KEY is not configured for live concept previews.")
        }

        guard let sourceImageData = try await loadReferenceImageData(for: project) else {
            throw AppError.validation("Choose a source photo before generating a concept preview.")
        }

        let baseConcept = baseConcept(for: project, analysis: analysis)
        let targetSize = renderSize(for: sourceImageData)
        AppConsole.visualization.notice("starting concept render projectID=\(project.id.uuidString, privacy: .public) analysisID=\(analysis.id.uuidString, privacy: .public) size=\(targetSize, privacy: .public)")
        let payload = try makePayload(
            prompt: buildPrompt(for: project, concept: baseConcept),
            imageData: sourceImageData,
            size: targetSize
        )
        let responseData = try await post(payload: payload)
        let renderedImageData = try await extractImageData(from: responseData)
        let savedURL = try await persist(renderedImageData, projectID: project.id, analysisID: analysis.id)
        AppConsole.visualization.notice("concept render saved to \(savedURL.path, privacy: .public)")

        return VisualizationConcept(
            projectedImprovedScore: baseConcept.projectedImprovedScore,
            promptSummary: baseConcept.promptSummary,
            whatImproved: baseConcept.whatImproved,
            stillNeedsWork: baseConcept.stillNeedsWork,
            conceptCaption: baseConcept.conceptCaption,
            generatedImageURL: savedURL
        )
    }

    private func baseConcept(for project: SpaceProject, analysis: SpaceAnalysis) -> VisualizationConcept {
        if let concept = analysis.visualizationConcept {
            return concept
        }

        return VisualizationConcept(
            projectedImprovedScore: min(100, analysis.score.totalScore + 14),
            promptSummary: "A calmer, more cohesive \(project.title.lowercased()) with stronger zoning and fewer visible distractions.",
            whatImproved: Array(analysis.bestOpportunities.prefix(3)),
            stillNeedsWork: Array(analysis.biggestProblems.prefix(2)),
            conceptCaption: "Live concept render based on your uploaded room photo.",
            generatedImageURL: nil
        )
    }

    private func buildPrompt(for project: SpaceProject, concept: VisualizationConcept) -> String {
        let improvements = concept.whatImproved.joined(separator: "; ")
        let remainingConstraints = concept.stillNeedsWork.joined(separator: "; ")

        return """
        Edit this exact room photo into a realistic "after" image for Reset My Space.
        Keep the same architecture, perspective, camera angle, furniture placement, windows, ceiling details, and core room structure.
        Do not redesign the room or add impossible features.
        Goal: \(project.mode.longLabel).
        Direction: \(concept.promptSummary)
        Improvements to emphasize: \(improvements.isEmpty ? "cleaner surfaces, stronger zoning, and better containment" : improvements)
        Keep realistic materials, realistic lighting, and the same room identity.
        Remaining constraints to respect: \(remainingConstraints.isEmpty ? "maintain realism and avoid over-styling" : remainingConstraints)
        Make it photorealistic, organized, calm, and believable for the same physical space.
        """
    }

    private func makePayload(prompt: String, imageData: Data, size: String) throws -> MultipartFormDataPayload {
        var payload = MultipartFormDataPayload()
        payload.addField(name: "model", value: "gpt-image-1.5")
        payload.addField(name: "prompt", value: prompt)
        payload.addField(name: "size", value: size)
        payload.addField(name: "quality", value: "low")
        payload.addField(name: "background", value: "auto")
        payload.addField(name: "output_format", value: "png")
        payload.addField(name: "input_fidelity", value: "high")
        payload.addFile(name: "image[]", fileName: "source.jpg", mimeType: "image/jpeg", data: imageData)
        return payload
    }

    private func renderSize(for imageData: Data) -> String {
        guard let image = UIImage(data: imageData) else {
            return "1024x1536"
        }

        if image.size.width > image.size.height {
            return "1536x1024"
        }

        if image.size.width == image.size.height {
            return "1024x1024"
        }

        return "1024x1536"
    }

    private func post(payload: MultipartFormDataPayload) async throws -> Data {
        let finalizedPayload = payload.finalized
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/images/edits")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue(finalizedPayload.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = finalizedPayload.body

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(empty)"
            throw AppError.network("OpenAI image generation failed: \(String(body.prefix(320)))")
        }

        return data
    }

    private func extractImageData(from data: Data) async throws -> Data {
        struct Response: Decodable {
            struct Item: Decodable {
                let b64_json: String?
                let url: String?
            }

            let data: [Item]
        }

        let response = try JSONDecoder().decode(Response.self, from: data)

        if let base64 = response.data.first?.b64_json,
           let decoded = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) {
            AppConsole.visualization.notice("concept render returned base64 payload bytes=\(decoded.count, privacy: .public)")
            return decoded
        }

        if let urlString = response.data.first?.url,
           let url = URL(string: urlString) {
            AppConsole.visualization.notice("concept render returned downloadable URL")
            let (imageData, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw AppError.network("OpenAI returned an image URL, but the rendered file could not be downloaded.")
            }
            AppConsole.visualization.notice("downloaded concept render bytes=\(imageData.count, privacy: .public)")
            return imageData
        }

        throw AppError.parsing("OpenAI did not return an image for the concept preview.")
    }

    private func persist(_ imageData: Data, projectID: UUID, analysisID: UUID) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("reason/generated-previews", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent("\(projectID.uuidString)-\(analysisID.uuidString).png")
            try imageData.write(to: fileURL, options: .atomic)
            return fileURL
        }.value
    }

    private func loadReferenceImageData(for project: SpaceProject) async throws -> Data? {
        let sourceImage = project.images.last ?? project.images.first

        if let storagePath = sourceImage?.storagePath {
            let fileURL = URL(fileURLWithPath: storagePath)
            let data = try await Task.detached(priority: .userInitiated) {
                try Data(contentsOf: fileURL)
            }.value
            AppConsole.visualization.notice("loaded source image from local storage path")
            return ReferenceImageLoader.normalizedJPEGData(from: data) ?? data
        }

        if let localAssetName = sourceImage?.localAssetName {
            let data = ReferenceImageLoader.imageData(named: localAssetName)
            AppConsole.visualization.notice("loaded source image from bundled asset=\(localAssetName, privacy: .public)")
            return data.flatMap { ReferenceImageLoader.normalizedJPEGData(from: $0) ?? $0 }
        }

        if let remoteURL = sourceImage?.remoteURL {
            let (data, response) = try await session.data(from: remoteURL)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw AppError.network("The source image could not be downloaded for concept generation.")
            }
            AppConsole.visualization.notice("loaded source image from remote URL")
            return ReferenceImageLoader.normalizedJPEGData(from: data) ?? data
        }

        return nil
    }
}

private struct MultipartFormDataPayload {
    private let boundary = "Boundary-\(UUID().uuidString)"
    private(set) var body = Data()

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    mutating func addField(name: String, value: String) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.appendString("\(value)\r\n")
    }

    mutating func addFile(name: String, fileName: String, mimeType: String, data: Data) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
    }

    private mutating func finalize() {
        body.appendString("--\(boundary)--\r\n")
    }

    init() { }

    var finalized: MultipartFormDataPayload {
        var copy = self
        copy.finalize()
        return copy
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
