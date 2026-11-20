import SwiftUI
import RedCardCore

/// The person's own block and allow lists. These always win over the
/// built-in rules.
struct RulesView: View {
    var body: some View {
        List {
            ForEach(RuleList.allCases) { list in
                RuleListSection(list: list)
            }
        }
        .navigationTitle("Your rules")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct RuleListSection: View {
    let list: RuleList

    @Environment(SettingsModel.self) private var model
    @State private var draft = ""

    var body: some View {
        Section {
            ForEach(model.entries(in: list), id: \.self) { entry in
                Text(entry)
            }
            .onDelete(perform: delete)

            HStack {
                // Before iOS 26 the plain TextField(_:text:) can't take a
                // LocalizedStringResource, so the label is passed as Text.
                TextField(text: $draft, prompt: Text(list.placeholder)) {
                    Text(list.placeholder)
                }
                    .keyboardType(list.isSenderList ? .phonePad : .default)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(add)

                Button("Add", systemImage: "plus.circle.fill", action: add)
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    // Borderless keeps taps on the text field from triggering the button.
                    .buttonStyle(.borderless)
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text(list.title)
        } footer: {
            Text(list.footer)
        }
    }

    private func add() {
        if model.add(draft, to: list) {
            draft = ""
        }
    }

    private func delete(at offsets: IndexSet) {
        model.remove(atOffsets: offsets, from: list)
    }
}

extension RuleList {
    var title: LocalizedStringResource {
        switch self {
        case .blockedWords: "Always filter these words"
        case .blockedSenders: "Always filter these senders"
        case .allowedWords: "Never filter these words"
        case .allowedSenders: "Never filter these senders"
        }
    }

    var placeholder: LocalizedStringResource {
        switch self {
        case .blockedWords, .allowedWords: "Add a word or phrase"
        case .blockedSenders, .allowedSenders: "Add a phone number"
        }
    }

    var footer: LocalizedStringResource {
        switch self {
        case .blockedWords: "Any message containing one of these goes to Junk. Spelling tricks such as dots between letters are caught too."
        case .blockedSenders: "Numbers match in any format: 0532…, +90 532… and 532… are the same."
        case .allowedWords: "Messages containing one of these are never filtered, even if they look like betting."
        case .allowedSenders: "Use this for a number whose messages were filtered by mistake. Contacts never need adding: iOS doesn't send their messages to filters."
        }
    }
}

#Preview {
    NavigationStack {
        RulesView()
    }
    .environment(SettingsModel(store: SharedStore(suiteName: "preview")))
}
