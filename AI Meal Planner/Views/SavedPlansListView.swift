import SwiftUI

struct SavedPlansListView: View {
    @Environment(MealPlannerViewModel.self) private var model
    @State private var applyFeedbackTick = 0

    var body: some View {
        NavigationStack {
            Group {
                if model.savedPlanBookmarks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(model.savedPlanBookmarks) { bookmark in
                                let isCurrent = model.activeSavedBookmarkId == bookmark.id
                                HStack(spacing: 0) {
                                    Button {
                                        let ok = bookmark.daily != nil || bookmark.weekly != nil
                                        model.applyBookmark(bookmark)
                                        if ok { applyFeedbackTick += 1 }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(alignment: .center, spacing: 8) {
                                                Text(bookmark.name)
                                                    .font(.headline)
                                                    .foregroundStyle(AppTheme.textPrimary)
                                                if isCurrent {
                                                    Text("Текущий")
                                                        .font(.caption2.weight(.semibold))
                                                        .foregroundStyle(AppTheme.accent)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Capsule().fill(AppTheme.accent.opacity(0.2)))
                                                }
                                            }
                                            Text(bookmark.subtitleLine.isEmpty ? "План" : bookmark.subtitleLine)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.textSecondary)
                                            Text(formattedDate(bookmark.createdAt))
                                                .font(.caption2)
                                                .foregroundStyle(AppTheme.textSecondary.opacity(0.85))
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    Menu {
                                        Button(role: .destructive) {
                                            model.deleteBookmark(id: bookmark.id)
                                        } label: {
                                            Label("Удалить", systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.title3)
                                            .foregroundStyle(isCurrent ? AppTheme.accent : AppTheme.textSecondary)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(isCurrent ? AppTheme.accent.opacity(0.14) : AppTheme.card.opacity(0.55))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(
                                                    isCurrent ? AppTheme.accent.opacity(0.75) : AppTheme.cardStroke.opacity(0.6),
                                                    lineWidth: isCurrent ? 2 : 1
                                                )
                                        )
                                        .shadow(color: isCurrent ? AppTheme.accent.opacity(0.22) : .clear, radius: 12, y: 6)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        Text("Нажмите на план — он станет текущим. Откройте вкладку «План», чтобы посмотреть.")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }
                    .sensoryFeedback(.success, trigger: applyFeedbackTick)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Сохранённые")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .alert("Ошибка", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.clearError() } }
            )) {
                Button("OK", role: .cancel) { model.clearError() }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.accent.opacity(0.85))
            Text("Нет сохранённых планов")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("На экране «План» сохраните рацион с именем. Нажмите на запись — план станет текущим, затем откройте вкладку «План».")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
