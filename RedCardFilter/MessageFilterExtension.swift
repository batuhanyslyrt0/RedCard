import IdentityLookup
import RedCardCore

/// iOS calls this extension for every SMS / MMS from a sender that is not
/// in the person's contacts. It runs fully on the device: there is no
/// network access and nothing is stored, so the message never leaves the phone.
final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    func handle(
        _ queryRequest: ILMessageFilterQueryRequest,
        context: ILMessageFilterExtensionContext,
        completion: @escaping (ILMessageFilterQueryResponse) -> Void
    ) {
        let store = SharedStore()
        // Downloaded rules when newer, otherwise the ones built into the app.
        let classifier = BetClassifier(rules: store.activeRules(), settings: store.load())
        let verdict = classifier.classify(
            body: queryRequest.messageBody ?? "",
            sender: queryRequest.sender
        )

        let response = ILMessageFilterQueryResponse()
        // `.none` leaves the decision to iOS, so ordinary messages behave
        // exactly as if the filter were not installed.
        response.action = verdict.isJunk ? .junk : .none
        completion(response)
    }
}
