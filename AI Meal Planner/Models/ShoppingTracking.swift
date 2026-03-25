import Foundation

enum ShoppingCategory: String, Codable, CaseIterable, Hashable {
    case proteins
    case vegetables
    case fruits
    case grainsAndCarbs
    case dairyAndAlternatives
    case fatsAndOils
    case spicesAndExtras

    var displayTitle: String {
        switch self {
        case .proteins: return "Белки"
        case .vegetables: return "Овощи"
        case .fruits: return "Фрукты"
        case .grainsAndCarbs: return "Крупы и углеводы"
        case .dairyAndAlternatives: return "Молочное / альтернативы"
        case .fatsAndOils: return "Жиры и масла"
        case .spicesAndExtras: return "Специи и прочее"
        }
    }
}

struct TrackedShoppingLine: Identifiable, Codable, Hashable {
    let id: UUID
    let category: ShoppingCategory
    let name: String
    let plannedAmount: String
    var isPurchased: Bool
    var remainingNote: String
    var price: Double?

    static func mergeKey(category: ShoppingCategory, name: String) -> String {
        "\(category.rawValue)|\(name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }
}

enum ShoppingTrackingStorage {
    private static let key = "shopping_tracking_v1"

    static func load() -> ShoppingTrackingSnapshot {
        guard let data = UserDefaults.standard.data(forKey: key),
              let s = try? JSONDecoder().decode(ShoppingTrackingSnapshot.self, from: data) else {
            return ShoppingTrackingSnapshot(budgetLimit: nil, lines: [])
        }
        return s
    }

    static func save(_ snapshot: ShoppingTrackingSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

struct ShoppingTrackingSnapshot: Codable {
    var budgetLimit: Double?
    var lines: [TrackedShoppingLine]
}

@MainActor
@Observable
final class ShoppingTracker {
    var budgetLimit: Double?
    private(set) var lines: [TrackedShoppingLine] = []

    init() {
        let s = ShoppingTrackingStorage.load()
        budgetLimit = s.budgetLimit
        lines = s.lines
    }

    var spentOnPurchased: Double {
        lines.filter(\.isPurchased).compactMap(\.price).reduce(0, +)
    }

    func setBudgetLimit(_ value: Double?) {
        budgetLimit = value
        persist()
    }

    func setPurchased(id: UUID, value: Bool) {
        guard let i = lines.firstIndex(where: { $0.id == id }) else { return }
        lines[i].isPurchased = value
        persist()
    }

    func setRemaining(id: UUID, text: String) {
        guard let i = lines.firstIndex(where: { $0.id == id }) else { return }
        lines[i].remainingNote = text
        persist()
    }

    func setPrice(id: UUID, value: Double?) {
        guard let i = lines.firstIndex(where: { $0.id == id }) else { return }
        lines[i].price = value
        persist()
    }

    func resetPurchaseMarks() {
        for i in lines.indices {
            lines[i].isPurchased = false
            lines[i].price = nil
        }
        persist()
    }

    func sync(from bucket: ShoppingListBucket) {
        var prev: [String: TrackedShoppingLine] = [:]
        for line in lines {
            prev[TrackedShoppingLine.mergeKey(category: line.category, name: line.name)] = line
        }

        var next: [TrackedShoppingLine] = []

        func append(category: ShoppingCategory, ingredients: [IngredientAmount]) {
            for ing in ingredients {
                let key = TrackedShoppingLine.mergeKey(category: category, name: ing.name)
                if let old = prev[key] {
                    next.append(
                        TrackedShoppingLine(
                            id: old.id,
                            category: category,
                            name: ing.name,
                            plannedAmount: ing.amount,
                            isPurchased: old.isPurchased,
                            remainingNote: old.remainingNote,
                            price: old.price
                        )
                    )
                    prev.removeValue(forKey: key)
                } else {
                    next.append(
                        TrackedShoppingLine(
                            id: UUID(),
                            category: category,
                            name: ing.name,
                            plannedAmount: ing.amount,
                            isPurchased: false,
                            remainingNote: "",
                            price: nil
                        )
                    )
                }
            }
        }

        append(category: .proteins, ingredients: bucket.proteins)
        append(category: .vegetables, ingredients: bucket.vegetables)
        append(category: .fruits, ingredients: bucket.fruits)
        append(category: .grainsAndCarbs, ingredients: bucket.grainsAndCarbs)
        append(category: .dairyAndAlternatives, ingredients: bucket.dairyAndAlternatives)
        append(category: .fatsAndOils, ingredients: bucket.fatsAndOils)
        append(category: .spicesAndExtras, ingredients: bucket.spicesAndExtras)

        lines = next
        persist()
    }

    func lines(for category: ShoppingCategory) -> [TrackedShoppingLine] {
        lines.filter { $0.category == category }
    }

    private func persist() {
        ShoppingTrackingStorage.save(ShoppingTrackingSnapshot(budgetLimit: budgetLimit, lines: lines))
    }
}
