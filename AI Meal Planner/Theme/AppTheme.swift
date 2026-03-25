import SwiftUI

enum AppTheme {
    static let bgTop = Color(red: 0.09, green: 0.10, blue: 0.13)
    static let bgBottom = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let card = Color(red: 0.14, green: 0.15, blue: 0.19)
    static let cardStroke = Color.white.opacity(0.08)
    static let accent = Color(red: 0.52, green: 0.78, blue: 0.65)
    static let accentSecondary = Color(red: 0.38, green: 0.55, blue: 0.95)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)

    static var background: some View {
        LinearGradient(
            colors: [bgTop, bgBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
