import Foundation
import Testing
@testable import Listler

@Suite("ListlerModel basics")
struct ListlerModelBasicsTests {
    @Test("Add item trims and appends; duplicate flags; remove item")
    func addAndRemoveAndDuplicate() throws {
        let suite = "ListlerBasics-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Failed to create UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let model = ListlerModel(defaults: defaults)
        #expect(model.items.isEmpty)
        #expect(model.generatedItems.isEmpty)
        #expect(model.isFinished == false)

        // Add with leading/trailing spaces; should trim
        model.draftItem = "  Milk  "
        model.addDraftItem()
        #expect(model.items == ["Milk"])
        #expect(model.draftItem.isEmpty)
        #expect(model.generatedItems.isEmpty)

        // Adding a duplicate (case-insensitive, whitespace-insensitive) should flag
        model.draftItem = " milk "
        model.addDraftItem()
        #expect(model.items == ["Milk"])
        #expect(model.duplicateFlash == true)

        // Remove the item
        model.removeItem(at: 0)
        #expect(model.items.isEmpty)
        #expect(model.generatedItems.isEmpty)
    }

    @Test("Finish/resume editing toggles state with non-empty items")
    func finishAndResume() throws {
        let suite = "ListlerBasics-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Failed to create UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let model = ListlerModel(defaults: defaults)
        model.draftItem = "Eggs"
        model.addDraftItem()
        #expect(model.items == ["Eggs"])

        model.finishEntry()
        #expect(model.isFinished == true)

        model.resumeEditing()
        #expect(model.isFinished == false)
    }

    @Test("Generate list shuffles items and clear resets state")
    func shuffleAndClear() throws {
        let suite = "ListlerBasics-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Failed to create UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let model = ListlerModel(defaults: defaults)
        for item in ["A", "B", "C"] { model.draftItem = item; model.addDraftItem() }
        #expect(model.items.count == 3)

        model.generateList()
        #expect(model.generatedItems.count == 3)
        #expect(Set(model.generatedItems) == Set(model.items))

        model.clearList()
        #expect(model.items.isEmpty)
        #expect(model.generatedItems.isEmpty)
        #expect(model.draftItem.isEmpty)
        #expect(model.duplicateFlash == false)
        #expect(model.isFinished == false)
    }
}
