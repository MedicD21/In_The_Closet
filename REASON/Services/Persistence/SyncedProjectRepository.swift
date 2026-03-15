import Foundation

@MainActor
final class SyncedProjectRepository: ProjectRepository {
    private let remote: ProjectRepository
    private let cache: ProjectRepository

    init(remote: ProjectRepository, cache: ProjectRepository) {
        self.remote = remote
        self.cache = cache
    }

    func fetchProjects(for userID: UUID) async throws -> [SpaceProject] {
        AppConsole.projects.notice("fetching remote projects for userID=\(userID.uuidString, privacy: .public)")
        let remoteProjects = try await remote.fetchProjects(for: userID)
        let cachedProjects = (try? await cache.fetchProjects(for: userID)) ?? []
        let cachedByID = Dictionary(uniqueKeysWithValues: cachedProjects.map { ($0.id, $0) })
        AppConsole.projects.notice("remote fetch returned \(remoteProjects.count, privacy: .public) rows and cache has \(cachedProjects.count, privacy: .public)")

        return remoteProjects
            .map { remoteProject in
                guard let cachedProject = cachedByID[remoteProject.id] else {
                    return remoteProject
                }
                return merge(remote: remoteProject, cached: cachedProject)
            }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    func save(project: SpaceProject) async throws -> SpaceProject {
        AppConsole.projects.notice("sync save starting projectID=\(project.id.uuidString, privacy: .public)")
        let remoteProject = try await remote.save(project: project)
        let mergedProject = merge(remote: remoteProject, cached: project)
        _ = try? await cache.save(project: mergedProject)
        AppConsole.projects.notice("sync save completed projectID=\(mergedProject.id.uuidString, privacy: .public)")
        return mergedProject
    }

    func delete(projectID: UUID, for userID: UUID) async throws {
        AppConsole.projects.notice("sync delete starting projectID=\(projectID.uuidString, privacy: .public)")
        try await remote.delete(projectID: projectID, for: userID)
        try? await cache.delete(projectID: projectID, for: userID)
        AppConsole.projects.notice("sync delete completed projectID=\(projectID.uuidString, privacy: .public)")
    }

    private func merge(remote: SpaceProject, cached: SpaceProject) -> SpaceProject {
        SpaceProject(
            id: remote.id,
            userID: remote.userID,
            title: remote.title,
            spaceType: remote.spaceType,
            customSpaceName: remote.customSpaceName,
            mode: remote.mode,
            status: remote.status,
            currentScore: remote.currentScore ?? cached.currentScore,
            createdAt: remote.createdAt,
            updatedAt: remote.updatedAt,
            archivedAt: remote.archivedAt,
            images: cached.images,
            analyses: cached.analyses,
            comparisons: cached.comparisons,
            savedProducts: cached.savedProducts,
            stagingChecklist: cached.stagingChecklist
        )
    }
}
