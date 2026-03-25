import SwiftUI
import UIKit

struct OnboardingHeroImage: View {
    let assetName: String
    let systemName: String
    var size: CGFloat = 200

    private var hasAsset: Bool {
        UIImage(named: assetName) != nil
    }

    var body: some View {
        Group {
            if hasAsset {
                Image(assetName)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: size + 48)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.accent.opacity(0.28),
                                    AppTheme.accentSecondary.opacity(0.2),
                                    AppTheme.card.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(AppTheme.cardStroke, lineWidth: 1)
                        )
                    Image(systemName: systemName)
                        .font(.system(size: size * 0.26, weight: .medium))
                }
                .shadow(color: AppTheme.accent.opacity(0.15), radius: 24, y: 12)
            }
        }
    }
}

struct OnboardingProgressBar: View {
    let step: Int
    let total: Int

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(step + 1) / CGFloat(total)
    }

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.cardStroke)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, g.size.width * progress))
                    .animation(.spring(response: 0.5, dampingFraction: 0.78), value: progress)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 4)
    }
}

struct OnboardingPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isEnabled ? AppTheme.accent : AppTheme.card)
                )
                .foregroundStyle(isEnabled ? Color.black.opacity(0.88) : AppTheme.textSecondary)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

struct SelectablePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.accent.opacity(0.35) : AppTheme.card)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? AppTheme.accent : AppTheme.cardStroke, lineWidth: isSelected ? 1.5 : 1)
                )
                .foregroundStyle(AppTheme.textPrimary)
        }
        .buttonStyle(.plain)
    }
}

struct GoalTile: View {
    let title: String
    let subtitle: String
    let assetName: String
    let systemIcon: String
    let value: String
    @Binding var selection: String

    private var selected: Bool { selection == value }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                selection = value
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(selected ? AppTheme.accent.opacity(0.28) : AppTheme.card)
                        .frame(width: 52, height: 52)
                    AssetIcon(assetName: assetName, systemName: systemIcon, pointSize: 26)
                }
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
                    .font(.title2)
                    .foregroundStyle(selected ? AppTheme.accent : AppTheme.textSecondary.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(selected ? AppTheme.accent.opacity(0.65) : AppTheme.cardStroke, lineWidth: selected ? 2 : 1)
                    )
            )
            .scaleEffect(selected ? 1.02 : 1)
            .shadow(color: selected ? AppTheme.accent.opacity(0.12) : .clear, radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(3...6)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
            )
            .foregroundStyle(AppTheme.textPrimary)
    }
}
