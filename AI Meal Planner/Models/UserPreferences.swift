import Foundation

struct UserPreferences: Codable, Equatable {
    var goal: String
    var dailyCalories: Int
    var dietType: String
    var allergies: [String]
    var dislikedFoods: [String]
    var mealsPerDay: Int
    var cookingTimePreference: String
    var budget: String
    var activityLevel: String
    var preferredCuisine: String
    var language: String

    static let `default` = UserPreferences(
        goal: "healthy lifestyle",
        dailyCalories: 2000,
        dietType: "balanced",
        allergies: [],
        dislikedFoods: [],
        mealsPerDay: 4,
        cookingTimePreference: "medium",
        budget: "medium",
        activityLevel: "moderate",
        preferredCuisine: "mixed",
        language: "ru"
    )
}

enum UserPreferencesStorage {
    private static let key = "user_preferences_v1"

    static func load() -> UserPreferences {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return .default
        }
        return decoded
    }

    static func save(_ prefs: UserPreferences) {
        guard let data = try? JSONEncoder().encode(prefs) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
