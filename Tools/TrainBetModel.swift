// Trains Red Card's on-device bet text model with Create ML and measures it.
//
//   swift Tools/TrainBetModel.swift train.json test.json OUT.mlmodel
//
// train.json / test.json: [{"text": "...", "label": "bet" | "normal"}]
// The text must already be normalized with BetTextModelInput (the
// classify-messages tool writes it as "normalized"). Training data contains
// real messages and must never be committed; only the model is.
import CoreML
import CreateML
import Foundation
import NaturalLanguage

struct Example: Decodable {
    let text: String
    let label: String
}

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    print("usage: swift Tools/TrainBetModel.swift train.json test.json OUT.mlmodel")
    exit(1)
}

func load(_ path: String) throws -> [Example] {
    try JSONDecoder().decode([Example].self, from: Data(contentsOf: URL(fileURLWithPath: path)))
}

let train = try load(arguments[1])
let test = try load(arguments[2])

var grouped: [String: [String]] = [:]
for example in train { grouped[example.label, default: []].append(example.text) }

let parameters = MLTextClassifier.ModelParameters(
    validation: .none,
    algorithm: .maxEnt(revision: 1),
    language: .turkish
)
let classifier = try MLTextClassifier(trainingData: grouped, parameters: parameters)

let outURL = URL(fileURLWithPath: arguments[3])
try classifier.write(to: outURL, metadata: MLModelMetadata(
    author: "Red Card",
    shortDescription: "Says whether a normalized SMS text is a betting/casino advert.",
    license: "Trained on de-identified data",
    version: "1"
))

// Measure on the held-out set with the compiled model, exactly as the app uses it.
let compiled = try MLModel.compileModel(at: outURL)
let model = try NLModel(contentsOf: compiled)

for threshold in [0.5, 0.7, 0.8, 0.9, 0.95] {
    var tp = 0, fp = 0, fn = 0, tn = 0
    for example in test {
        let p = model.predictedLabelHypotheses(for: example.text, maximumCount: 2)["bet"] ?? 0
        let saysBet = p >= threshold
        switch (saysBet, example.label == "bet") {
        case (true, true): tp += 1
        case (true, false): fp += 1
        case (false, true): fn += 1
        case (false, false): tn += 1
        }
    }
    let recall = Double(tp) / Double(max(tp + fn, 1))
    let precision = Double(tp) / Double(max(tp + fp, 1))
    print(String(format: "threshold %.2f  caught %d/%d bets (%.1f%%)  normal flagged %d/%d  precision %.1f%%",
                 threshold, tp, tp + fn, recall * 100, fp, fp + tn, precision * 100))
}
print("compiled model:", compiled.path)
