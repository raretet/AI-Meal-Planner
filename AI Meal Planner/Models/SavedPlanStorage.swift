import Foundation

enum SavedPlanStorage {
    private static let key = "saved_meal_plan_v1"

    struct Payload: Codable {
        var daily: DailyPlanResponse?
        var weekly: WeeklyPlanResponse?
    }

    static func load() -> Payload {
        guard let data = UserDefaults.standard.data(forKey: key),
              let p = try? JSONDecoder().decode(Payload.self, from: data) else {
            return Payload(daily: nil, weekly: nil)
        }
        return p
    }

    static func save(daily: DailyPlanResponse?, weekly: WeeklyPlanResponse?) {
        let p = Payload(daily: daily, weekly: weekly)
        guard let data = try? JSONEncoder().encode(p) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
