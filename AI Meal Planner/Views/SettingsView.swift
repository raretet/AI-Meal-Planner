import SwiftUI

struct SettingsView: View {
    @AppStorage("intro_onboarding_done_v1") private var introDone = true
    @AppStorage("onboarding_done_v1") private var profileDone = true
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Профиль") {
                    Button("Изменить цели и ограничения") {
                        showEditProfile = true
                    }
                    Button("Пройти онбординг заново") {
                        introDone = false
                        profileDone = false
                    }
                }
                Section {
                    Text("Планы носят ознакомительный характер и не заменяют консультацию специалиста.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Настройки")
            .sheet(isPresented: $showEditProfile) {
                NavigationStack {
                    ProfileOnboardingView { showEditProfile = false }
                        .navigationTitle("Профиль")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Закрыть") { showEditProfile = false }
                            }
                        }
                        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                }
            }
        }
    }
}
