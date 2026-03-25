import SwiftUI

struct AILoadingOverlay: View {
    @State private var rotate = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.cardStroke, lineWidth: 12)
                        .frame(width: 96, height: 96)

                    Circle()
                        .trim(from: 0.06, to: 0.78)
                        .stroke(
                            AngularGradient(
                                colors: [AppTheme.accentSecondary, AppTheme.accent, AppTheme.accentSecondary],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(rotate ? 360 : 0))
                        .animation(.linear(duration: 1.15).repeatForever(autoreverses: false), value: rotate)

                    Circle()
                        .fill(AppTheme.accent.opacity(0.18))
                        .frame(width: pulse ? 42 : 26, height: pulse ? 42 : 26)
                        .blur(radius: 1.2)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)

                    Image(systemName: "sparkles")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                VStack(spacing: 5) {
                    Text("Генерирую план")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("AI подбирает блюда и макросы")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.cardStroke, AppTheme.accent.opacity(0.22)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.45), radius: 28, y: 14)
            .onAppear {
                rotate = true
                pulse = true
            }
        }
    }
}
