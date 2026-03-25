import Foundation

@MainActor
@Observable
final class MealPlannerViewModel {
    var preferences: UserPreferences
    var dailyPlan: DailyPlanResponse?
    var weeklyPlan: WeeklyPlanResponse?
    var isLoading = false
    var errorMessage: String?
    var mealExplanation: MealExplanationResponse?
    var ingredientSwapResult: IngredientSwapResponse?
    var shoppingTracker = ShoppingTracker()

    private let client = MealAIClient()

    init() {
        preferences = UserPreferencesStorage.load()
    }

    func persistPreferences() {
        UserPreferencesStorage.save(preferences)
    }

    var hasAPIKey: Bool {
        !Secrets.deepSeekAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func generateDailyPlan() async {
        await run {
            let key = try requireKey()
            let raw = try await client.completeJSON(
                userPrompt: PromptBuilder.dailyPlanRequest(prefs: preferences),
                apiKey: key
            )
            let plan = try client.decodeDailyPlan(from: raw)
            dailyPlan = plan
            weeklyPlan = nil
            shoppingTracker.sync(from: plan.shoppingList)
        }
    }

    func generateWeeklyPlan() async {
        await run {
            let key = try requireKey()
            let raw = try await client.completeJSON(
                userPrompt: PromptBuilder.weeklyPlanRequest(prefs: preferences),
                apiKey: key
            )
            let plan = try client.decodeWeeklyPlan(from: raw)
            weeklyPlan = plan
            dailyPlan = nil
            shoppingTracker.sync(from: plan.shoppingList)
        }
    }

    func regenerateMeal(mealId: String, mealType: String, calories: Int) async {
        await run {
            let key = try requireKey()
            let ctx = contextSummary()
            let raw = try await client.completeJSON(
                userPrompt: PromptBuilder.regenerateMealRequest(
                    prefs: preferences,
                    replacedMealId: mealId,
                    mealType: mealType,
                    approximateCalories: calories,
                    planContext: ctx
                ),
                apiKey: key
            )
            let resp = try client.decodeRegenerateMeal(from: raw)
            let ids = [mealId, resp.replacedMealId]
            if var d = dailyPlan {
                var updated: DailyPlanResponse?
                for id in ids {
                    if let u = d.replacingMeal(id: id, with: resp.meal) {
                        updated = u
                        break
                    }
                }
                if let updated {
                    dailyPlan = updated
                } else {
                    errorMessage = "Не удалось вставить блюдо в дневной план"
                }
            } else if var w = weeklyPlan {
                var updated: WeeklyPlanResponse?
                for id in ids {
                    if let u = w.replacingMeal(oldId: id, with: resp.meal) {
                        updated = u
                        break
                    }
                }
                if let updated {
                    weeklyPlan = updated
                } else {
                    errorMessage = "Не удалось вставить блюдо в недельный план"
                }
            } else {
                errorMessage = "Нет активного плана"
            }
        }
    }

    func explainMeal(meal: PlannedMeal) async {
        await run {
            let key = try requireKey()
            let summary = "\(meal.name). \(meal.shortDescription). \(meal.calories) kcal. Macros P\(meal.macros.protein) F\(meal.macros.fat) C\(meal.macros.carbs)."
            let raw = try await client.completeJSON(
                userPrompt: PromptBuilder.mealExplanationRequest(prefs: preferences, mealSummary: summary),
                apiKey: key
            )
            mealExplanation = try client.decodeMealExplanation(from: raw)
        }
    }

    func swapIngredient(_ name: String, context: String) async {
        await run {
            let key = try requireKey()
            let raw = try await client.completeJSON(
                userPrompt: PromptBuilder.ingredientSwapRequest(prefs: preferences, ingredient: name, context: context),
                apiKey: key
            )
            ingredientSwapResult = try client.decodeIngredientSwap(from: raw)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func clearExplanation() {
        mealExplanation = nil
    }

    func clearIngredientSwap() {
        ingredientSwapResult = nil
    }

    private func requireKey() throws -> String {
        let k = Secrets.deepSeekAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else { throw MealAIClient.MealAIError.missingAPIKey }
        return k
    }

    private func contextSummary() -> String {
        if let d = dailyPlan {
            return d.meals.map { "\($0.type): \($0.name) \($0.calories) kcal id=\($0.id)" }.joined(separator: "; ")
        }
        if let w = weeklyPlan {
            return w.week.flatMap { day in
                day.meals.map { "\(day.label) \($0.type): \($0.name) \($0.calories) kcal id=\($0.id)" }
            }.joined(separator: "; ")
        }
        return ""
    }

    private func run(_ work: () async throws -> Void) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await work()
        } catch let e as MealAIClient.MealAIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension MealPlannerViewModel {
    var activeShoppingList: ShoppingListBucket? {
        if let d = dailyPlan { return d.shoppingList }
        if let w = weeklyPlan { return w.shoppingList }
        return nil
    }
}
