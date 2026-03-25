import SwiftUI

private enum MainTab: Int, CaseIterable {
    case plan
    case shopping
    case settings

    var title: String {
        switch self {
        case .plan: return "План"
        case .shopping: return "Покупки"
        case .settings: return "Настройки"
        }
    }

    var asset: String {
        switch self {
        case .plan: return "icon_tab_plan"
        case .shopping: return "icon_tab_cart"
        case .settings: return "icon_tab_settings"
        }
    }

    var system: String {
        switch self {
        case .plan: return "leaf.fill"
        case .shopping: return "cart.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @Environment(MealPlannerViewModel.self) private var model
    @State private var selected: MainTab = .plan

    var body: some View {
        ZStack {
            Group {
                switch selected {
                case .plan:
                    PlanHomeView()
                case .shopping:
                    ShoppingListView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .blur(radius: model.isPlanLoading ? 1.6 : 0)

            if model.isPlanLoading {
                AILoadingOverlay()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .allowsHitTesting(!model.isPlanLoading)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark)
    }

    private var customTabBar: some View {
        HStack(spacing: 6) {
            ForEach(MainTab.allCases, id: \.rawValue) { tab in
                tabItem(tab)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.cardStroke, AppTheme.accent.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.45), radius: 24, y: 12)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func tabItem(_ tab: MainTab) -> some View {
        let on = selected == tab
        return Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if on {
                        Capsule()
                            .fill(AppTheme.accent.opacity(0.22))
                            .frame(width: 56, height: 36)
                    }
                    AssetIcon(assetName: tab.asset, systemName: tab.system, pointSize: on ? 26 : 23)
                }
                .frame(height: 38)
                Text(tab.title)
                    .font(.system(size: 11, weight: on ? .semibold : .medium, design: .rounded))
                    .foregroundStyle(on ? AppTheme.textPrimary : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
