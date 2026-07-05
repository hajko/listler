import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The main screen of the Listler app.
///
/// This view presents three primary phases of the flow:
/// 1. Entry: Add items to your list.
/// 2. Finished: Lock the list and choose actions (Shuffle, Edit, Clear).
/// 3. Generated: Show a shuffled ordering of the original items.
///
/// It holds a `ListlerModel` which is an `@Observable` object. Because
/// the model is observable, changes to its properties automatically trigger
/// UI updates (e.g., adding items, toggling finished state, generating a list).
struct ContentView: View {
  /// The model that stores and manages the list data and actions.
  /// Using `@State` here keeps the model instance alive for the lifetime
  /// of this view and ensures UI updates when the model changes.
  @State private var model = ListlerModel()

  /// An ID used to scroll to the generated list after shuffling.
  private let generatedListID = "generated-list"

  var body: some View {
    NavigationStack { // Provides a navigation bar and a stack-based nav model.
      // ScrollViewReader lets us programmatically scroll to a particular view
      // (by ID) after the user taps "Shuffle".
      ScrollViewReader { proxy in
        ScrollView { // Allows the contents to scroll if they exceed the screen.
          VStack(alignment: .leading, spacing: 20) {
            // A brief description shown at the top of the screen.
            Text("Build a list, finish when you are ready, then generate a shuffled order.")
              .font(.subheadline)
              .foregroundStyle(.secondary)

            // The main conditional: show either the editing UI (entry + items)
            // or the finished panel based on the model's state.
            if model.isFinished {
              finishedPanel(scrollProxy: proxy)
            } else {
              entryPanel
              currentItemsPanel
            }

            // Once finished, if a shuffled list exists, show it below.
            if model.isFinished, !model.generatedItems.isEmpty {
              generatedItemsPanel
                .id(generatedListID) // Used for programmatic scrolling.
                .transition(.opacity) // Fade in/out when appearing or disappearing.
                .animation(.easeInOut(duration: 0.25), value: model.generatedItems)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(20)
        }
        // A grouped background color to visually separate content from the edges.
        .background(Color(.systemGroupedBackground))
      }
      .navigationTitle("Listler") // Title shown in the navigation bar.
    }
  }

  // MARK: - Panels (Sub-Views)

  /// Panel for entering items: includes a text field, an Add button,
  /// and a Finish button to lock the list for shuffling.
  private var entryPanel: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Add Items")
        .font(.headline)

      HStack(alignment: .top, spacing: 12) {
        // The text field is bound to the model's `draftItem`.
        // Using a custom Binding allows us to forward changes directly
        // to the model and keep this view as the source of truth for the UI.
        TextField(
          "Enter an item",
          text: Binding(
            get: { model.draftItem },
            set: { model.draftItem = $0 }
          )
        )
          .textFieldStyle(.roundedBorder)
          .textInputAutocapitalization(.words)
          .autocorrectionDisabled()
          .submitLabel(.done) // Keyboard action label.
          .onSubmit {
            // Pressing Return/Done triggers the same action as tapping Add.
            model.addDraftItem()
          }

        // Adds the current draft item to the list.
        Button("Add", systemImage: "plus") {
          model.addDraftItem()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!model.canAddItem) // Disabled if the draft is blank/whitespace.
      }

      // Show a brief red warning when the user attempts to add a duplicate.
      if model.duplicateFlash {
        Text("Duplicate item.")
          .font(.footnote)
          .foregroundStyle(.red)
          .accessibilityLabel("Duplicate item")
          .accessibilityHint("That item is already in the list.")
          .transition(.opacity)
          .animation(.easeInOut(duration: 0.25), value: model.duplicateFlash)
      }

      // Locks the list for shuffling. Disabled until there's at least one item.
      Button("Finish", systemImage: "checkmark") {
        model.finishEntry()
      }
      .buttonStyle(.bordered)
      .disabled(model.items.isEmpty)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(panelBackground)
    .onChange(of: model.duplicateFlash) { oldValue, newValue in
      if newValue {
        #if canImport(UIKit)
        // Haptic warning to indicate a duplicate attempt.
        let warning = UINotificationFeedbackGenerator()
        warning.prepare()
        warning.notificationOccurred(.warning)
        #endif
        // Auto-hide the duplicate warning after a short delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          // Only hide if it's still showing.
          if model.duplicateFlash {
            withAnimation(.easeInOut(duration: 0.25)) {
              model.duplicateFlash = false
            }
          }
        }
      }
    }
  }

  /// Panel shown after the list is finished. Offers actions to shuffle,
  /// return to editing, or clear the entire list.
  private func finishedPanel(scrollProxy: ScrollViewProxy) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Ready to Shuffle")
        .font(.headline)

      Text("Your list is locked in. Generate a random order any time, or go back and edit the items.")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      HStack(spacing: 12) {
        // Generates a shuffled copy of the original items and scrolls down
        // to reveal the generated list.
        Button("Shuffle", systemImage: "shuffle") {
          withAnimation(.easeInOut(duration: 0.25)) {
            model.generateList()
          }
          #if canImport(UIKit)
          // Subtle two-tap impact to simulate a shuffle feel.
          let impact = UIImpactFeedbackGenerator(style: .light)
          impact.prepare()
          impact.impactOccurred(intensity: 0.8)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            impact.impactOccurred(intensity: 0.5)
          }
          #endif
          withAnimation(.smooth) {
            scrollProxy.scrollTo(generatedListID, anchor: .top)
          }
        }
        .buttonStyle(.borderedProminent)

        // Returns to editing mode to add/remove items.
        Button("Edit", systemImage: "pencil") {
          model.resumeEditing()
        }
        .buttonStyle(.bordered)

        // Clears the entire list and resets the state.
        Button("Clear", systemImage: "trash") {
          model.clearList()
        }
        .buttonStyle(.bordered)
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(panelBackground)
  }

  /// Panel that displays the user's current items. While editing, each item
  /// has a remove button; in finished mode it's read-only.
  private var currentItemsPanel: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(model.isFinished ? "Original Items" : "Items")
        .font(.headline)

      if model.items.isEmpty {
        // Placeholder text when no items have been added yet.
        Text("No items yet.")
          .foregroundStyle(.secondary)
      } else {
        VStack(spacing: 10) {
          // We enumerate to display a 1-based index next to each item.
          ForEach(Array(model.items.enumerated()), id: \.offset) { index, item in
            HStack(spacing: 12) {
              // A secondary-styled index number (1., 2., 3., ...).
              Text("\(index + 1).")
                .foregroundStyle(.secondary)
                .monospacedDigit()

              // The item text stretches to fill the available width.
              Text(item)
                .frame(maxWidth: .infinity, alignment: .leading)

              // While editing, show a remove button per item.
              if !model.isFinished {
                Button("Remove", systemImage: "minus.circle.fill") {
                  model.removeItem(at: index)
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.red)
                .accessibilityLabel("Remove \(item)")
              }
            }
            .padding(.vertical, 6)
          }
        }
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(panelBackground)
  }

  /// Panel that displays the most recently generated (shuffled) list.
  private var generatedItemsPanel: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("List")
        .font(.headline)

      VStack(alignment: .leading, spacing: 10) {
        // Show a numbered list of the shuffled items.
        ForEach(Array(model.generatedItems.enumerated()), id: \.offset) { index, item in
          HStack(alignment: .top, spacing: 12) {
            // A tinted, emphasized index number for the generated list.
            Text("\(index + 1).")
              .fontWeight(.semibold)
              .foregroundStyle(.tint)
              .monospacedDigit()

            // The item text stretches to fill the available width.
            Text(item)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(panelBackground)
  }

  // MARK: - Styling Helpers

  /// A rounded rectangle used as a background for each panel to provide
  /// a card-like appearance against the grouped background.
  private var panelBackground: some View {
    RoundedRectangle(cornerRadius: 20, style: .continuous)
      .fill(Color(.secondarySystemBackground))
  }
}

