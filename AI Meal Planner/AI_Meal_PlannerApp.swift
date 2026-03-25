import SwiftUI

@main
struct AI_Meal_PlannerApp: App {
    @State private var planner = MealPlannerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(planner)
        }
    }
}
