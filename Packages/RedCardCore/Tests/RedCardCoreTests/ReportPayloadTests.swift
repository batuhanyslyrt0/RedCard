import Foundation
import Testing
@testable import RedCardCore

@Suite("Report payload")
struct ReportPayloadTests {
    private func payload(body: String, sender: String?) -> [String: Any] {
        ReportPayload.make(
            kind: .junk,
            messages: [ReportPayload.Message(body: body, sender: sender, receivedAt: Date(timeIntervalSince1970: 1_800_000_000))],
            rules: .builtIn,
            settings: FilterSettings(),
            appVersion: "1.0"
        )
    }

    @Test("Is valid JSON")
    func isValidJSON() {
        let report = payload(body: "Deneme bonusu", sender: "+905321234567")
        #expect(JSONSerialization.isValidJSONObject(report))
    }

    @Test("Never contains the sender's number")
    func hidesSender() throws {
        let report = payload(body: "Deneme bonusu", sender: "+905321234567")
        let data = try JSONSerialization.data(withJSONObject: report)
        let text = String(decoding: data, as: UTF8.self)
        #expect(!text.contains("5321234567"))
        #expect(text.contains("personalNumber"))
    }

    @Test("Includes the filter's own verdict")
    func includesVerdict() throws {
        let report = payload(body: "Deneme bonusu 500 TL guncel giris bit.ly/x", sender: nil)
        let message = try #require((report["messages"] as? [[String: Any]])?.first)
        #expect(message["localDecision"] as? String == "junk")
        #expect(message["receivedDay"] as? String == "2027-01-15")
    }

    @Test("Cuts very long messages")
    func limitsLength() throws {
        let report = payload(body: String(repeating: "a", count: 10_000), sender: nil)
        let message = try #require((report["messages"] as? [[String: Any]])?.first)
        #expect((message["body"] as? String)?.count == ReportPayload.maximumBodyLength)
    }
}
