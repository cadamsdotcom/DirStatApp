import SwiftUI

struct DirStatView: View {
    @Bindable var controller: WindowController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let path = controller.state.directoryPath {
                // Directory path
                Text(abbreviatePath(path))
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let error = controller.gitData.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                } else {
                    // Latest commit message
                    Text(controller.gitData.latestCommitMessage)
                        .font(.system(size: 12, weight: .regular).italic())
                        .foregroundStyle(.blue)
                        .lineLimit(1)

                    // Branch info
                    Text("On branch \(controller.gitData.currentBranch)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    // Ahead/behind
                    aheadBehindView

                    Divider().padding(.vertical, -2)

                    // Git graph
                    GitGraphView(entries: controller.gitData.graphEntries)
                        .clipped()

                    Divider().padding(.vertical, -2)

                    // File stats
                    statsView
                }
            } else {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("Click to choose a directory")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var aheadBehindView: some View {
        let ahead = controller.gitData.aheadCount
        let behind = controller.gitData.behindCount
        let base = controller.gitData.baseBranch

        if ahead > 0 || behind > 0 {
            HStack(spacing: 4) {
                if ahead > 0 {
                    Text("\(ahead) commit\(ahead == 1 ? "" : "s") ahead")
                        .foregroundStyle(.green)
                }
                if ahead > 0 && behind > 0 {
                    Text(",")
                }
                if behind > 0 {
                    Text("\(behind) behind")
                        .foregroundStyle(.red)
                }
                Text(base)
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 12))
        }
    }

    @ViewBuilder
    private var statsView: some View {
        let unstaged = controller.gitData.unstagedStats
        let staged = controller.gitData.stagedStats
        let untracked = controller.gitData.untrackedCount

        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text("Staged: \(staged.fileCount) \(staged.fileCount == 1 ? "file" : "files"),")
                    .font(.system(size: 11))
                Text("+\(formatNumber(staged.additions))")
                    .foregroundStyle(.green)
                    .font(.system(size: 11, design: .monospaced))
                Text("/ -\(formatNumber(staged.deletions))")
                    .foregroundStyle(.red)
                    .font(.system(size: 11, design: .monospaced))
            }
            HStack(spacing: 4) {
                Text("Unstaged: \(unstaged.fileCount) \(unstaged.fileCount == 1 ? "file" : "files"),")
                    .font(.system(size: 11))
                Text("+\(formatNumber(unstaged.additions))")
                    .foregroundStyle(.green)
                    .font(.system(size: 11, design: .monospaced))
                Text("/ -\(formatNumber(unstaged.deletions))")
                    .foregroundStyle(.red)
                    .font(.system(size: 11, design: .monospaced))
            }
            Text("Untracked: \(untracked) \(untracked == 1 ? "file" : "files")")
                .font(.system(size: 11))
        }
    }

    private func abbreviatePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
