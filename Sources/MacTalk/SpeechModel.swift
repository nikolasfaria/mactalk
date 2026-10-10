import CryptoKit
import Foundation

/// Parakeet TDT v3 (int8) from the sherpa-onnx Hugging Face mirror.
enum SpeechModel {
    struct File {
        let name: String
        let size: Int64
        let sha256: String
    }

    static let title = "Parakeet TDT v3"
    static let summary = "Highest accuracy for 25 European languages. Punctuation, capitalization, and word-level timestamps."
    static let downloadSize = "≈ 640 MB"

    private static let repo = "csukuangfj/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8"
    private static let revision = "2bda32ec70b097a55adaa07d9a7173915b43cc78"

    static let files: [File] = [
        File(name: "encoder.int8.onnx", size: 652_184_281,
             sha256: "acfc2b4456377e15d04f0243af540b7fe7c992f8d898d751cf134c3a55fd2247"),
        File(name: "decoder.int8.onnx", size: 11_845_275,
             sha256: "179e50c43d1a9de79c8a24149a2f9bac6eb5981823f2a2ed88d655b24248db4e"),
        File(name: "joiner.int8.onnx", size: 6_355_277,
             sha256: "3164c13fc2821009440d20fcb5fdc78bff28b4db2f8d0f0b329101719c0948b3"),
        File(name: "tokens.txt", size: 93_939,
             sha256: "d58544679ea4bc6ac563d1f545eb7d474bd6cfa467f0a6e2c1dc1c7d37e3c35d"),
    ]

    static var directory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("MacTalk/models/parakeet-tdt-0.6b-v3-int8", isDirectory: true)
    }

    static func url(for file: File) -> URL {
        URL(string: "https://huggingface.co/\(repo)/resolve/\(revision)/\(file.name)?download=true")!
    }

    static var isInstalled: Bool {
        files.allSatisfy { FileManager.default.fileExists(atPath: directory.appendingPathComponent($0.name).path) }
    }

    static func remove() throws {
        try FileManager.default.removeItem(at: directory)
    }

    static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 4 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

private final class ObservationBox: @unchecked Sendable {
    var value: NSKeyValueObservation?
}

@MainActor
final class ModelDownloader: ObservableObject {
    enum Phase: Equatable {
        case idle, downloading, verifying, failed(String)
    }

    @Published private(set) var phase: Phase = .idle
    /// Overall progress across all files, 0...1.
    @Published private(set) var progress: Double = 0

    var isBusy: Bool {
        phase == .downloading || phase == .verifying
    }

    func download() {
        guard !isBusy else { return }
        phase = .downloading
        progress = 0
        Task {
            do {
                try await fetchAll()
                phase = .idle
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    private func fetchAll() async throws {
        let directory = SpeechModel.directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let total = Double(SpeechModel.files.reduce(0) { $0 + $1.size })
        var doneBytes = 0.0

        for file in SpeechModel.files {
            let destination = directory.appendingPathComponent(file.name)
            if FileManager.default.fileExists(atPath: destination.path) {
                doneBytes += Double(file.size)
                progress = doneBytes / total
                continue
            }

            let base = doneBytes
            let temp = try await fetch(SpeechModel.url(for: file)) { fraction in
                Task { @MainActor in self.progress = (base + fraction * Double(file.size)) / total }
            }

            phase = .verifying
            let digest = try await Task.detached(priority: .utility) { try SpeechModel.sha256(of: temp) }.value
            guard digest == file.sha256 else {
                try? FileManager.default.removeItem(at: temp)
                throw DownloadError.checksumMismatch(file.name)
            }
            try FileManager.default.moveItem(at: temp, to: destination)
            phase = .downloading
            doneBytes += Double(file.size)
            progress = doneBytes / total
        }
    }

    /// Downloads to a temp file and reports fraction completed (0...1) for this file.
    private func fetch(_ url: URL, onProgress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let observer = ObservationBox()
            let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
                withExtendedLifetime(observer) {}  // keeps the KVO observer alive until the download finishes
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let tempURL, (response as? HTTPURLResponse)?.statusCode == 200 else {
                    continuation.resume(throwing: DownloadError.badResponse)
                    return
                }
                // Move out of the system temp location before the callback returns.
                let kept = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                do {
                    try FileManager.default.moveItem(at: tempURL, to: kept)
                    continuation.resume(returning: kept)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            observer.value = task.progress.observe(\.fractionCompleted) { progress, _ in
                onProgress(progress.fractionCompleted)
            }
            task.resume()
        }
    }

    enum DownloadError: LocalizedError {
        case badResponse
        case checksumMismatch(String)

        var errorDescription: String? {
            switch self {
            case .badResponse: return String(localized: "Download failed. Check your connection and try again.")
            case .checksumMismatch(let name): return String(localized: "Checksum mismatch for \(name). The file was discarded.")
            }
        }
    }
}
