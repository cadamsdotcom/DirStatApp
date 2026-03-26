import Foundation

struct WindowState: Codable, Identifiable, Sendable {
    let id: UUID
    var directoryPath: String?
    var baseBranch: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var alpha: Double

    nonisolated init(
        id: UUID = UUID(),
        directoryPath: String? = nil,
        baseBranch: String = "main",
        x: Double = 100,
        y: Double = 100,
        width: Double = 420,
        height: Double = 500,
        alpha: Double = 1.0
    ) {
        self.id = id
        self.directoryPath = directoryPath
        self.baseBranch = baseBranch
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.alpha = alpha
    }
}

struct GitData: Sendable {
    var currentBranch: String = ""
    var latestCommitMessage: String = ""
    var aheadCount: Int = 0
    var behindCount: Int = 0
    var baseBranch: String = "main"
    var unstagedStats: FileStats = FileStats()
    var stagedStats: FileStats = FileStats()
    var graphEntries: [GitGraphEntry] = []
    var branches: [BranchInfo] = []
    var errorMessage: String? = nil

    nonisolated init() {}
}

struct FileStats: Sendable {
    var fileCount: Int = 0
    var additions: Int = 0
    var deletions: Int = 0

    nonisolated init() {}
}

struct BranchInfo: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let isRemote: Bool

    nonisolated init(name: String, isRemote: Bool) {
        self.name = name
        self.isRemote = isRemote
    }
}

struct GitGraphEntry: Identifiable, Sendable {
    let id = UUID()
    let graphPrefix: String
    let hash: String
    let refs: String
    let message: String
    let isBoundary: Bool

    nonisolated init(graphPrefix: String, hash: String, refs: String, message: String, isBoundary: Bool) {
        self.graphPrefix = graphPrefix
        self.hash = hash
        self.refs = refs
        self.message = message
        self.isBoundary = isBoundary
    }
}
