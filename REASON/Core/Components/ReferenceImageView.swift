import SwiftUI
import UIKit

struct ReferenceImageView: View {
    let assetName: String
    let bundleFileName: String
    let fileExtension: String

    var body: some View {
        if let uiImage = UIImage(named: assetName) ?? loadBundleImage() {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(BrandColor.elevatedBackground(for: .light))
                Image(systemName: "photo")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(BrandColor.secondaryText(for: .light))
            }
        }
    }

    private func loadBundleImage() -> UIImage? {
        guard let url = Bundle.main.url(forResource: bundleFileName, withExtension: fileExtension) else {
            return nil
        }

        return UIImage(contentsOfFile: url.path)
    }
}
