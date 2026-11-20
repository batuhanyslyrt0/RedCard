import IdentityLookup
import IdentityLookupUI
import RedCardCore
import SwiftUI

/// Shown by Messages when someone taps "Report" on a message from an unknown
/// sender. The person says whether it is a bet message; iOS then sends the
/// payload from `classificationResponse(for:)` to Red Card's server.
final class ReportViewController: ILClassificationUIExtensionViewController {
    private let model = ReportModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        let host = UIHostingController(rootView: ReportView(model: model))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)

        // The system's Report button stays disabled until a choice is made.
        model.onChoice = { [weak self] in
            self?.extensionContext.isReadyForClassificationResponse = true
        }
    }

    override func prepare(for request: ILClassificationRequest) {
        guard let request = request as? ILMessageClassificationRequest else { return }
        model.messages = request.messageCommunications.map {
            ReportPayload.Message(body: $0.messageBody ?? "", sender: $0.sender, receivedAt: $0.dateReceived)
        }
    }

    override func classificationResponse(for request: ILClassificationRequest) -> ILClassificationResponse {
        guard let choice = model.choice else {
            return ILClassificationResponse(action: .none)
        }

        let store = SharedStore()
        let response = ILClassificationResponse(action: choice == .junk ? .reportJunk : .reportNotJunk)
        response.userInfo = ReportPayload.make(
            kind: choice,
            messages: model.messages,
            rules: store.activeRules(),
            settings: store.load(),
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        )
        return response
    }
}
