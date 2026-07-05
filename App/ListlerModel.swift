import Foundation
import Observation

/// The observable model that powers the Listler app.
///
/// Responsibilities:
/// - Holds the user's in-progress text (`draftItem`).
/// - Stores the original list of items (`items`).
/// - Produces a shuffled version of the list (`generatedItems`).
/// - Tracks whether the user has finished editing (`isFinished`).
/// - Emits a transient duplicate warning flag (`duplicateFlash`) for the UI.
///
/// Design:
/// - Annotated with `@Observable` (Observation framework) so SwiftUI updates automatically
///   when its properties change.
/// - Owned by `ContentView` as `@State` to keep the instance alive for the view's lifetime.
///
/// Behavior & Validation:
/// - `addDraftItem()` trims whitespace and rejects case-insensitive duplicates.
/// - `removeItem(at:)` safely bounds-checks indices.
/// - `finishEntry()` requires at least one item; `resumeEditing()` returns to editing.
/// - `clearList()` resets all state; `generateList()` shuffles `items`.

@Observable
final class ListlerModel {
    // MARK: - Stored Properties
    var items: [String] = []
    var generatedItems: [String] = []
    var draftItem: String = ""
    var duplicateFlash: Bool = false
    var isFinished: Bool = false

    // MARK: - Persistence
    private enum StorageKey {
        static let items = "listler.items"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let saved = defaults.stringArray(forKey: StorageKey.items) {
            items = saved
        }
        isFinished = !items.isEmpty
    }

    // MARK: - Derived Properties
    var canAddItem: Bool { !draftItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    // MARK: - Actions
    func addDraftItem() {
        let trimmed = draftItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if items.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            // duplicate
            withAnimationIfAvailable {
                duplicateFlash = true
            }
            return
        }
        items.append(trimmed)
        draftItem = ""
        generatedItems.removeAll()
        persistItems()
    }

    func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
        generatedItems.removeAll()
        persistItems()
    }

    func finishEntry() {
        guard !items.isEmpty else { return }
        isFinished = true
    }

    func resumeEditing() {
        isFinished = false
    }

    func clearList() {
        items.removeAll()
        generatedItems.removeAll()
        draftItem = ""
        duplicateFlash = false
        isFinished = false
        persistItems()
    }

    func generateList() {
        generatedItems = items.shuffled()
    }

    // MARK: - Persistence Helpers
    private func persistItems() {
        defaults.set(items, forKey: StorageKey.items)
        if items.isEmpty {
            isFinished = false
        }
    }
}

// Helper to avoid importing SwiftUI here just for animation
private func withAnimationIfAvailable(_ actions: () -> Void) {
    actions()
}

