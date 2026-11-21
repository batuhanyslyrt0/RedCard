import SwiftUI
import RedCardCore

/// What Red Card does, what it can't do, and how it treats privacy.
struct AboutView: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        List {
            Section("Private by design") {
                Label("Every message is checked on your iPhone. Red Card has no account and no tracking.", systemImage: "iphone")
                Label("The filter has no internet access and can't store anything, so your messages never leave your phone.", systemImage: "lock")
                Label("The only exception is a message you report yourself from Messages: then its text is sent to Red Card, without your number or the sender's number.", systemImage: "exclamationmark.bubble")
                Link(destination: ReportServer.privacyPolicyURL) {
                    Label("Privacy policy", systemImage: "hand.raised")
                }
            }

            Section("Missed a bet message?") {
                Label("In Messages, report the message as spam and choose Red Card. It helps the filter learn new bet messages for everyone.", systemImage: "arrowshape.turn.up.right")
                Label("If Red Card isn't offered when you report, turn it on once: Settings › Apps › Phone › SMS/Call Reporting › Red Card.", systemImage: "gearshape")
            }

            Section("What Red Card checks") {
                Label("SMS and MMS from numbers that aren't in your contacts.", systemImage: "message")
                Label("It looks for betting words, betting brand names, betting site links, bonus amounts and spelling tricks such as dots between letters.", systemImage: "magnifyingglass")
                Label("A small AI model, trained on thousands of real bet and normal messages, gives a second opinion. It runs on your iPhone; nothing is sent.", systemImage: "sparkles")
            }

            Section("What iOS doesn't allow") {
                Label("Messages from your contacts and iMessages are never sent to filters.", systemImage: "person.2")
                Label("Filters can't delete messages or block numbers. Filtered messages wait in Spam, where you can still read them.", systemImage: "tray")
                Label("Filters can't keep a count, so Red Card can't show how many messages it filtered.", systemImage: "number")
            }

            Section {
                Label("Red Card is free, with no ads and no in-app purchases.", systemImage: "gift")
                if RuleUpdater.rulesURL != nil {
                    Label("Once a day the app may download an updated list of betting rules. Nothing about you or your messages is sent.", systemImage: "arrow.down.circle")
                }
                LabeledContent("Version", value: appVersion)
                LabeledContent("Rules version") {
                    Text(model.rules.version, format: .number)
                }
            }
        }
        .navigationTitle("How Red Card works")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
    .environment(SettingsModel(store: SharedStore(suiteName: "preview")))
}
