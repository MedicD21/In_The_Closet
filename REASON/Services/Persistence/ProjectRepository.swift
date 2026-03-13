import Foundation

@MainActor
protocol ProjectRepository {
    func fetchProjects(for userID: UUID) async throws -> [SpaceProject]
    func save(project: SpaceProject) async throws -> SpaceProject
    func delete(projectID: UUID, for userID: UUID) async throws
}

final class ResilientProjectRepository: ProjectRepository {
    private let primary: ProjectRepository?
    private let fallback: ProjectRepository

    init(primary: ProjectRepository?, fallback: ProjectRepository) {
        self.primary = primary
        self.fallback = fallback
    }

    func fetchProjects(for userID: UUID) async throws -> [SpaceProject] {
        if let primary {
            do {
                return try await primary.fetchProjects(for: userID)
            } catch {
                return try await fallback.fetchProjects(for: userID)
            }
        }

        return try await fallback.fetchProjects(for: userID)
    }

    func save(project: SpaceProject) async throws -> SpaceProject {
        if let primary {
            do {
                return try await primary.save(project: project)
            } catch {
                return try await fallback.save(project: project)
            }
        }

        return try await fallback.save(project: project)
    }

    func delete(projectID: UUID, for userID: UUID) async throws {
        if let primary {
            do {
                try await primary.delete(projectID: projectID, for: userID)
                return
            } catch {
                try await fallback.delete(projectID: projectID, for: userID)
                return
            }
        }

        try await fallback.delete(projectID: projectID, for: userID)
    }
}
