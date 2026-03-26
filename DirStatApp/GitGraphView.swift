import SwiftUI
import AppKit

struct GitGraphView: View {
    let entries: [GitGraphEntry]

    private let minRowHeight: CGFloat = 22
    private let colWidth: CGFloat = 14
    private let dotInset: CGFloat = 5
    private let graphColors: [Color] = [.blue, .green, .red, .orange, .purple, .cyan]

    var body: some View {
        if entries.isEmpty {
            Text("No graph data")
                .foregroundStyle(.secondary)
                .font(.caption)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    let isGraphOnly = entry.hash.isEmpty && entry.message.isEmpty
                    let graphChars = Array(entry.graphPrefix.filter { $0 != " " })
                    let graphWidth = CGFloat(graphChars.count) * colWidth + dotInset

                    if isGraphOnly {
                        Canvas { context, size in
                            drawGraphRow(context: &context, chars: graphChars, rowH: size.height, anchorY: size.height / 2)
                        }
                        .frame(height: 10)
                    } else {
                        // Text drives the height; Canvas overlays for graph lines
                        HStack(alignment: .top, spacing: 4) {
                            if !entry.hash.isEmpty {
                                Text(entry.hash)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.orange)
                                    .fixedSize()
                            }

                            let cr = cleanRefs(entry.refs)
                            if !cr.isEmpty {
                                Text(" \(cr) ")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 2)
                                    .padding(.vertical, 1)
                                    .background(RoundedRectangle(cornerRadius: 3).fill(.blue.opacity(0.7)))
                            }

                            if !entry.message.isEmpty {
                                Text(entry.message)
                                    .font(.system(size: 11))
                                    .foregroundColor(entry.isBoundary ? .secondary : .primary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.leading, graphWidth)
                        .frame(maxWidth: .infinity, minHeight: minRowHeight, alignment: .topLeading)
                        .overlay(alignment: .topLeading) {
                            Canvas { context, size in
                                drawGraphRow(context: &context, chars: graphChars, rowH: size.height, anchorY: 9)
                            }
                            .frame(width: graphWidth)
                        }
                    }
                }
            }
        }
    }

    private func drawGraphRow(context: inout GraphicsContext, chars: [Character], rowH: CGFloat, anchorY: CGFloat) {
        for (col, char) in chars.enumerated() {
            let color = graphColors[col % graphColors.count]
            let cx = CGFloat(col) * colWidth + dotInset

            switch char {
            case "*":
                // Draw connecting line through the full row, then dot on top
                context.stroke(Path { p in p.move(to: CGPoint(x: cx, y: 0)); p.addLine(to: CGPoint(x: cx, y: rowH)) }, with: .color(color), lineWidth: 1.5)
                context.fill(Circle().path(in: CGRect(x: cx - 4, y: anchorY - 4, width: 8, height: 8)), with: .color(color))
            case "o":
                // Draw connecting line, then white-filled circle with colored border
                context.stroke(Path { p in p.move(to: CGPoint(x: cx, y: 0)); p.addLine(to: CGPoint(x: cx, y: rowH)) }, with: .color(color), lineWidth: 1.5)
                context.fill(Circle().path(in: CGRect(x: cx - 4, y: anchorY - 4, width: 8, height: 8)), with: .color(.white))
                context.stroke(Circle().path(in: CGRect(x: cx - 4, y: anchorY - 4, width: 8, height: 8)), with: .color(color), lineWidth: 2)
            case "|":
                context.stroke(Path { p in p.move(to: CGPoint(x: cx, y: 0)); p.addLine(to: CGPoint(x: cx, y: rowH)) }, with: .color(color), lineWidth: 1.5)
            case "/":
                // Connects current column (top) to previous column (bottom)
                let prevCx = col > 0 ? CGFloat(col - 1) * colWidth + dotInset : dotInset
                context.stroke(Path { p in p.move(to: CGPoint(x: cx, y: 0)); p.addLine(to: CGPoint(x: prevCx, y: rowH)) }, with: .color(color), lineWidth: 1.5)
            case "\\":
                // Connects previous column (top) to current column (bottom)
                let prevCx = col > 0 ? CGFloat(col - 1) * colWidth + dotInset : dotInset
                context.stroke(Path { p in p.move(to: CGPoint(x: prevCx, y: 0)); p.addLine(to: CGPoint(x: cx, y: rowH)) }, with: .color(color), lineWidth: 1.5)
            case "_":
                context.stroke(Path { p in p.move(to: CGPoint(x: cx - colWidth / 2, y: anchorY)); p.addLine(to: CGPoint(x: cx + colWidth / 2, y: anchorY)) }, with: .color(color), lineWidth: 1.5)
            default:
                break
            }
        }
    }

    private func cleanRefs(_ refs: String) -> String {
        refs.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespaces)
    }
}
