import SwiftUI

struct ShoppingListView: View {
    @Environment(MealPlannerViewModel.self) private var model
    @State private var budgetText = ""
    @State private var showResetConfirm = false

    var body: some View {
        @Bindable var tracker = model.shoppingTracker
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    budgetCard(tracker: tracker)
                    if model.activeShoppingList == nil && tracker.lines.isEmpty {
                        emptyPlanHint
                    } else if tracker.lines.isEmpty, model.activeShoppingList != nil {
                        Text("Обновляю список…")
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        ForEach(ShoppingCategory.allCases, id: \.self) { cat in
                            let items = tracker.lines(for: cat)
                            if !items.isEmpty {
                                categoryBlock(title: cat.displayTitle, items: items)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 28)
            }
            .background(AppTheme.background)
            .navigationTitle("Покупки")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showResetConfirm = true
                    } label: {
                        Label("Сбросить отметки", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(tracker.lines.isEmpty || !tracker.lines.contains { $0.isPurchased || ($0.price ?? 0) > 0 })
                }
            }
            .onAppear { syncBudgetField() }
            .confirmationDialog("Сбросить отметки «купил» и цены?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Сбросить", role: .destructive) {
                    tracker.resetPurchaseMarks()
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }

    private func budgetCard(tracker: ShoppingTracker) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Бюджет на продукты")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Лимит")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("0", text: $budgetText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppTheme.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
                    .foregroundStyle(AppTheme.textPrimary)
                    .onChange(of: budgetText) { _, new in
                        applyBudget(from: new)
                    }
                Text("₽")
                    .foregroundStyle(AppTheme.textSecondary)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Потрачено (по отмеченным)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(formatMoney(tracker.spentOnPurchased))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                if let limit = tracker.budgetLimit, limit > 0 {
                    let ratio = tracker.spentOnPurchased / limit
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(ratio <= 1 ? "В пределах" : "Превышение")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ratio <= 1 ? AppTheme.accent : Color.orange)
                        Text("\(Int(min(999, ratio * 100)))%")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            if let limit = tracker.budgetLimit, limit > 0 {
                GeometryReader { g in
                    let p = tracker.spentOnPurchased / limit
                    let over = p > 1
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.cardStroke)
                        Capsule()
                            .fill(over ? Color.orange.opacity(0.85) : AppTheme.accent)
                            .frame(width: min(g.size.width, g.size.width * CGFloat(min(p, 1.0))))
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AppTheme.cardStroke))
        )
    }

    private var emptyPlanHint: some View {
        ContentUnavailableView(
            "Список пуст",
            systemImage: "cart",
            description: Text("Сгенерируйте план на вкладке «План» — список и отметки подстроятся автоматически. Лимит бюджета сохраняется.")
        )
        .foregroundStyle(AppTheme.textSecondary)
    }

    private func categoryBlock(title: String, items: [TrackedShoppingLine]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.accent)
            ForEach(items) { line in
                ShoppingLineRow(line: line)
            }
        }
    }

    private func syncBudgetField() {
        if let b = model.shoppingTracker.budgetLimit, b > 0 {
            if b.truncatingRemainder(dividingBy: 1) == 0 {
                budgetText = String(Int(b))
            } else {
                budgetText = String(b)
            }
        } else {
            budgetText = ""
        }
    }

    private func applyBudget(from raw: String) {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if t.isEmpty {
            model.shoppingTracker.setBudgetLimit(nil)
            return
        }
        model.shoppingTracker.setBudgetLimit(Double(t))
    }

    private func formatMoney(_ v: Double) -> String {
        let n = Int(v.rounded())
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        return "\(f.string(from: NSNumber(value: n)) ?? "\(n)") ₽"
    }
}

private struct ShoppingLineRow: View {
    @Environment(MealPlannerViewModel.self) private var model
    let line: TrackedShoppingLine

    var body: some View {
        @Bindable var tracker = model.shoppingTracker
        let current = tracker.lines.first { $0.id == line.id } ?? line
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    tracker.setPurchased(id: current.id, value: !current.isPurchased)
                } label: {
                    Image(systemName: current.isPurchased ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(current.isPurchased ? AppTheme.accent : AppTheme.textSecondary.opacity(0.45))
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 4) {
                    Text(current.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .strikethrough(current.isPurchased, color: AppTheme.textSecondary)
                    Text("В плане: \(current.plannedAmount)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            Text("Осталось дома")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            TextField("Напр. полпачки, 300 г", text: Binding(
                get: { tracker.lines.first { $0.id == line.id }?.remainingNote ?? "" },
                set: { tracker.setRemaining(id: line.id, text: $0) }
            ))
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppTheme.bgTop))
            .foregroundStyle(AppTheme.textPrimary)
            HStack {
                Text("Цена покупки")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("₽", text: Binding(
                    get: {
                        guard let p = tracker.lines.first(where: { $0.id == line.id })?.price else { return "" }
                        if p.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(p)) }
                        return String(p)
                    },
                    set: { new in
                        let t = new.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                        if t.isEmpty {
                            tracker.setPrice(id: line.id, value: nil)
                        } else {
                            tracker.setPrice(id: line.id, value: Double(t))
                        }
                    }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .padding(10)
                .frame(maxWidth: 120)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppTheme.bgTop))
                .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.cardStroke))
        )
    }
}
