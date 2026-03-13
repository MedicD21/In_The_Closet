import SwiftUI
import UIKit

struct ProjectImageView: View {
    let projectImage: ProjectImage?
    var imageData: Data? = nil

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let localAssetName = projectImage?.localAssetName {
                if let uiImage = UIImage(named: localAssetName) ?? referenceUIImage(for: localAssetName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
            } else if let storagePath = projectImage?.storagePath,
                      let uiImage = UIImage(contentsOfFile: storagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [BrandColor.softTeal.opacity(0.35), BrandColor.gold.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(BrandColor.primaryText(for: .light).opacity(0.5))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func referenceUIImage(for localAssetName: String) -> UIImage? {
        let mapping: [String: (String, String)] = [
            "PantrySample": ("pantry-sample", "jpeg"),
            "HomeMockup": ("home-mockup", "png"),
            "ResultsMockup": ("results-mockup", "png")
        ]

        guard let file = mapping[localAssetName],
              let url = Bundle.main.url(forResource: file.0, withExtension: file.1) else {
            return nil
        }

        return UIImage(contentsOfFile: url.path)
    }
}
