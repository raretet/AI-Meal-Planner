import SwiftUI

struct PlanHomeView: View {
    @Environment(MealPlannerViewModel.self) private var model
    @State private var selectedMeal: PlannedMeal?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerActions

                    if let d = model.dailyPlan {
                        planHeader(
                            title: "Сегодня",
                            subtitle: "\(d.summary.dailyCalories) ккал · \(d.summary.mealsCount) приёма · \(d.summary.goal)"
                        )
                        if hasMacros(d.macros) {
                            macroSummary(d.macros)
                        }
                        hydrationRow(d.hydration.targetMl)
                        ForEach(d.meals) { meal in
                            MealCardView(meal: meal) { selectedMeal = meal }
                        }
                        tipsBlock(d.tips)
                        disclaimer(d.disclaimer)
                    } else if let w = model.weeklyPlan {
                        planHeader(
                            title: "Неделя",
                            subtitle: "\(w.summary.dailyCalories) ккал/день · \(w.summary.mealsCount) приёма · \(w.summary.goal)"
                        )
                        ForEach(w.week) { day in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(day.label)
                                        .font(.title3.bold())
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    if let m = day.macros, hasMacros(m) {
                                        Text("Б\(m.protein) Ж\(m.fat) У\(m.carbs)")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                }
                                ForEach(day.meals) { meal in
                                    MealCardView(meal: meal) { selectedMeal = meal }
                                }
                            }
                            .glassCard()
                        }
                        tipsBlock(w.tips)
                        disclaimer(w.disclaimer)
                    } else {
                        emptyState
                    }
                }
                .padding(20)
                .padding(.bottom, 32)
            }
            .background(AppTheme.background)
            .navigationTitle("План")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .alert("Ошибка", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.clearError() } }
            )) {
                Button("OK", role: .cancel) { model.clearError() }
            } message: {
                Text(model.errorMessage ?? "")
            }
            .sheet(item: $selectedMeal) { meal in
                MealDetailView(meal: meal)
            }
        }
    }

    private var headerActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    Task { await model.generateDailyPlan() }
                } label: {
                    actionLabel("День", icon: "sun.max.fill")
                }
                .disabled(model.isLoading || !model.hasAPIKey)

                Button {
                    Task { await model.generateWeeklyPlan() }
                } label: {
                    actionLabel("Неделя", icon: "calendar")
                }
                .disabled(model.isLoading || !model.hasAPIKey)
            }
            if !model.hasAPIKey {
                Text("Укажите ключ DeepSeek в Secrets.deepSeekAPIKey")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }

    private func actionLabel(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.accent.opacity(0.9)))
        .foregroundStyle(.black.opacity(0.85))
    }

    private func planHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func macroSummary(_ m: MacroGrams) -> some View {
        HStack(spacing: 10) {
            Text("Белки \(m.protein) г")
            Text("Жиры \(m.fat) г")
            Text("Углеводы \(m.carbs) г")
        }
        .font(.caption.weight(.semibold))
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
        .foregroundStyle(AppTheme.textPrimary)
    }

    private func hasMacros(_ macros: MacroGrams) -> Bool {
        macros.protein > 0 || macros.fat > 0 || macros.carbs > 0
    }

    private func hydrationRow(_ ml: Int) -> some View {
        HStack {
            AssetIcon(assetName: "icon_hydration", systemName: "drop.fill", pointSize: 22)
            Text("Вода ~\(ml) мл")
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .foregroundStyle(AppTheme.textPrimary)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card.opacity(0.9)))
    }

    private func tipsBlock(_ tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Советы")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            ForEach(Array(tips.enumerated()), id: \.offset) { _, t in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text(t)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func disclaimer(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent.opacity(0.85))
            Text("Сгенерируйте план на день или неделю")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text("Планы ориентированы на wellness, не заменяют консультацию специалиста.")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .glassCard()
    }
}
