// Prints the rules as JSON, ready to publish as Rules/rules.json.
//
// To ship new rules without an app update:
//   1. Edit DefaultRules.swift and raise `version`.
//   2. cd Packages/RedCardCore && swift test
//   3. swift run export-rules > ../../Rules/rules.json
//   4. Commit and push. Apps download it within a day.
import Foundation
import RedCardCore

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

do {
    try RuleSet.builtIn.validate()
    let data = try encoder.encode(RuleSet.builtIn)
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
} catch {
    FileHandle.standardError.write(Data("Rules are invalid: \(error)\n".utf8))
    exit(1)
}
