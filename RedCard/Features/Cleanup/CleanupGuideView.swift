import SwiftUI

/// Explains how to delete bet messages that arrived before Red Card was
/// installed. Apple doesn't let any app read or delete existing messages,
/// so this has to be done in Messages.
struct CleanupGuideView: View {
    var body: some View {
        List {
            Section {
                Text("Apple doesn't let any app read or delete messages already on your iPhone, so old bet messages need to be removed in Messages. These are the quickest ways.")
                    .foregroundStyle(.secondary)
            }

            Section {
                GuideStep(number: 1, text: "On your iPhone, check that Messages in iCloud is on: Settings › your name › iCloud › Messages.")
                GuideStep(number: 2, text: "Open Messages on a Mac signed in with the same Apple Account.")
                GuideStep(number: 3, text: "Hold Command and click each bet conversation, or click the first one and Shift-click the last.")
                GuideStep(number: 4, text: "Press Delete. The conversations are removed from your iPhone too.")
            } header: {
                Text("Fastest: with a Mac")
            } footer: {
                Text("Hundreds of conversations can be selected and deleted at once this way.")
            }

            Section("On iPhone") {
                GuideStep(number: 1, text: "Open Messages, tap the filter button at the top of the list and choose Unknown Senders.")
                GuideStep(number: 2, text: "Tap the More button or Edit, then Select Messages.")
                GuideStep(number: 3, text: "Tap each bet conversation, then tap Delete.")
            }
        }
        .navigationTitle("Clean up old messages")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GuideStep: View {
    let number: Int
    let text: LocalizedStringResource

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "\(number).circle")
                .foregroundStyle(.tint)
                .imageScale(.large)
        }
    }
}

#Preview {
    NavigationStack {
        CleanupGuideView()
    }
}
