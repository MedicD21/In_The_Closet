import Foundation

struct AmazonAffiliateLinkBuilder {
    let baseURL: URL
    let associateTag: String

    func searchURL(for query: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) ?? URLComponents()
        components.path = "/s"
        components.queryItems = [
            URLQueryItem(name: "k", value: query),
            URLQueryItem(name: "tag", value: associateTag)
        ]
        return components.url ?? baseURL
    }
}
