# Listler

A simple SwiftUI app to build a list of items, mark it as finished, and generate a random order. The original list persists across app launches using UserDefaults.

## Architecture Overview

- **App entry (App.swift)**
  - `@main` `ListlerApp` conforms to `App`.
  - Defines a `WindowGroup` that hosts `ContentView` as the root view.

- **View (ContentView.swift)**
  - Presents three phases of the UI:
    1. **Entry**: Add items via a text field and an Add button; Finish to lock the list.
    2. **Finished**: Actions to Shuffle (generate a random order), Edit (return to editing), or Clear (reset).
    3. **Generated**: Displays the shuffled list when available.
  - Holds `@State private var model = ListlerModel()` so UI updates automatically when the model changes.
  - Uses `ScrollViewReader` to scroll to the generated list after shuffling.

- **Model (ListlerModel.swift)**
  - Annotated with `@Observable` (Swift Observation) so UI updates when properties change.
  - State:
    - `draftItem`: current text input.
    - `items`: original list (persisted).
    - `generatedItems`: shuffled result (not persisted).
    - `isFinished`: whether editing is locked.
  - Actions:
    - `addDraftItem()`, `removeItem(at:)`, `finishEntry()`, `resumeEditing()`, `generateList()`, `clearList()`.
  - Persistence:
    - Saves and loads `items` using `UserDefaults` under key "listler.items".
    - On init, restores saved items and sets `isFinished = !items.isEmpty`.

## Data Flow

1. User types into the text field bound to `model.draftItem`.
2. Tapping Add (or pressing Return) calls `model.addDraftItem()` which appends to `items`, clears the draft, and persists.
3. Tapping Finish sets `isFinished = true` and reveals the Finished panel.
4. Tapping Shuffle sets `generatedItems = items.shuffled()` and scrolls to the results.
5. Tapping Edit sets `isFinished = false` to modify items again.
6. Tapping Clear resets all state and persists an empty list.

## Persistence Behavior

- The original list (`items`) is persisted; it reappears when the app restarts.
- The shuffled results (`generatedItems`) and in-progress input (`draftItem`) are not persisted.
- If items exist on launch, the app starts in the Finished state.

## Where to Change Things

- Customize validation: `addDraftItem()` in `ListlerModel`.
- Adjust persistence keys or strategy: `persistItems()` and `init` in `ListlerModel`.
- Modify UI layout/labels: panel subviews in `ContentView`.
- Change launch behavior (e.g., start in editing mode): tweak how `isFinished` is derived in `ListlerModel.init`.

## Configuration

- App display name is set in App/Info.plist via CFBundleDisplayName = "Listler".
- Bundle identifier and versions are configured in the target's Build Settings.
- Deployment target is set in the target's Build Settings (iOS 17 or later recommended).

## Requirements

- Xcode 15+ (Swift 5.9+) and iOS 17 or later (uses SwiftUI and the Observation framework).

## License

- Apple Standard EULA (https://www.apple.com/legal/internet-services/itunes/dev/stdeula/)

## Privacy Policy

- This app does not collect, store, or share any personal information. All data processing occurs locally on your device.

## Support

- To report bugs, email mvhs10s-listler@yahoo.com

