import Foundation

enum SpaceType: String, Codable, CaseIterable, Identifiable {
    case pantry
    case closet
    case drawer
    case bathroom
    case garage
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pantry: "Pantry"
        case .closet: "Closet"
        case .drawer: "Drawer"
        case .bathroom: "Bathroom"
        case .garage: "Garage"
        case .custom: "Custom"
        }
    }

    var iconName: String {
        switch self {
        case .pantry: "cabinet"
        case .closet: "hanger"
        case .drawer: "shippingbox"
        case .bathroom: "drop.fill"
        case .garage: "wrench.and.screwdriver"
        case .custom: "sparkles.rectangle.stack"
        }
    }

    var searchKeywords: [String] {
        switch self {
        case .pantry: ["clear pantry bins", "turntable organizer", "pantry labels", "shelf riser"]
        case .closet: ["matching hangers", "shelf dividers", "closet bins", "under shelf basket"]
        case .drawer: ["drawer organizer", "modular tray", "drawer label clips", "non slip liner"]
        case .bathroom: ["bathroom canister", "under sink organizer", "lazy susan", "tray organizer"]
        case .garage: ["heavy duty storage bin", "wall hooks", "label holder", "shelf tote"]
        case .custom: ["storage bins", "label maker", "clear container", "basket organizer"]
        }
    }
}

enum ProjectMode: String, Codable, CaseIterable, Identifiable {
    case organize
    case stageForSelling
    case compareProgress

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .organize: "Organize"
        case .stageForSelling: "Stage"
        case .compareProgress: "Compare"
        }
    }

    var longLabel: String {
        switch self {
        case .organize: "Organize"
        case .stageForSelling: "Stage for Selling / Showing"
        case .compareProgress: "Compare Progress"
        }
    }
}

enum ProjectStatus: String, Codable {
    case draft
    case analyzing
    case ready
    case archived
}

enum BudgetTier: String, Codable, CaseIterable, Identifiable {
    case budget
    case mid
    case premium

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .budget: "Budget Reset"
        case .mid: "Mid Reset"
        case .premium: "Premium Reset"
        }
    }
}

enum RecommendationCategory: String, Codable, CaseIterable, Identifiable {
    case containment
    case labels
    case risers
    case shelfDividers
    case baskets
    case stagingDecor
    case closetTools
    case drawerOrganizers

    var id: String { rawValue }

    var displayName: String {
        rawValue
            .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .capitalized
    }
}

enum Retailer: String, Codable {
    case amazon
}

enum AIProvider: String, Codable {
    case openAI
    case anthropic
    case mock
}

enum AppThemePreference: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

enum AuthMethod: String, Codable {
    case email
    case apple
    case google
    case guest
}

enum ProjectImageType: String, Codable {
    case before
    case after
    case generatedPreview
    case stagingPreview
}

struct UserProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var email: String
    var displayName: String
    var avatarURL: URL?
    var createdAt: Date
    var updatedAt: Date
    var preferredTheme: AppThemePreference
    var preferredTone: String
    var onboardingCompleted: Bool
    var authMethod: AuthMethod
}

struct ProjectImage: Identifiable, Codable, Hashable {
    let id: UUID
    var projectID: UUID
    var userID: UUID
    var imageType: ProjectImageType
    var storagePath: String?
    var remoteURL: URL?
    var localAssetName: String?
    var createdAt: Date
}

struct SpaceProject: Identifiable, Codable, Hashable {
    let id: UUID
    var userID: UUID
    var title: String
    var spaceType: SpaceType
    var customSpaceName: String?
    var mode: ProjectMode
    var status: ProjectStatus
    var currentScore: Int?
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?
    var images: [ProjectImage]
    var analyses: [SpaceAnalysis]
    var comparisons: [ProjectComparison]
    var savedProducts: [ProductRecommendation]
    var stagingChecklist: StagingChecklist?

    var latestAnalysis: SpaceAnalysis? {
        analyses.sorted(by: { $0.createdAt > $1.createdAt }).first
    }
}

struct UploadDraft: Codable, Hashable {
    var spaceType: SpaceType = .pantry
    var customSpaceName: String = ""
    var mode: ProjectMode = .organize
    var selectedImageData: Data?
    var imageAssetName: String?
    var existingProjectID: UUID?

    var title: String {
        if spaceType == .custom, !customSpaceName.isEmpty {
            return customSpaceName
        }

        return spaceType.displayName
    }
}
