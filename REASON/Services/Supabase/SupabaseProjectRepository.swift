import Foundation
import Supabase

final class SupabaseProjectRepository: ProjectRepository {
    private let clientFactory: SupabaseClientFactory

    init(clientFactory: SupabaseClientFactory) {
        self.clientFactory = clientFactory
    }

    func fetchProjects(for userID: UUID) async throws -> [SpaceProject] {
        _ = try clientFactory.makeClient()
        throw AppError.unavailable("Supabase project fetches need the final row mapping and storage URL strategy.")
    }

    func save(project: SpaceProject) async throws -> SpaceProject {
        _ = try clientFactory.makeClient()
        throw AppError.unavailable("Supabase project persistence is scaffolded but still needs the final insert and update calls.")
    }

    func delete(projectID: UUID, for userID: UUID) async throws {
        _ = try clientFactory.makeClient()
        throw AppError.unavailable("Supabase project deletion should be completed alongside storage cleanup.")
    }
}
