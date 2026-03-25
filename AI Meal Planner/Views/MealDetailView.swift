import SwiftUI

struct MealDetailView: View {
    @Environment(MealPlannerViewModel.self) private var model
    let meal: PlannedMeal
    @Environment(\.dismiss) private var dismiss

    @State private var swapIngredient = ""
    @State private var showExplain = false
    @State private var showSwap = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(meal.shortDescription)
                        .foregroundStyle(AppTheme.textSecondary)

                    if hasMacros(meal.macros) {
                        macroRow
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ингредиенты")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(meal.ingredients) { ing in
                            HStack {
                                Text(ing.name)
                                Spacer()
                                Text(ing.amount)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Шаги")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        ForEach(Array(meal.instructions.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1)")
                                    .font(.caption.bold())
                                    .frame(width: 22, height: 22)
                                    .background(Circle().fill(AppTheme.accent.opacity(0.25)))
                                Text(step)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()

                    Text(meal.whyItFits)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()

                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await model.explainMeal(meal: meal)
                                if model.mealExplanation != nil { showExplain = true }
                            }
                        } label: {
                            label("Почему это подходит", asset: "icon_explain", system: "sparkles")
                        }
                        .disabled(model.isMealActionLoading)

                        Button {
                            Task {
                                await model.regenerateMeal(mealId: meal.id, mealType: meal.type, calories: meal.calories)
                                if model.errorMessage == nil { dismiss() }
                            }
                        } label: {
                            label("Другое блюдо", asset: "icon_regenerate", system: "arrow.triangle.2.circlepath")
                        }
                        .disabled(model.isMealActionLoading)

                        TextField("Заменить ингредиент, напр. молоко", text: $swapIngredient)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            Task {
                                let ctx = meal.instructions.joined(separator: " ") + " " + meal.ingredients.map(\.name).joined(separator: ", ")
                                await model.swapIngredient(swapIngredient, context: ctx)
                                if model.ingredientSwapResult != nil { showSwap = true }
                            }
                        } label: {
                            label("Альтернативы ингредиента", asset: "icon_swap", system: "leaf")
                        }
                        .disabled(model.isMealActionLoading || swapIngredient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationTitle(meal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .sheet(isPresented: $showExplain) {
                if let ex = model.mealExplanation {
                    ExplanationSheet(response: ex) {
                        showExplain = false
                        model.clearExplanation()
                    }
                }
            }
            .sheet(isPresented: $showSwap) {
                if let sw = model.ingredientSwapResult {
                    SwapSheet(response: sw) {
                        showSwap = false
                        model.clearIngredientSwap()
                    }
                }
            }
            .overlay {
                if model.isMealActionLoading {
                    AILoadingOverlay(
                        title: "Обрабатываю блюдо",
                        subtitle: "AI анализирует и подбирает результат"
                    )
                    .transition(.opacity)
                }
            }
            .allowsHitTesting(!model.isMealActionLoading)
        }
    }

    private var macroRow: some View {
        HStack(spacing: 12) {
            chip("Б", meal.macros.protein)
            chip("Ж", meal.macros.fat)
            chip("У", meal.macros.carbs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hasMacros(_ macros: MacroGrams) -> Bool {
        macros.protein > 0 || macros.fat > 0 || macros.carbs > 0
    }

    private func chip(_ t: String, _ v: Int) -> some View {
        Text("\(t) \(v) г")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(AppTheme.card))
            .overlay(Capsule().stroke(AppTheme.cardStroke))
            .foregroundStyle(AppTheme.textPrimary)
    }

    private func label(_ title: String, asset: String, system: String) -> some View {
        HStack(spacing: 10) {
            AssetIcon(assetName: asset, systemName: system, pointSize: 22)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.accentSecondary.opacity(0.35)))
    }
}

private struct ExplanationSheet: View {
    let response: MealExplanationResponse
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(response.explanation)
                        .foregroundStyle(AppTheme.textPrimary)
                    ForEach(response.highlights, id: \.self) { h in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.accent)
                            Text(h).foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    Text(response.disclaimer)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationTitle(response.mealName)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK", action: onClose)
                }
            }
        }
    }
}

private struct SwapSheet: View {
    let response: IngredientSwapResponse
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section(response.ingredient) {
                    ForEach(response.alternatives) { alt in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(alt.name).font(.headline)
                            Text(alt.reason).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Замены")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK", action: onClose)
                }
            }
        }
    }
}
