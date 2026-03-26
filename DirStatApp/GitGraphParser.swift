import Foundation

nonisolated enum GitGraphParser {
    static func parse(_ output: String) -> [GitGraphEntry] {
        var entries: [GitGraphEntry] = []
        for line in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let lineStr = String(line)
            let entry = parseLine(lineStr)
            entries.append(entry)
        }
        return entries
    }

    private static func parseLine(_ line: String) -> GitGraphEntry {
        var graphPrefix = ""
        var commitData = ""

        // Look for the section marker §
        if let sectionRange = line.range(of: "§") {
            let beforeSection = String(line[line.startIndex..<sectionRange.lowerBound])
            if let lastSpace = beforeSection.lastIndex(where: { " /\\|*_".contains($0) }) {
                let afterLastGraphChar = beforeSection.index(after: lastSpace)
                graphPrefix = String(beforeSection[beforeSection.startIndex...lastSpace])
                let hashPart = String(beforeSection[afterLastGraphChar...])
                commitData = hashPart + String(line[sectionRange.lowerBound...])
            } else {
                commitData = line
            }
        } else {
            graphPrefix = line
        }

        // Parse commit data: hash§refs§message
        let parts = commitData.split(separator: "§", maxSplits: 2, omittingEmptySubsequences: false)
        let hash = parts.count > 0 ? String(parts[0]).trimmingCharacters(in: .whitespaces) : ""
        let refs = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
        let message = parts.count > 2 ? String(parts[2]).trimmingCharacters(in: .whitespaces) : ""

        let isBoundary = graphPrefix.contains("o") || hash.hasPrefix("-")
        let cleanHash = hash.hasPrefix("-") ? String(hash.dropFirst()) : hash

        return GitGraphEntry(
            graphPrefix: graphPrefix,
            hash: cleanHash,
            refs: refs,
            message: message,
            isBoundary: isBoundary
        )
    }
}
