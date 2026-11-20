import SwiftUI
import RedCardCore

struct HomeView: View {
    @Environment(SettingsModel.self) private var model
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @State private var isShowingSetup = false

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            List {
                Section {
                    HomeHeader(
                        hasCompletedSetup: hasCompletedSetup,
                        showSetup: showSetup
                    )
                }
                .listRowBackground(Color.clear)

                Section {
                    NavigationLink {
                        MessageTesterView()
                    } label: {
                        Label("Try a message", systemImage: "text.magnifyingglass")
                    }

                    NavigationLink {
                        RulesView()
                    } label: {
                        Label("Your rules", systemImage: "list.bullet.rectangle")
                    }

                    Picker(selection: $model.strictness) {
                        ForEach(Strictness.allCases) { strictness in
                            Text(strictness.title).tag(strictness)
                        }
                    } label: {
                        Label("Strictness", systemImage: "dial.medium")
                    }
                } footer: {
                    Text(model.strictness.explanation)
                }

                Section {
                    NavigationLink {
                        CleanupGuideView()
                    } label: {
                        Label("Clean up old messages", systemImage: "trash")
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("How Red Card works", systemImage: "lock.shield")
                    }
                }
            }
            .navigationTitle("Red Card")
            .sheet(isPresented: $isShowingSetup) {
                SetupGuideView {
                    hasCompletedSetup = true
                }
            }
        }
    }

    private func showSetup() {
        isShowingSetup = true
    }
}

/// The card, one sentence about what the app does, and the setup button.
private struct HomeHeader: View {
    let hasCompletedSetup: Bool
    let showSetup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // The launch splash is the app's one motion moment, so the
            // card simply rests here.
            RedCardMark(width: 116)
                .rotationEffect(Theme.cardRestingTilt)
                .frame(maxWidth: .infinity)
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 8) {
                Text("Bet messages stay out of your inbox.")
                    .font(Theme.headline)

                Text("Red Card checks texts from unknown senders on your iPhone and moves betting and casino adverts to Junk.")
                    .foregroundStyle(.secondary)
            }

            if hasCompletedSetup {
                // iOS gives apps no way to read whether the SMS filter is on,
                // so the app never claims it is. It says so and offers a check.
                VStack(alignment: .leading, spacing: 10) {
                    Label("iOS doesn't tell apps whether the filter is on, so Red Card can't show it here. If bet messages reach your inbox again, check that Red Card is still chosen in Settings.", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Check in Settings", systemImage: "gear", action: showSetup)
                        .buttonStyle(.bordered)
                }
            } else {
                Button(action: showSetup) {
                    Text("Turn on the filter")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .listRowInsets(EdgeInsets())
    }
}

extension Strictness {
    var title: LocalizedStringResource {
        switch self {
        case .relaxed: "Relaxed"
        case .balanced: "Balanced"
        case .strict: "Strict"
        }
    }

    var explanation: LocalizedStringResource {
        switch self {
        case .relaxed: "Only messages that are clearly betting adverts go to Junk. Choose this if a normal message was ever filtered by mistake."
        case .balanced: "Recommended. Catches almost every bet message while leaving bank, cargo and code messages alone."
        case .strict: "Also catches messages with only a few betting signs. A normal message may occasionally end up in Junk."
        }
    }
}

#Preview {
    HomeView()
        .environment(SettingsModel(store: SharedStore(suiteName: "preview")))
}
