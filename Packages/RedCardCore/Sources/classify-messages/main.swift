// Runs the filter over a file of messages and prints the verdicts.
//
//   swift run classify-messages messages.jsonl > verdicts.jsonl
//
// Input: one JSON object per line with "body" and optional "sender".
// Output: the same objects with "decision", "score" and "signals" added.
// Used to check the rules against real messages; never commit real messages.
import Foundation
import RedCardCore

guard CommandLine.arguments.count == 2,
      let contents = try? String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8) else {
    FileHandle.standardError.write(Data("usage: classify-messages <file.jsonl>\n".utf8))
    exit(1)
}

let classifier = BetClassifier()
for line in contents.split(separator: "\n") {
    guard var object = (try? JSONSerialization.jsonObject(with: Data(line.utf8))) as? [String: Any],
          let body = object["body"] as? String else { continue }
    let verdict = classifier.classify(body: body, sender: object["sender"] as? String)
    object["decision"] = verdict.isJunk ? "junk" : "allow"
    object["score"] = verdict.score
    object["signals"] = verdict.signals.map { "\($0.kind.rawValue):\($0.detail):\($0.points)" }
    // The text exactly as the on-device model sees it.
    object["normalized"] = BetTextModelInput.text(for: body)
    if let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes]) {
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
