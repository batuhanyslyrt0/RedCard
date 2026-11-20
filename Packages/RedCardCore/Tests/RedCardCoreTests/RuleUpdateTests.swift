import Foundation
import Testing
@testable import RedCardCore

@Suite("Downloaded rules")
struct RuleUpdateTests {
    private func makeStore() -> SharedStore {
        SharedStore(suiteName: "RedCardCoreTests.\(UUID().uuidString)")
    }

    private func encoded(_ rules: RuleSet) throws -> Data {
        try JSONEncoder().encode(rules)
    }

    @Test("The built-in rules pass validation")
    func builtInRulesAreValid() throws {
        try RuleSet.builtIn.validate()
    }

    @Test("Uses built-in rules when nothing was downloaded")
    func defaultsToBuiltIn() {
        #expect(makeStore().activeRules() == .builtIn)
    }

    @Test("Uses newer downloaded rules")
    func usesNewerRules() throws {
        var newer = RuleSet.builtIn
        newer.version += 1
        newer.terms.append(WeightedTerm("yeni bet hilesi", 60))

        let store = makeStore()
        #expect(store.saveDownloadedRules(try encoded(newer)))
        #expect(store.activeRules() == newer)

        let verdict = BetClassifier(rules: store.activeRules())
            .classify(body: "Yeni bet hilesi burada", sender: nil)
        #expect(verdict.isJunk)
    }

    @Test("Ignores downloaded rules that are not newer than the built-in ones")
    func ignoresOlderRules() throws {
        var older = RuleSet.builtIn
        older.version = RuleSet.builtIn.version
        older.terms.append(WeightedTerm("eski", 60))

        let store = makeStore()
        store.saveDownloadedRules(try encoded(older))
        #expect(store.activeRules() == .builtIn)
    }

    @Test("Rejects broken or suspicious files")
    func rejectsBadFiles() throws {
        let store = makeStore()
        #expect(!store.saveDownloadedRules(Data("not json".utf8)))

        var almostEmpty = RuleSet.builtIn
        almostEmpty.version += 1
        almostEmpty.terms = [WeightedTerm("bonus", 15)]
        #expect(!store.saveDownloadedRules(try encoded(almostEmpty)))

        var hugeWeight = RuleSet.builtIn
        hugeWeight.version += 1
        hugeWeight.terms.append(WeightedTerm("merhaba", 1_000))
        #expect(!store.saveDownloadedRules(try encoded(hugeWeight)))

        #expect(store.activeRules() == .builtIn)
    }
}
