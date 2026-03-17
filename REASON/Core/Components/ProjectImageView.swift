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
                if let uiImage = ReferenceImageLoader.uiImage(named: localAssetName) {
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
                        colors: [BrandColor.tealMuted.opacity(0.35), BrandColor.gold.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(BrandColor.textPrimary.opacity(0.5))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}
