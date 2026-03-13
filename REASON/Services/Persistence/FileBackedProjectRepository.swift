import Foundation

final class FileBackedProjectRepository: ProjectRepository {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func fetchProjects(for userID: UUID) async throws -> [SpaceProject] {
        let stored = try loadAllProjects()
        return stored.filter { $0.userID == userID }.sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    func save(project: SpaceProject) async throws -> SpaceProject {
        var allProjects = try loadAllProjects()
        if let index = allProjects.firstIndex(where: { $0.id == project.id }) {
            allProjects[index] = project
        } else {
            allProjects.append(project)
        }
        try persist(allProjects: allProjects)
        return project
    }

    func delete(projectID: UUID, for userID: UUID) async throws {
        let allProjects = try loadAllProjects()
            .filter { !($0.id == projectID && $0.userID == userID) }
        try persist(allProjects: allProjects)
    }

    private func loadAllProjects() throws -> [SpaceProject] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([SpaceProject].self, from: data)
    }

    private func persist(allProjects: [SpaceProject]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(allProjects)
        try data.write(to: fileURL, options: .atomic)
    }

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("reason/projects.json")
    }
}
