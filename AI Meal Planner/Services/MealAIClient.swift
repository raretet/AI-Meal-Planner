import Foundation

struct MealAIClient: Sendable {
    struct Configuration: Sendable {
        var endpoint: URL = URL(string: "https://api.deepseek.com/chat/completions")!
        var model: String = "deepseek-chat"
    }

    enum MealAIError: Error, LocalizedError {
        case missingAPIKey
        case invalidResponse
        case httpStatus(Int, String?)
        case decoding(Error)
        case emptyContent

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "Нет API-ключа"
            case .invalidResponse: return "Некорректный ответ сервера"
            case .httpStatus(let code, let body):
                return "Ошибка \(code)" + (body.map { ": \($0)" } ?? "")
            case .decoding(let err):
                return "Не удалось разобрать план: \(MealAIClient.formatDecodeError(err))"
            case .emptyContent: return "Пустой ответ модели"
            }
        }
    }

    private let session: URLSession
    private let config: Configuration

    private static func formatDecodeError(_ error: Error) -> String {
        if let e = error as? DecodingError {
            switch e {
            case .keyNotFound(let k, _):
                return "нет поля \(k.stringValue)"
            case .typeMismatch(let t, _):
                return "неверный тип (\(t))"
            case .valueNotFound(let t, _):
                return "пусто (\(t))"
            case .dataCorrupted(let ctx):
                return ctx.debugDescription
            @unknown default:
                return String(describing: e)
            }
        }
        return error.localizedDescription
    }

    init(session: URLSession = .shared, configuration: Configuration = Configuration()) {
        self.session = session
        self.config = configuration
    }

    func completeJSON(userPrompt: String, apiKey: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MealAIError.missingAPIKey
        }
        do {
            return try await performChat(userPrompt: userPrompt, apiKey: apiKey, jsonObjectMode: true)
        } catch {
            if let e = error as? MealAIError, case .httpStatus(let code, _) = e, code == 400 {
                return try await performChat(userPrompt: userPrompt, apiKey: apiKey, jsonObjectMode: false)
            }
            throw error
        }
    }

    private func performChat(userPrompt: String, apiKey: String, jsonObjectMode: Bool) async throws -> String {
        var request = URLRequest(url: config.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": SystemPrompt.mealEngine],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.6
        ]
        if jsonObjectMode {
            body["response_format"] = ["type": "json_object"]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw MealAIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8)
            throw MealAIError.httpStatus(http.statusCode, text)
        }

        struct Outer: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String?
                }
                let message: Message
            }
            let choices: [Choice]
        }
        let outer = try JSONDecoder().decode(Outer.self, from: data)
        guard let content = outer.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw MealAIError.emptyContent
        }
        return content
    }

    func decodeDailyPlan(from raw: String) throws -> DailyPlanResponse {
        guard let payload = JSONPayloadExtractor.data(from: raw) else { throw MealAIError.invalidResponse }
        do {
            return try JSONDecoder().decode(DailyPlanResponse.self, from: payload)
        } catch {
            throw MealAIError.decoding(error)
        }
    }

    func decodeWeeklyPlan(from raw: String) throws -> WeeklyPlanResponse {
        guard let payload = JSONPayloadExtractor.data(from: raw) else { throw MealAIError.invalidResponse }
        do {
            return try JSONDecoder().decode(WeeklyPlanResponse.self, from: payload)
        } catch {
            throw MealAIError.decoding(error)
        }
    }

    func decodeRegenerateMeal(from raw: String) throws -> RegenerateMealResponse {
        guard let payload = JSONPayloadExtractor.data(from: raw) else { throw MealAIError.invalidResponse }
        do {
            return try JSONDecoder().decode(RegenerateMealResponse.self, from: payload)
        } catch {
            throw MealAIError.decoding(error)
        }
    }

    func decodeIngredientSwap(from raw: String) throws -> IngredientSwapResponse {
        guard let payload = JSONPayloadExtractor.data(from: raw) else { throw MealAIError.invalidResponse }
        do {
            return try JSONDecoder().decode(IngredientSwapResponse.self, from: payload)
        } catch {
            throw MealAIError.decoding(error)
        }
    }

    func decodeMealExplanation(from raw: String) throws -> MealExplanationResponse {
        guard let payload = JSONPayloadExtractor.data(from: raw) else { throw MealAIError.invalidResponse }
        do {
            return try JSONDecoder().decode(MealExplanationResponse.self, from: payload)
        } catch {
            throw MealAIError.decoding(error)
        }
    }
}

enum PromptBuilder {
    static func dailyPlanRequest(prefs: UserPreferences) -> String {
        """
        Return JSON only for mode daily_plan.
        User: goal=\(prefs.goal), caloriesTarget=\(prefs.dailyCalories), dietType=\(prefs.dietType), allergies=\(prefs.allergies.joined(separator: ", ")), dislikedFoods=\(prefs.dislikedFoods.joined(separator: ", ")), mealsPerDay=\(prefs.mealsPerDay), cookingTimePreference=\(prefs.cookingTimePreference), budget=\(prefs.budget), activityLevel=\(prefs.activityLevel), preferredCuisine=\(prefs.preferredCuisine), language=\(prefs.language).
        """
    }

    static func weeklyPlanRequest(prefs: UserPreferences) -> String {
        """
        Return JSON only for mode weekly_plan. Seven days.
        User: goal=\(prefs.goal), caloriesTarget=\(prefs.dailyCalories), dietType=\(prefs.dietType), allergies=\(prefs.allergies.joined(separator: ", ")), dislikedFoods=\(prefs.dislikedFoods.joined(separator: ", ")), mealsPerDay=\(prefs.mealsPerDay), cookingTimePreference=\(prefs.cookingTimePreference), budget=\(prefs.budget), activityLevel=\(prefs.activityLevel), preferredCuisine=\(prefs.preferredCuisine), language=\(prefs.language).
        """
    }

    static func regenerateMealRequest(
        prefs: UserPreferences,
        replacedMealId: String,
        mealType: String,
        approximateCalories: Int,
        planContext: String
    ) -> String {
        """
        Return JSON only for mode regenerate_meal. replacedMealId=\(replacedMealId). Keep meal type \(mealType), calories near \(approximateCalories).
        User constraints: goal=\(prefs.goal), dietType=\(prefs.dietType), allergies=\(prefs.allergies.joined(separator: ", ")), disliked=\(prefs.dislikedFoods.joined(separator: ", ")), cookingTime=\(prefs.cookingTimePreference), budget=\(prefs.budget), language=\(prefs.language).
        Context: \(planContext)
        """
    }

    static func ingredientSwapRequest(prefs: UserPreferences, ingredient: String, context: String) -> String {
        """
        Return JSON only for mode ingredient_swap. ingredient=\(ingredient).
        Respect allergies=\(prefs.allergies.joined(separator: ", ")), dietType=\(prefs.dietType). language=\(prefs.language).
        Recipe context: \(context)
        """
    }

    static func mealExplanationRequest(prefs: UserPreferences, mealSummary: String) -> String {
        """
        Return JSON only for mode meal_explanation. User goal=\(prefs.goal), dietType=\(prefs.dietType). language=\(prefs.language).
        Meal: \(mealSummary)
        """
    }
}
