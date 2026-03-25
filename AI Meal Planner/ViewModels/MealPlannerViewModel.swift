import Foundation

@MainActor
@Observable
final class MealPlannerViewModel {
    var preferences: UserPreferences
    var dailyPlan: DailyPlanResponse?
    var weeklyPlan: WeeklyPlanResponse?
    var isPlanLoading = false
    var isMealActionLoading = false
    var isLoading: Bool { isPlanLoading || isMealActionLoading }
    var errorMessage: String?
    var mealExplanation: MealExplanationResponse?
    var ingredientSwapResult: IngredientSwapResponse?
    var shoppingTracker = ShoppingTracker()
    var savedPlanBookmarks: [SavedPlanBookmark] = []
    var planSessionId = UUID()
    var activeSavedBookmarkId: UUID?

    private let client = MealAIClient()

    init() {
        preferences = UserPreferencesStorage.load()
        savedPlanBookmarks = SavedPlansLibraryStorage.load().sorted { $0.createdAt > $1.createdAt }
        if let id = ActiveSavedBookmarkStorage.load(),
           savedPlanBookmarks.contains(where: { $0.id == id }) {
            activeSavedBookmarkId = id
        }
        let persisted = SavedPlanStorage.load()
        if let d = persisted.daily {
            dailyPlan = d
            weeklyPlan = nil
            shoppingTracker.sync(from: d.shoppingList)
        } else if let w = persisted.weekly {
            weeklyPlan = w
            dailyPlan = nil
            shoppingTracker.sync(from: w.shoppingList)
        }
    }

    func persistPreferences() {
        UserPreferencesStorage.save(preferences)
    }

    var hasAPIKey: Bool {
        !Secrets.deepSeekAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func generateDailyPlan() async {
        await runPlan {
            let key = try requireKey()
            let raw = try await client.completeJSON(
                userPrompt: PromptBuilder.dailyPlanRequest(prefs: preferences),
                apiKey: key
            )
            let plan = try client.decodeDailyPlan(from: raw)
            dailyPlan = plan
            weeklyPlan = nil
            shoppingTracker.sync(from: plan.shoppingList)
            SavedPlanStorage.save(daily: plan, weekly: nil)
            bumpPlanSession()
            clearActiveSavedBookmark()
        }
    }

    func generateWeeklyPlan() async {
        await runPlan {
            let key = try requireKey()
            let raw = try await client.completeJSON(
                userPrompt: PromptBuilder.weeklyPlanRequest(prefs: preferences),
                apiKey: key
            )
            let plan = try client.decodeWeeklyPlan(from: raw)
            weeklyPlan = plan
            dailyPlan = nil
            shoppingTracker.sync(from: plan.shoppingList)
            SavedPlanStorage.save(daily: nil, weekly: plan)
            bumpPlanSession()
            clearActiveSavedBookmark()
        }
    }

    func regenerateMeal(mealId: String, mealType: String, calories: Int) async {
        await runMealAction {
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
                    SavedPlanStorage.save(daily: updated, weekly: nil)
                    bumpPlanSession()
                    clearActiveSavedBookmark()
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
                    SavedPlanStorage.save(daily: nil, weekly: updated)
                    bumpPlanSession()
                    clearActiveSavedBookmark()
                } else {
                    errorMessage = "Не удалось вставить блюдо в недельный план"
                }
            } else {
                errorMessage = "Нет активного плана"
            }
        }
    }

    func explainMeal(meal: PlannedMeal) async {
        await runMealAction {
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
        await runMealAction {
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

    func saveCurrentPlanAsBookmark(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? Self.defaultBookmarkTitle() : trimmed
        if let d = dailyPlan {
            let b = SavedPlanBookmark(id: UUID(), name: finalName, createdAt: Date(), daily: d, weekly: nil)
            insertBookmark(b)
            setActiveSavedBookmark(b.id)
        } else if let w = weeklyPlan {
            let b = SavedPlanBookmark(id: UUID(), name: finalName, createdAt: Date(), daily: nil, weekly: w)
            insertBookmark(b)
            setActiveSavedBookmark(b.id)
        }
    }

    func deleteBookmark(id: UUID) {
        savedPlanBookmarks.removeAll { $0.id == id }
        SavedPlansLibraryStorage.save(savedPlanBookmarks)
        if activeSavedBookmarkId == id {
            clearActiveSavedBookmark()
        }
    }

    func applyBookmark(_ bookmark: SavedPlanBookmark) {
        if let d = bookmark.daily {
            dailyPlan = d
            weeklyPlan = nil
            shoppingTracker.sync(from: d.shoppingList)
            SavedPlanStorage.save(daily: d, weekly: nil)
            bumpPlanSession()
            setActiveSavedBookmark(bookmark.id)
        } else if let w = bookmark.weekly {
            weeklyPlan = w
            dailyPlan = nil
            shoppingTracker.sync(from: w.shoppingList)
            SavedPlanStorage.save(daily: nil, weekly: w)
            bumpPlanSession()
            setActiveSavedBookmark(bookmark.id)
        } else {
            errorMessage = "В записи нет данных плана. Сохраните рацион ещё раз."
        }
    }

    private func insertBookmark(_ bookmark: SavedPlanBookmark) {
        savedPlanBookmarks.insert(bookmark, at: 0)
        SavedPlansLibraryStorage.save(savedPlanBookmarks)
    }

    private func bumpPlanSession() {
        planSessionId = UUID()
    }

    private func setActiveSavedBookmark(_ id: UUID) {
        activeSavedBookmarkId = id
        ActiveSavedBookmarkStorage.save(id)
    }

    private func clearActiveSavedBookmark() {
        activeSavedBookmarkId = nil
        ActiveSavedBookmarkStorage.save(nil)
    }

    private static func defaultBookmarkTitle() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateStyle = .short
        f.timeStyle = .short
        return "План \(f.string(from: Date()))"
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

    private func runPlan(_ work: () async throws -> Void) async {
        errorMessage = nil
        isPlanLoading = true
        defer { isPlanLoading = false }
        do {
            try await work()
        } catch let e as MealAIClient.MealAIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runMealAction(_ work: () async throws -> Void) async {
        errorMessage = nil
        isMealActionLoading = true
        defer { isMealActionLoading = false }
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
