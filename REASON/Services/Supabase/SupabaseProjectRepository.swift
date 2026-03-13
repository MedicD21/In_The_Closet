import Foundation
import Supabase

final class SupabaseProjectRepository: ProjectRepository {
    private let clientFactory: SupabaseClientFactory

    init(clientFactory: SupabaseClientFactory) {
        self.clientFactory = clientFactory
    }

    // MARK: - Fetch

    func fetchProjects(for userID: UUID) async throws -> [SpaceProject] {
        let client = try clientFactory.makeClient()

        struct ProjectRow: Decodable {
            let id: UUID
            let user_id: UUID
            let title: String
            let space_type: String
            let custom_space_name: String?
            let mode: String
            let status: String
            let current_score: Int?
            let created_at: Date
            let updated_at: Date
            let archived_at: Date?
        }

        let rows: [ProjectRow] = try await client
            .from("projects")
            .select()
            .eq("user_id", value: userID.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value

        return rows.map { row in
            SpaceProject(
                id: row.id,
                userID: row.user_id,
                title: row.title,
                spaceType: SpaceType(rawValue: row.space_type) ?? .custom,
                customSpaceName: row.custom_space_name,
                mode: ProjectMode(rawValue: row.mode) ?? .organize,
                status: ProjectStatus(rawValue: row.status) ?? .draft,
                currentScore: row.current_score,
                createdAt: row.created_at,
                updatedAt: row.updated_at,
                archivedAt: row.archived_at,
                images: [],
                analyses: [],
                comparisons: [],
                savedProducts: [],
                stagingChecklist: nil
            )
        }
    }

    // MARK: - Save

    func save(project: SpaceProject) async throws -> SpaceProject {
        let client = try clientFactory.makeClient()

        struct ProjectUpsert: Encodable {
            let id: String
            let user_id: String
            let title: String
            let space_type: String
            let custom_space_name: String?
            let mode: String
            let status: String
            let current_score: Int?
            let updated_at: Date
        }

        let upsertRow = ProjectUpsert(
            id: project.id.uuidString,
            user_id: project.userID.uuidString,
            title: project.title,
            space_type: project.spaceType.rawValue,
            custom_space_name: project.customSpaceName,
            mode: project.mode.rawValue,
            status: project.status.rawValue,
            current_score: project.currentScore,
            updated_at: .now
        )

        try await client
            .from("projects")
            .upsert(upsertRow)
            .execute()

        return SpaceProject(
            id: project.id,
            userID: project.userID,
            title: project.title,
            spaceType: project.spaceType,
            customSpaceName: project.customSpaceName,
            mode: project.mode,
            status: project.status,
            currentScore: project.currentScore,
            createdAt: project.createdAt,
            updatedAt: .now,
            archivedAt: project.archivedAt,
            images: project.images,
            analyses: project.analyses,
            comparisons: project.comparisons,
            savedProducts: project.savedProducts,
            stagingChecklist: project.stagingChecklist
        )
    }

    // MARK: - Delete

    func delete(projectID: UUID, for userID: UUID) async throws {
        let client = try clientFactory.makeClient()
        try await client
            .from("projects")
            .delete()
            .eq("id", value: projectID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .execute()
    }
}
