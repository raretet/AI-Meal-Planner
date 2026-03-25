import Foundation

struct SavedPlanBookmark: Codable, Identifiable {
    let id: UUID
    var name: String
    let createdAt: Date
    var daily: DailyPlanResponse?
    var weekly: WeeklyPlanResponse?

    var subtitleLine: String {
        if daily != nil {
            let k = daily?.summary.dailyCalories ?? 0
            return "День · \(k) ккал"
        }
        if weekly != nil {
            let k = weekly?.summary.dailyCalories ?? 0
            let days = weekly?.summary.days ?? 0
            return "Неделя · \(days) дн. · \(k) ккал/день"
        }
        return ""
    }
}

enum ActiveSavedBookmarkStorage {
    private static let key = "active_saved_bookmark_id_v1"

    static func load() -> UUID? {
        guard let s = UserDefaults.standard.string(forKey: key),
              let u = UUID(uuidString: s) else { return nil }
        return u
    }

    static func save(_ id: UUID?) {
        if let id {
            UserDefaults.standard.set(id.uuidString, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

enum SavedPlansLibraryStorage {
    private static let key = "saved_plans_library_v1"

    static func load() -> [SavedPlanBookmark] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([SavedPlanBookmark].self, from: data) else {
            return []
        }
        return list
    }

    static func save(_ items: [SavedPlanBookmark]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
