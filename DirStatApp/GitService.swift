import Foundation

actor GitService {
    func fetchGitData(directoryPath: String, baseBranch: String) -> GitData {
        var data = GitData()
        data.baseBranch = baseBranch

        guard FileManager.default.fileExists(atPath: directoryPath + "/.git") else {
            data.errorMessage = "Not a git repository"
            return data
        }

        data.currentBranch = run("git", args: ["symbolic-ref", "--short", "HEAD"], in: directoryPath)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        data.latestCommitMessage = run("git", args: ["log", "-1", "--format=%s"], in: directoryPath)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if let aheadBehind = run("git", args: ["rev-list", "--count", "--left-right", "\(baseBranch)...HEAD"], in: directoryPath)?
            .trimmingCharacters(in: .whitespacesAndNewlines) {
            let parts = aheadBehind.split(separator: "\t")
            if parts.count == 2 {
                data.behindCount = Int(parts[0]) ?? 0
                data.aheadCount = Int(parts[1]) ?? 0
            }
        }

        data.unstagedStats = parseStats(
            numstat: run("git", args: ["diff", "--numstat"], in: directoryPath),
            nameOnly: run("git", args: ["diff", "--name-only"], in: directoryPath)
        )

        data.stagedStats = parseStats(
            numstat: run("git", args: ["diff", "--cached", "--numstat"], in: directoryPath),
            nameOnly: run("git", args: ["diff", "--cached", "--name-only"], in: directoryPath)
        )

        if let graphOutput = run("git", args: [
            "log", "--graph", "--format=format:%h§%d§%s", "--boundary",
            "\(baseBranch)...HEAD"
        ], in: directoryPath) {
            data.graphEntries = GitGraphParser.parse(graphOutput)
        }

        data.branches = parseBranches(directoryPath: directoryPath)

        return data
    }

    func fetchBranches(directoryPath: String) -> [BranchInfo] {
        parseBranches(directoryPath: directoryPath)
    }

    private func parseBranches(directoryPath: String) -> [BranchInfo] {
        guard let output = run("git", args: ["branch", "--all", "--format=%(refname:short)"], in: directoryPath) else {
            return []
        }
        return output
            .split(separator: "\n")
            .map { line -> BranchInfo in
                let name = String(line).trimmingCharacters(in: .whitespaces)
                let isRemote = name.hasPrefix("origin/")
                return BranchInfo(name: name, isRemote: isRemote)
            }
            .filter { !$0.name.isEmpty }
    }

    private func parseStats(numstat: String?, nameOnly: String?) -> FileStats {
        var stats = FileStats()
        if let nameOnly {
            stats.fileCount = nameOnly.split(separator: "\n").count
            if nameOnly.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                stats.fileCount = 0
            }
        }
        if let numstat {
            for line in numstat.split(separator: "\n") {
                let parts = line.split(separator: "\t")
                if parts.count >= 2 {
                    stats.additions += Int(parts[0]) ?? 0
                    stats.deletions += Int(parts[1]) ?? 0
                }
            }
        }
        return stats
    }

    private func run(_ command: String, args: [String], in directory: String) -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + args
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
