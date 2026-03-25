import SwiftUI

struct ContentView: View {
    @AppStorage("intro_onboarding_done_v1") private var introDone = false
    @AppStorage("onboarding_done_v1") private var profileDone = false

    var body: some View {
        Group {
            if !introDone {
                IntroOnboardingView { introDone = true }
            } else if !profileDone {
                NavigationStack {
                    ProfileOnboardingView { profileDone = true }
                        .navigationTitle("Профиль")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                }
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(MealPlannerViewModel())
}
