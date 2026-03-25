import SwiftUI

struct MealCardView: View {
    let meal: PlannedMeal
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(mealTypeLabel(meal.type))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppTheme.accent.opacity(0.22)))
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                    Text("\(meal.calories) ккал")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Text(meal.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(meal.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                HStack(spacing: 12) {
                    Label("\(meal.prepTimeMinutes) мин", systemImage: "timer")
                    Label(difficultyLabel(meal.difficulty), systemImage: "hand.raised.fill")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.accent.opacity(0.5), AppTheme.accentSecondary.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func mealTypeLabel(_ type: String) -> String {
        switch type.lowercased() {
        case "breakfast": return "Завтрак"
        case "lunch": return "Обед"
        case "dinner": return "Ужин"
        case "snack": return "Перекус"
        default: return type.capitalized
        }
    }

    private func difficultyLabel(_ d: String) -> String {
        d.lowercased() == "medium" ? "Средне" : "Легко"
    }
}
