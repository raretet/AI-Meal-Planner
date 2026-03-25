import Foundation

extension KeyedDecodingContainer {
    func decodeFlexibleInt(forKey key: Key) throws -> Int {
        if let i = try? decode(Int.self, forKey: key) { return i }
        if let d = try? decode(Double.self, forKey: key) { return Int(d.rounded()) }
        if let s = try? decode(String.self, forKey: key) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if let i = Int(t) { return i }
            if let d = Double(t) { return Int(d.rounded()) }
        }
        throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected number")
    }

    func decodeFlexibleIntIfPresent(forKey key: Key, default def: Int) -> Int {
        guard contains(key) else { return def }
        return (try? decodeFlexibleInt(forKey: key)) ?? def
    }
}
