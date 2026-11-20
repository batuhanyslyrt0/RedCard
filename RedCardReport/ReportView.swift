import Observation
import RedCardCore
import SwiftUI

@MainActor
@Observable
final class ReportModel {
    var messages: [ReportPayload.Message] = []
    var choice: ReportPayload.Kind? {
        didSet { if choice != nil { onChoice?() } }
    }
    @ObservationIgnored var onChoice: (() -> Void)?
}

/// The report sheet: the message, one question, and exactly what is sent.
struct ReportView: View {
    @Bindable var model: ReportModel

    var body: some View {
        Form {
            if let message = model.messages.last {
                Section("Message") {
                    Text(message.body)
                        .lineLimit(8)
                        .textSelection(.enabled)
                }
            }

            Section {
                ChoiceRow(
                    title: "Yes, it's a betting or casino ad",
                    systemImage: "hand.raised.fill",
                    isSelected: model.choice == .junk
                ) { model.choice = .junk }

                ChoiceRow(
                    title: "No, it's a normal message",
                    systemImage: "checkmark.circle.fill",
                    isSelected: model.choice == .notJunk
                ) { model.choice = .notJunk }
            } header: {
                Text("Is this a bet message?")
            } footer: {
                Text("When you tap Report, only the text of this message, the kind of sender (for example “mobile number”) and Red Card's own score are sent to Red Card. The sender's number, your number and who you are are never sent. Reports are used only to teach the filter new bet messages.")
            }
        }
    }
}

private struct ChoiceRow: View {
    let title: LocalizedStringResource
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label {
                    Text(title)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: systemImage)
                        .foregroundStyle(.tint)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .bold()
                }
            }
            .contentShape(.rect)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
