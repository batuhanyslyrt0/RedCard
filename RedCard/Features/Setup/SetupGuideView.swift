import SwiftUI
import UIKit

/// Walks the person through switching the filter on in Settings.
/// iOS gives apps no way to check whether the filter is on, so the person
/// confirms it themselves at the end.
struct SetupGuideView: View {
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SetupStep(number: 1, text: "Open the Settings app.")
                    SetupStep(number: 2, text: "Scroll down and tap Apps, then Messages.")
                    SetupStep(number: 3, text: "Tap Unknown & Spam.")
                    SetupStep(number: 4, text: "Under Text Message Filter, choose Red Card.")
                } header: {
                    Text("Four steps in Settings")
                } footer: {
                    Text("The button below opens Red Card's page in Settings. Go back once to reach Apps.")
                }

                Section {
                    Button("Open Settings", systemImage: "gear", action: openSettings)
                }

                Section("Where filtered messages go") {
                    Label("In Messages, tap the filter button at the top of the list, then Spam. Filtered messages wait there without a notification.", systemImage: "tray")
                    Label("Messages from your contacts are never checked or filtered.", systemImage: "person.crop.circle.badge.checkmark")
                }
            }
            .navigationTitle("Turn on the filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("It's on", action: complete)
                        .bold()
                }
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func complete() {
        onComplete()
        dismiss()
    }
}

/// One numbered step. These really are a sequence, so numbers are useful here.
private struct SetupStep: View {
    let number: Int
    let text: LocalizedStringResource

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "\(number).circle.fill")
                .foregroundStyle(.tint)
                .imageScale(.large)
        }
    }
}

#Preview {
    SetupGuideView {}
}
