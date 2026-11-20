import SwiftUI
import RedCardCore

/// Lets people paste any message and see what the filter would do with it,
/// and why. Uses exactly the same classifier and settings as the extension.
struct MessageTesterView: View {
    @Environment(SettingsModel.self) private var model
    @State private var message: String
    @State private var sender: String

    // Bet spam is Turkish, so the sample stays Turkish in every language.
    private static let sampleMessage = "D.E.N.E.M.E B0NUSU 500 TL + 100 FS! Çevrimsiz, anında çekim. Güncel giriş: cutt.ly/xyz"
    private static let sampleSender = "+90 532 000 00 00"

    init(startsWithSample: Bool = false) {
        _message = State(initialValue: startsWithSample ? Self.sampleMessage : "")
        _sender = State(initialValue: startsWithSample ? Self.sampleSender : "")
    }

    var body: some View {
        Form {
            Section {
                TextField("Paste or type a message", text: $message, axis: .vertical)
                    .lineLimit(4...10)
                TextField("Sender (optional)", text: $sender)
                    .textContentType(.telephoneNumber)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Message")
            } footer: {
                Text("For example +90 532 123 45 67. The sender helps a little, but the message text matters most.")
            }

            if let verdict = verdict() {
                Section {
                    VerdictSummary(verdict: verdict)
                }

                if !verdict.signals.isEmpty {
                    Section("Why") {
                        ForEach(verdict.signals) { signal in
                            SignalRow(signal: signal)
                        }
                    }
                }

                senderShortcut(for: verdict)
            } else {
                Section {
                    Button("Use a sample bet message", systemImage: "doc.on.clipboard", action: fillSample)
                }
            }
        }
        .navigationTitle("Try a message")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }

    /// One-tap fix when the result is wrong: block a bet sender that got
    /// through, or allow a sender that was filtered by mistake.
    /// Everything stays on the phone; nothing is reported anywhere.
    @ViewBuilder
    private func senderShortcut(for verdict: Verdict) -> some View {
        let trimmedSender = sender.trimmingCharacters(in: .whitespaces)
        let decidedByUserList = verdict.signals.contains { signal in
            [.userBlockedSender, .userAllowedSender, .userBlockedWord, .userAllowedWord].contains(signal.kind)
        }

        if !trimmedSender.isEmpty, !decidedByUserList {
            Section {
                if verdict.isJunk {
                    Button("Never filter this sender", systemImage: "hand.thumbsup") {
                        model.add(trimmedSender, to: .allowedSenders)
                    }
                } else {
                    Button("Always filter this sender", systemImage: "hand.raised") {
                        model.add(trimmedSender, to: .blockedSenders)
                    }
                }
            } header: {
                Text("Wrong result?")
            } footer: {
                Text("The sender is added to Your rules on this iPhone. You can remove it there at any time.")
            }
        }
    }

    private func verdict() -> Verdict? {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return model.makeClassifier().classify(body: message, sender: sender.isEmpty ? nil : sender)
    }

    private func fillSample() {
        message = Self.sampleMessage
        sender = Self.sampleSender
    }
}

private struct VerdictSummary: View {
    let verdict: Verdict

    var body: some View {
        HStack(spacing: 16) {
            if verdict.isJunk {
                RedCardMark(width: 34)
                    .rotationEffect(Theme.cardRestingTilt)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Two separate Text values, so both strings are localized.
                (verdict.isJunk ? Text("Goes to Junk") : Text("Stays in your inbox"))
                    .font(Theme.verdictTitle)

                Gauge(value: Double(min(max(verdict.score, 0), verdict.threshold)), in: 0...Double(verdict.threshold)) {
                    Text("Score")
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .labelsHidden()
                .tint(verdict.isJunk ? Color(.cardRed) : .green)

                Text("Score \(verdict.score), filtered from \(verdict.threshold)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct SignalRow: View {
    let signal: Signal

    var body: some View {
        LabeledContent {
            if signal.points != 0 {
                Text(signal.points, format: .number.sign(strategy: .always()))
                    .monospacedDigit()
                    .foregroundStyle(signal.points > 0 ? Color(.cardRed) : .green)
            }
        } label: {
            Label {
                Text(signal.title)
            } icon: {
                Image(systemName: signal.systemImage)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MessageTesterView()
    }
    .environment(SettingsModel(store: SharedStore(suiteName: "preview")))
}
