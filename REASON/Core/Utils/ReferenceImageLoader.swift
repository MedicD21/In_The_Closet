import Foundation
import UIKit

enum ReferenceImageLoader {
    private static let mapping: [String: (fileName: String, fileExtension: String)] = [
        "PantrySample": ("pantry-sample", "jpeg"),
        "HomeMockup": ("home-mockup", "png"),
        "ResultsMockup": ("results-mockup", "png")
    ]

    static func uiImage(named name: String) -> UIImage? {
        if let image = UIImage(named: name) {
            return image
        }

        guard let url = bundleURL(named: name) else {
            return nil
        }

        return UIImage(contentsOfFile: url.path)
    }

    static func imageData(named name: String) -> Data? {
        if let url = bundleURL(named: name) {
            return try? Data(contentsOf: url)
        }

        guard let image = UIImage(named: name) else {
            return nil
        }

        return image.pngData() ?? image.jpegData(compressionQuality: 0.96)
    }

    static func normalizedJPEGData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else {
            return nil
        }

        return image.jpegData(compressionQuality: 0.94)
    }

    private static func bundleURL(named name: String) -> URL? {
        guard let file = mapping[name] else {
            return nil
        }

        return Bundle.main.url(forResource: file.fileName, withExtension: file.fileExtension)
    }
}
