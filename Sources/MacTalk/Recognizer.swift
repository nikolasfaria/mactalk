import Foundation

/// Runs Parakeet off the main thread. The sherpa recognizer is not thread-safe, so every call goes through one serial queue.
final class Recognizer: @unchecked Sendable {
    private let queue = DispatchQueue(label: "mactalk.recognizer", qos: .userInitiated)
    private var recognizer: SherpaOnnxOfflineRecognizer?

    /// Loads the model ahead of the first dictation so the first ⌘E is instant.
    func preload() {
        queue.async { self.loadIfNeeded() }
    }

    func transcribe(_ samples: [Float]) async -> String {
        await withCheckedContinuation { continuation in
            queue.async {
                self.loadIfNeeded()
                let text = self.recognizer?.decode(samples: samples).text ?? ""
                continuation.resume(returning: text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }

    /// Drop the loaded model, e.g. after the user deletes it.
    func unload() {
        queue.async { self.recognizer = nil }
    }

    private func loadIfNeeded() {
        guard recognizer == nil, SpeechModel.isInstalled else { return }
        let dir = SpeechModel.activeDirectory.path
        let transducer = sherpaOnnxOfflineTransducerModelConfig(
            encoder: "\(dir)/encoder.int8.onnx",
            decoder: "\(dir)/decoder.int8.onnx",
            joiner: "\(dir)/joiner.int8.onnx"
        )
        let modelConfig = sherpaOnnxOfflineModelConfig(
            tokens: "\(dir)/tokens.txt",
            transducer: transducer,
            numThreads: 4,
            modelType: "nemo_transducer"
        )
        var config = sherpaOnnxOfflineRecognizerConfig(
            featConfig: sherpaOnnxFeatureConfig(sampleRate: 16_000, featureDim: 80),
            modelConfig: modelConfig,
            decodingMethod: "greedy_search"
        )
        recognizer = SherpaOnnxOfflineRecognizer(config: &config)
    }
}
