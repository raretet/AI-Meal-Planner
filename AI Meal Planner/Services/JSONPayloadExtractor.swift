import Foundation

enum JSONPayloadExtractor {
    static func data(from raw: String) -> Data? {
        var t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            t = String(t.dropFirst(3))
            if let nl = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: nl)...])
            }
            if let fence = t.range(of: "```", options: .backwards) {
                t = String(t[..<fence.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        guard let start = t.firstIndex(of: "{"),
              let end = t.lastIndex(of: "}") else { return nil }
        return String(t[start...end]).data(using: .utf8)
    }
}
