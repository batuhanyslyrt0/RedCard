import Foundation
import NaturalLanguage

/// The on-device text model, trained with Create ML on real, de-identified
/// betting and normal SMS (see Tools/TrainBetModel.swift). It gives the
/// classifier a second opinion that catches new brand names and wordings
/// the hand-written rules don't know yet.
///
/// It runs entirely on the device: nothing is downloaded or sent.
public final class BetTextModel: @unchecked Sendable {
    /// The model bundled with the package, or `nil` if it can't be loaded.
    public static let shared: BetTextModel? = BetTextModel()

    private let model: NLModel
    // NLModel isn't documented as thread-safe, so predictions are serialized.
    private let lock = NSLock()

    private init?() {
        guard let url = Bundle.module.url(forResource: "BetTextModel", withExtension: "mlmodelc"),
              let model = try? NLModel(contentsOf: url) else {
            return nil
        }
        self.model = model
    }

    /// Probability (0…1) that the message is a betting or casino advert.
    public func betProbability(for body: String) -> Double {
        let input = BetTextModelInput.text(for: body)
        guard !input.isEmpty else { return 0 }
        lock.lock()
        defer { lock.unlock() }
        return model.predictedLabelHypotheses(for: input, maximumCount: 2)["bet"] ?? 0
    }
}
