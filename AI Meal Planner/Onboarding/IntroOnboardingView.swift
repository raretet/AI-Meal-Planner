import SwiftUI

struct IntroOnboardingView: View {
    var onFinished: () -> Void

    @State private var page = 0
    @State private var appear = false

    private let pages: [(asset: String, symbol: String, title: String, subtitle: String)] = [
        (
            "onboarding_intro_welcome",
            "leaf.circle.fill",
            "AI Meal Planner",
            "Персональные планы питания и списки покупок в одном месте. Напоминание: это wellness-приложение, не медицинский сервис."
        ),
        (
            "onboarding_intro_plans",
            "calendar.badge.clock",
            "День и неделя",
            "Собирай рацион на сегодня или на всю неделю с разнообразием блюд и удобным списком продуктов."
        ),
        (
            "onboarding_intro_ai",
            "wand.and.stars",
            "Умный помощник",
            "Замени одно блюдо, подбери альтернативу ингредиенту или узнай, почему блюдо подходит под твою цель."
        ),
        (
            "onboarding_intro_wellness",
            "heart.text.square.fill",
            "Твой ритм",
            "Укажи цели, калории и предпочтения — дальше настроим профиль по шагам. This is not medical advice."
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.background
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                        slide(asset: p.asset, symbol: p.symbol, title: p.title, subtitle: p.subtitle)
                            .tag(i)
                            .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: page)

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? AppTheme.accent : AppTheme.cardStroke)
                            .frame(width: i == page ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: page)
                    }
                }
                .padding(.bottom, 20)

                VStack(spacing: 12) {
                    if page < pages.count - 1 {
                        OnboardingPrimaryButton(title: "Далее") {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                page += 1
                            }
                        }
                        Button("Пропустить") {
                            onFinished()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        OnboardingPrimaryButton(title: "Создать профиль") {
                            onFinished()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 12)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05)) {
                appear = true
            }
        }
    }

    private func slide(asset: String, symbol: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)
            OnboardingHeroImage(assetName: asset, systemName: symbol, size: 200)
                .padding(.top, 8)
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 24)
        }
    }
}
