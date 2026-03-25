import SwiftUI

struct ProfileOnboardingView: View {
    @Environment(MealPlannerViewModel.self) private var model
    var onFinished: () -> Void

    @State private var step = 0
    @State private var forward = true

    private let totalSteps = 8

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if step > 0 {
                    Button {
                        forward = false
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                            step -= 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                    }
                }
                Spacer()
                Text("Шаг \(step + 1) из \(totalSteps)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            OnboardingProgressBar(step: step, total: totalSteps)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            ZStack {
                ProfileOnboardingSteps(step: step)
                    .id(step)
                    .transition(stepTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: step)

            OnboardingPrimaryButton(title: step == totalSteps - 1 ? "Готово" : "Продолжить") {
                if step == totalSteps - 1 {
                    model.persistPreferences()
                    onFinished()
                } else {
                    forward = true
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        step += 1
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(AppTheme.background)
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }
}

private struct ProfileOnboardingSteps: View {
    @Environment(MealPlannerViewModel.self) private var model
    let step: Int

    var body: some View {
        @Bindable var m = model
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                switch step {
                case 0:
                    stepHeader("Твоя цель", "От этого зависит баланс калорий и акценты в плане.")
                    VStack(spacing: 12) {
                        GoalTile(title: "Снижение веса", subtitle: "Дефицит и сытость", assetName: "icon_goal_lose_weight", systemIcon: "chart.line.downtrend.xyaxis", value: "weight loss", selection: $m.preferences.goal)
                        GoalTile(title: "Набор массы", subtitle: "Белок и энергия", assetName: "icon_goal_muscle", systemIcon: "figure.strengthtraining.traditional", value: "muscle gain", selection: $m.preferences.goal)
                        GoalTile(title: "Поддержание", subtitle: "Стабильный баланс", assetName: "icon_goal_maintain", systemIcon: "equal.circle.fill", value: "maintenance", selection: $m.preferences.goal)
                        GoalTile(title: "Здоровый образ жизни", subtitle: "Разнообразие и устойчивость", assetName: "icon_goal_lifestyle", systemIcon: "sparkles", value: "healthy lifestyle", selection: $m.preferences.goal)
                    }
                case 1:
                    stepHeader("Калории", "Приблизительная цель на день.")
                    VStack(spacing: 20) {
                        Text("\(m.preferences.dailyCalories)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [AppTheme.accent, AppTheme.textPrimary], startPoint: .leading, endPoint: .trailing)
                            )
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: m.preferences.dailyCalories)
                        Text("ккал / день")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Slider(
                            value: Binding(
                                get: { Double(m.preferences.dailyCalories) },
                                set: { m.preferences.dailyCalories = Int(($0 / 50).rounded() * 50) }
                            ),
                            in: 1200...4000,
                            step: 50
                        )
                        .tint(AppTheme.accent)
                    }
                    .padding(.vertical, 8)
                case 2:
                    stepHeader("Тип питания", "Можно выбрать шаблон или написать свой.")
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach([("balanced", "Баланс"), ("high protein", "Больше белка"), ("vegetarian", "Вегетарианство"), ("mediterranean", "Средиземноморье")], id: \.0) { tag, label in
                            DietTypeCard(title: label, isSelected: m.preferences.dietType == tag) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    m.preferences.dietType = tag
                                }
                            }
                        }
                    }
                    OnboardingTextField(placeholder: "Свой вариант…", text: $m.preferences.dietType)
                case 3:
                    stepHeader("Ограничения", "Аллергии и продукты, которые не хочешь видеть.")
                    Text("Аллергии")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    OnboardingTextField(
                        placeholder: "Через запятую, например: орехи, молоко",
                        text: Binding(
                            get: { m.preferences.allergies.joined(separator: ", ") },
                            set: { m.preferences.allergies = splitList($0) }
                        )
                    )
                    Text("Не люблю")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    OnboardingTextField(
                        placeholder: "Через запятую",
                        text: Binding(
                            get: { m.preferences.dislikedFoods.joined(separator: ", ") },
                            set: { m.preferences.dislikedFoods = splitList($0) }
                        )
                    )
                case 4:
                    stepHeader("Приёмы пищи", "Сколько раз в день ешь.")
                    HStack(spacing: 10) {
                        ForEach(3...6, id: \.self) { n in
                            mealPill(n: n, current: m.preferences.mealsPerDay) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                                    m.preferences.mealsPerDay = n
                                }
                            }
                        }
                    }
                case 5:
                    stepHeader("Время на готовку", "Подстроим сложность блюд.")
                    VStack(spacing: 12) {
                        CookingOptionRow(title: "Мало", subtitle: "15–20 минут", tag: "low", assetName: "icon_cooking_fast", systemName: "bolt.fill", selection: $m.preferences.cookingTimePreference)
                        CookingOptionRow(title: "Средне", subtitle: "до 40 минут", tag: "medium", assetName: "icon_cooking_medium", systemName: "timer", selection: $m.preferences.cookingTimePreference)
                        CookingOptionRow(title: "Много", subtitle: "есть время готовить", tag: "high", assetName: "icon_cooking_slow", systemName: "flame.fill", selection: $m.preferences.cookingTimePreference)
                    }
                case 6:
                    stepHeader("Бюджет и активность", "Для реалистичных порций и продуктов.")
                    Text("Бюджет")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    HStack(spacing: 10) {
                        ForEach([("low", "Ниже"), ("medium", "Средний"), ("high", "Выше")], id: \.0) { t, label in
                            SelectablePill(title: label, isSelected: m.preferences.budget == t) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    m.preferences.budget = t
                                }
                            }
                        }
                    }
                    Text("Активность")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.top, 8)
                    HStack(spacing: 10) {
                        ForEach([("low", "Низкая"), ("moderate", "Умеренная"), ("high", "Высокая")], id: \.0) { t, label in
                            SelectablePill(title: label, isSelected: m.preferences.activityLevel == t) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    m.preferences.activityLevel = t
                                }
                            }
                        }
                    }
                case 7:
                    stepHeader("Кухня и язык", "Ответы AI можно получать на русском или английском.")
                    Text("Предпочтения по кухне")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    OnboardingTextField(placeholder: "mixed, азиатская, домашняя…", text: $m.preferences.preferredCuisine)
                    Text("Язык ответов")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    HStack(spacing: 12) {
                        SelectablePill(title: "Русский", isSelected: m.preferences.language == "ru") {
                            m.preferences.language = "ru"
                        }
                        SelectablePill(title: "English", isSelected: m.preferences.language == "en") {
                            m.preferences.language = "en"
                        }
                    }
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func stepHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func mealPill(n: Int, current: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(n)")
                .font(.title2.weight(.bold))
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(n == current ? AppTheme.accent.opacity(0.35) : AppTheme.card)
                )
                .overlay(
                    Circle()
                        .stroke(n == current ? AppTheme.accent : AppTheme.cardStroke, lineWidth: n == current ? 2 : 1)
                )
                .foregroundStyle(AppTheme.textPrimary)
        }
        .buttonStyle(.plain)
        .scaleEffect(n == current ? 1.08 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.68), value: current)
    }

    private func splitList(_ raw: String) -> [String] {
        raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}

private struct CookingOptionRow: View {
    let title: String
    let subtitle: String
    let tag: String
    let assetName: String
    let systemName: String
    @Binding var selection: String

    private var selected: Bool { selection == tag }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                selection = tag
            }
        } label: {
            HStack(spacing: 14) {
                AssetIcon(assetName: assetName, systemName: systemName, pointSize: 28)
                    .frame(width: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? AppTheme.accent : AppTheme.textSecondary.opacity(0.35))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? AppTheme.accent.opacity(0.55) : AppTheme.cardStroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DietTypeCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 58)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? AppTheme.accent.opacity(0.32) : AppTheme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? AppTheme.accent : AppTheme.cardStroke, lineWidth: isSelected ? 1.5 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}
