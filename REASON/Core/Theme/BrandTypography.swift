import SwiftUI

enum BrandTypography {
    static let displayTitle = Font.custom("Georgia", size: 44).weight(.semibold)
    static let screenTitle  = Font.system(size: 28, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let body         = Font.system(size: 16, weight: .regular, design: .rounded)
    static let bodyStrong   = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let label        = Font.system(size: 13, weight: .semibold, design: .rounded)
    static let micro        = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let button       = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let score        = Font.system(size: 52, weight: .heavy, design: .rounded)
    static let scoreSmall   = Font.system(size: 32, weight: .heavy, design: .rounded)
}
