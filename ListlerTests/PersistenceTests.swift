import Foundation
import Testing
@testable import Listler

@Suite("ListlerModel persistence")
struct ListlerModelPersistenceTests {
    @Test("Items persist across model instances using a custom defaults suite")
    func itemsPersistAcrossInstances() throws {
        let suiteName = "ListlerTests-\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create UserDefaults suite")
            return
        }
        defer { testDefaults.removePersistentDomain(forName: suiteName) }

        var model = ListlerModel(defaults: testDefaults)
        #expect(model.items.isEmpty)
        #expect(model.isFinished == false)

        model.draftItem = "Milk"
        model.addDraftItem()

        model = ListlerModel(defaults: testDefaults)
        #expect(model.items == ["Milk"]) // persisted
        #expect(model.isFinished == true)  // derived from non-empty items

        model.removeItem(at: 0)
        #expect(model.items.isEmpty)
        #expect(model.isFinished == false)

        model = ListlerModel(defaults: testDefaults)
        #expect(model.items.isEmpty)
        #expect(model.isFinished == false)
    }
}
