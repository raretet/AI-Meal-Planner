import Foundation

struct IngredientAmount: Codable, Hashable, Identifiable {
    var id: String { "\(name)|\(amount)" }
    let name: String
    let amount: String

    enum CodingKeys: String, CodingKey {
        case name, amount
    }

    init(name: String, amount: String) {
        self.name = name
        self.amount = amount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        if let s = try? c.decode(String.self, forKey: .amount) {
            amount = s
        } else if let i = try? c.decode(Int.self, forKey: .amount) {
            amount = "\(i) g"
        } else if let d = try? c.decode(Double.self, forKey: .amount) {
            amount = "\(Int(d.rounded())) g"
        } else {
            amount = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(amount, forKey: .amount)
    }
}

struct MacroGrams: Codable, Hashable {
    let protein: Int
    let fat: Int
    let carbs: Int

    init(protein: Int, fat: Int, carbs: Int) {
        self.protein = max(0, protein)
        self.fat = max(0, fat)
        self.carbs = max(0, carbs)
    }

    enum CodingKeys: String, CodingKey {
        case protein, fat, carbs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let p = c.decodeFlexibleIntIfPresent(forKey: .protein, default: 0)
        let f = c.decodeFlexibleIntIfPresent(forKey: .fat, default: 0)
        let ca = c.decodeFlexibleIntIfPresent(forKey: .carbs, default: 0)
        self.init(protein: p, fat: f, carbs: ca)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(protein, forKey: .protein)
        try c.encode(fat, forKey: .fat)
        try c.encode(carbs, forKey: .carbs)
    }
}

struct HydrationTarget: Codable, Hashable {
    let targetMl: Int

    enum CodingKeys: String, CodingKey {
        case targetMl
    }

    init(targetMl: Int) {
        self.targetMl = targetMl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        targetMl = max(0, c.decodeFlexibleIntIfPresent(forKey: .targetMl, default: 2000))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(targetMl, forKey: .targetMl)
    }
}

struct PlannedMeal: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let name: String
    let shortDescription: String
    let imagePrompt: String
    let ingredients: [IngredientAmount]
    let calories: Int
    let macros: MacroGrams
    let prepTimeMinutes: Int
    let difficulty: String
    let instructions: [String]
    let whyItFits: String

    enum CodingKeys: String, CodingKey {
        case id, type, name, shortDescription, imagePrompt, ingredients, calories, macros, prepTimeMinutes, difficulty, instructions, whyItFits
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(String.self, forKey: .type)
        name = try c.decode(String.self, forKey: .name)
        shortDescription = try c.decodeIfPresent(String.self, forKey: .shortDescription) ?? name
        imagePrompt = try c.decodeIfPresent(String.self, forKey: .imagePrompt) ?? "\(name), healthy meal, premium food photography, soft light"
        ingredients = try c.decodeIfPresent([IngredientAmount].self, forKey: .ingredients) ?? []
        calories = max(0, c.decodeFlexibleIntIfPresent(forKey: .calories, default: 0))
        macros = try c.decodeIfPresent(MacroGrams.self, forKey: .macros) ?? MacroGrams(protein: 0, fat: 0, carbs: 0)
        prepTimeMinutes = max(0, c.decodeFlexibleIntIfPresent(forKey: .prepTimeMinutes, default: 15))
        difficulty = try c.decodeIfPresent(String.self, forKey: .difficulty) ?? "easy"
        instructions = try c.decodeIfPresent([String].self, forKey: .instructions) ?? []
        whyItFits = try c.decodeIfPresent(String.self, forKey: .whyItFits) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(name, forKey: .name)
        try c.encode(shortDescription, forKey: .shortDescription)
        try c.encode(imagePrompt, forKey: .imagePrompt)
        try c.encode(ingredients, forKey: .ingredients)
        try c.encode(calories, forKey: .calories)
        try c.encode(macros, forKey: .macros)
        try c.encode(prepTimeMinutes, forKey: .prepTimeMinutes)
        try c.encode(difficulty, forKey: .difficulty)
        try c.encode(instructions, forKey: .instructions)
        try c.encode(whyItFits, forKey: .whyItFits)
    }
}

struct ShoppingListBucket: Codable, Hashable {
    var proteins: [IngredientAmount]
    var vegetables: [IngredientAmount]
    var fruits: [IngredientAmount]
    var grainsAndCarbs: [IngredientAmount]
    var dairyAndAlternatives: [IngredientAmount]
    var fatsAndOils: [IngredientAmount]
    var spicesAndExtras: [IngredientAmount]

    enum CodingKeys: String, CodingKey {
        case proteins, vegetables, fruits, grainsAndCarbs, dairyAndAlternatives, fatsAndOils, spicesAndExtras
    }

    init(
        proteins: [IngredientAmount],
        vegetables: [IngredientAmount],
        fruits: [IngredientAmount],
        grainsAndCarbs: [IngredientAmount],
        dairyAndAlternatives: [IngredientAmount],
        fatsAndOils: [IngredientAmount],
        spicesAndExtras: [IngredientAmount]
    ) {
        self.proteins = proteins
        self.vegetables = vegetables
        self.fruits = fruits
        self.grainsAndCarbs = grainsAndCarbs
        self.dairyAndAlternatives = dairyAndAlternatives
        self.fatsAndOils = fatsAndOils
        self.spicesAndExtras = spicesAndExtras
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        proteins = try c.decodeIfPresent([IngredientAmount].self, forKey: .proteins) ?? []
        vegetables = try c.decodeIfPresent([IngredientAmount].self, forKey: .vegetables) ?? []
        fruits = try c.decodeIfPresent([IngredientAmount].self, forKey: .fruits) ?? []
        grainsAndCarbs = try c.decodeIfPresent([IngredientAmount].self, forKey: .grainsAndCarbs) ?? []
        dairyAndAlternatives = try c.decodeIfPresent([IngredientAmount].self, forKey: .dairyAndAlternatives) ?? []
        fatsAndOils = try c.decodeIfPresent([IngredientAmount].self, forKey: .fatsAndOils) ?? []
        spicesAndExtras = try c.decodeIfPresent([IngredientAmount].self, forKey: .spicesAndExtras) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(proteins, forKey: .proteins)
        try c.encode(vegetables, forKey: .vegetables)
        try c.encode(fruits, forKey: .fruits)
        try c.encode(grainsAndCarbs, forKey: .grainsAndCarbs)
        try c.encode(dairyAndAlternatives, forKey: .dairyAndAlternatives)
        try c.encode(fatsAndOils, forKey: .fatsAndOils)
        try c.encode(spicesAndExtras, forKey: .spicesAndExtras)
    }
}

struct DailyPlanSummary: Codable, Hashable {
    let goal: String
    let dietType: String
    let dailyCalories: Int
    let mealsCount: Int
    var budget: String?
    var activityLevel: String?

    enum CodingKeys: String, CodingKey {
        case goal, dietType, dailyCalories, mealsCount, budget, activityLevel
    }

    init(goal: String, dietType: String, dailyCalories: Int, mealsCount: Int, budget: String?, activityLevel: String?) {
        self.goal = goal
        self.dietType = dietType
        self.dailyCalories = dailyCalories
        self.mealsCount = mealsCount
        self.budget = budget
        self.activityLevel = activityLevel
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        goal = try c.decodeIfPresent(String.self, forKey: .goal) ?? ""
        dietType = try c.decodeIfPresent(String.self, forKey: .dietType) ?? "balanced"
        dailyCalories = max(0, c.decodeFlexibleIntIfPresent(forKey: .dailyCalories, default: 2000))
        mealsCount = max(1, c.decodeFlexibleIntIfPresent(forKey: .mealsCount, default: 4))
        budget = try c.decodeIfPresent(String.self, forKey: .budget)
        activityLevel = try c.decodeIfPresent(String.self, forKey: .activityLevel)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(goal, forKey: .goal)
        try c.encode(dietType, forKey: .dietType)
        try c.encode(dailyCalories, forKey: .dailyCalories)
        try c.encode(mealsCount, forKey: .mealsCount)
        try c.encodeIfPresent(budget, forKey: .budget)
        try c.encodeIfPresent(activityLevel, forKey: .activityLevel)
    }
}

struct DailyPlanResponse: Codable {
    let disclaimer: String
    let mode: String
    let summary: DailyPlanSummary
    let macros: MacroGrams
    let hydration: HydrationTarget
    let meals: [PlannedMeal]
    let shoppingList: ShoppingListBucket
    let tips: [String]

    enum CodingKeys: String, CodingKey {
        case disclaimer, mode, summary, macros, hydration, meals, shoppingList, tips
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        disclaimer = try c.decodeIfPresent(String.self, forKey: .disclaimer) ?? "This is not medical advice."
        mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "daily_plan"
        summary = try c.decode(DailyPlanSummary.self, forKey: .summary)
        macros = try c.decode(MacroGrams.self, forKey: .macros)
        hydration = try c.decodeIfPresent(HydrationTarget.self, forKey: .hydration) ?? HydrationTarget(targetMl: 2000)
        meals = try c.decodeIfPresent([PlannedMeal].self, forKey: .meals) ?? []
        shoppingList = try c.decodeIfPresent(ShoppingListBucket.self, forKey: .shoppingList)
            ?? ShoppingListBucket(proteins: [], vegetables: [], fruits: [], grainsAndCarbs: [], dairyAndAlternatives: [], fatsAndOils: [], spicesAndExtras: [])
        tips = try c.decodeIfPresent([String].self, forKey: .tips) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(disclaimer, forKey: .disclaimer)
        try c.encode(mode, forKey: .mode)
        try c.encode(summary, forKey: .summary)
        try c.encode(macros, forKey: .macros)
        try c.encode(hydration, forKey: .hydration)
        try c.encode(meals, forKey: .meals)
        try c.encode(shoppingList, forKey: .shoppingList)
        try c.encode(tips, forKey: .tips)
    }
}

struct WeeklyPlanSummary: Codable, Hashable {
    let goal: String
    let dietType: String
    let days: Int
    let dailyCalories: Int
    let mealsCount: Int

    enum CodingKeys: String, CodingKey {
        case goal, dietType, days, dailyCalories, mealsCount
    }

    init(goal: String, dietType: String, days: Int, dailyCalories: Int, mealsCount: Int) {
        self.goal = goal
        self.dietType = dietType
        self.days = days
        self.dailyCalories = dailyCalories
        self.mealsCount = mealsCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        goal = try c.decodeIfPresent(String.self, forKey: .goal) ?? ""
        dietType = try c.decodeIfPresent(String.self, forKey: .dietType) ?? "balanced"
        days = max(1, c.decodeFlexibleIntIfPresent(forKey: .days, default: 7))
        dailyCalories = max(0, c.decodeFlexibleIntIfPresent(forKey: .dailyCalories, default: 2000))
        mealsCount = max(1, c.decodeFlexibleIntIfPresent(forKey: .mealsCount, default: 4))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(goal, forKey: .goal)
        try c.encode(dietType, forKey: .dietType)
        try c.encode(days, forKey: .days)
        try c.encode(dailyCalories, forKey: .dailyCalories)
        try c.encode(mealsCount, forKey: .mealsCount)
    }
}

struct WeekDayPlan: Codable, Identifiable, Hashable {
    var id: Int { day }
    let day: Int
    let label: String
    var macros: MacroGrams?
    let meals: [PlannedMeal]

    enum CodingKeys: String, CodingKey {
        case day, label, macros, meals
    }

    init(day: Int, label: String, macros: MacroGrams?, meals: [PlannedMeal]) {
        self.day = day
        self.label = label
        self.macros = macros
        self.meals = meals
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        day = max(1, c.decodeFlexibleIntIfPresent(forKey: .day, default: 1))
        label = try c.decodeIfPresent(String.self, forKey: .label) ?? "Day \(day)"
        macros = try c.decodeIfPresent(MacroGrams.self, forKey: .macros)
        meals = try c.decodeIfPresent([PlannedMeal].self, forKey: .meals) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(day, forKey: .day)
        try c.encode(label, forKey: .label)
        try c.encodeIfPresent(macros, forKey: .macros)
        try c.encode(meals, forKey: .meals)
    }
}

struct WeeklyPlanResponse: Codable {
    let disclaimer: String
    let mode: String
    let summary: WeeklyPlanSummary
    let week: [WeekDayPlan]
    let shoppingList: ShoppingListBucket
    let tips: [String]

    enum CodingKeys: String, CodingKey {
        case disclaimer, mode, summary, week, shoppingList, tips
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        disclaimer = try c.decodeIfPresent(String.self, forKey: .disclaimer) ?? "This is not medical advice."
        mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "weekly_plan"
        summary = try c.decode(WeeklyPlanSummary.self, forKey: .summary)
        week = try c.decodeIfPresent([WeekDayPlan].self, forKey: .week) ?? []
        shoppingList = try c.decodeIfPresent(ShoppingListBucket.self, forKey: .shoppingList)
            ?? ShoppingListBucket(proteins: [], vegetables: [], fruits: [], grainsAndCarbs: [], dairyAndAlternatives: [], fatsAndOils: [], spicesAndExtras: [])
        tips = try c.decodeIfPresent([String].self, forKey: .tips) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(disclaimer, forKey: .disclaimer)
        try c.encode(mode, forKey: .mode)
        try c.encode(summary, forKey: .summary)
        try c.encode(week, forKey: .week)
        try c.encode(shoppingList, forKey: .shoppingList)
        try c.encode(tips, forKey: .tips)
    }
}

struct RegenerateMealResponse: Codable {
    let disclaimer: String
    let mode: String
    let replacedMealId: String
    let meal: PlannedMeal

    enum CodingKeys: String, CodingKey {
        case disclaimer, mode, replacedMealId, meal
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        disclaimer = try c.decodeIfPresent(String.self, forKey: .disclaimer) ?? "This is not medical advice."
        mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "regenerate_meal"
        replacedMealId = try c.decode(String.self, forKey: .replacedMealId)
        meal = try c.decode(PlannedMeal.self, forKey: .meal)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(disclaimer, forKey: .disclaimer)
        try c.encode(mode, forKey: .mode)
        try c.encode(replacedMealId, forKey: .replacedMealId)
        try c.encode(meal, forKey: .meal)
    }
}

struct IngredientSwapAlternative: Codable, Hashable, Identifiable {
    var id: String { name }
    let name: String
    let reason: String

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        reason = try c.decodeIfPresent(String.self, forKey: .reason) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(reason, forKey: .reason)
    }

    enum CodingKeys: String, CodingKey {
        case name, reason
    }
}

struct IngredientSwapResponse: Codable {
    let disclaimer: String
    let mode: String
    let ingredient: String
    let alternatives: [IngredientSwapAlternative]

    enum CodingKeys: String, CodingKey {
        case disclaimer, mode, ingredient, alternatives
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        disclaimer = try c.decodeIfPresent(String.self, forKey: .disclaimer) ?? "This is not medical advice."
        mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "ingredient_swap"
        ingredient = try c.decode(String.self, forKey: .ingredient)
        alternatives = try c.decodeIfPresent([IngredientSwapAlternative].self, forKey: .alternatives) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(disclaimer, forKey: .disclaimer)
        try c.encode(mode, forKey: .mode)
        try c.encode(ingredient, forKey: .ingredient)
        try c.encode(alternatives, forKey: .alternatives)
    }
}

struct MealExplanationResponse: Codable {
    let disclaimer: String
    let mode: String
    let mealName: String
    let explanation: String
    let highlights: [String]

    enum CodingKeys: String, CodingKey {
        case disclaimer, mode, mealName, explanation, highlights
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        disclaimer = try c.decodeIfPresent(String.self, forKey: .disclaimer) ?? "This is not medical advice."
        mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "meal_explanation"
        mealName = try c.decodeIfPresent(String.self, forKey: .mealName) ?? ""
        explanation = try c.decodeIfPresent(String.self, forKey: .explanation) ?? ""
        highlights = try c.decodeIfPresent([String].self, forKey: .highlights) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(disclaimer, forKey: .disclaimer)
        try c.encode(mode, forKey: .mode)
        try c.encode(mealName, forKey: .mealName)
        try c.encode(explanation, forKey: .explanation)
        try c.encode(highlights, forKey: .highlights)
    }
}

extension DailyPlanResponse {
    init(
        disclaimer: String,
        mode: String,
        summary: DailyPlanSummary,
        macros: MacroGrams,
        hydration: HydrationTarget,
        meals: [PlannedMeal],
        shoppingList: ShoppingListBucket,
        tips: [String]
    ) {
        self.disclaimer = disclaimer
        self.mode = mode
        self.summary = summary
        self.macros = macros
        self.hydration = hydration
        self.meals = meals
        self.shoppingList = shoppingList
        self.tips = tips
    }

    func replacingMeal(id: String, with replacement: PlannedMeal) -> DailyPlanResponse? {
        guard let i = meals.firstIndex(where: { $0.id == id }) else { return nil }
        var m = meals
        m[i] = replacement
        return DailyPlanResponse(
            disclaimer: disclaimer,
            mode: mode,
            summary: summary,
            macros: macros,
            hydration: hydration,
            meals: m,
            shoppingList: shoppingList,
            tips: tips
        )
    }
}

extension WeeklyPlanResponse {
    init(
        disclaimer: String,
        mode: String,
        summary: WeeklyPlanSummary,
        week: [WeekDayPlan],
        shoppingList: ShoppingListBucket,
        tips: [String]
    ) {
        self.disclaimer = disclaimer
        self.mode = mode
        self.summary = summary
        self.week = week
        self.shoppingList = shoppingList
        self.tips = tips
    }

    func replacingMeal(oldId: String, with replacement: PlannedMeal) -> WeeklyPlanResponse? {
        var newWeek: [WeekDayPlan] = []
        var found = false
        for d in week {
            if let idx = d.meals.firstIndex(where: { $0.id == oldId }) {
                var ms = d.meals
                ms[idx] = replacement
                newWeek.append(WeekDayPlan(day: d.day, label: d.label, macros: d.macros, meals: ms))
                found = true
            } else {
                newWeek.append(d)
            }
        }
        guard found else { return nil }
        return WeeklyPlanResponse(
            disclaimer: disclaimer,
            mode: mode,
            summary: summary,
            week: newWeek,
            shoppingList: shoppingList,
            tips: tips
        )
    }
}
