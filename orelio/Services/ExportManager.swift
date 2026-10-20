import Foundation
import SwiftUI

struct ExportFailure: Identifiable {
    let record: PhotoRecord
    let message: String
    var id: UUID { record.id }
}

/// Sequential, local batch queue. A cancellation takes effect between files.
@MainActor
final class ExportManager: ObservableObject {
    @Published private(set) var isExporting = false
    @Published private(set) var wasCancelled = false
    @Published private(set) var progress = 0.0
    @Published private(set) var completedCount = 0
    @Published private(set) var totalCount = 0
    @Published private(set) var completedFiles: [URL] = []
    @Published private(set) var failures: [ExportFailure] = []
    @Published private(set) var exportFolder: URL?
    @Published private(set) var currentFilename = ""

    private var job: Task<Void, Never>?
    private var configuration: (format: ExportFormat, quality: Double, resolution: ExportResolution)?

    func start(records: [PhotoRecord], format: ExportFormat, quality: Double,
               resolution: ExportResolution) {
        guard !isExporting, !records.isEmpty else { return }
        job?.cancel()
        configuration = (format, quality, resolution)
        completedFiles = []
        exportFolder = nil
        failures = []
        launch(records: records, into: nil)
    }

    func retryFailed() {
        guard !isExporting, !failures.isEmpty, configuration != nil else { return }
        let records = failures.map(\.record)
        failures = []
        launch(records: records, into: exportFolder)
    }

    func cancel() {
        guard isExporting else { return }
        wasCancelled = true
        job?.cancel()
    }

    private func launch(records: [PhotoRecord], into existing: URL?) {
        guard let configuration else { return }
        isExporting = true
        wasCancelled = false
        completedCount = 0
        totalCount = records.count
        progress = 0
        currentFilename = ""
        job = Task { [weak self] in
            guard let self else { return }
            do {
                let directory = try existing ?? AppFolders.newExportDirectory(prefix: "orelio-photos")
                self.exportFolder = directory
                for (index, record) in records.enumerated() {
                    if Task.isCancelled { self.wasCancelled = true; break }
                    self.currentFilename = record.originalFilename
                    // Keep names unique when retrying into the same directory.
                    let destination = directory.appendingPathComponent("\(record.id.uuidString).\(configuration.format.fileExtension)")
                    let result = await Task.detached(priority: .utility) { () -> Result<URL, Error> in
                        do {
                            try ImagePipeline.shared.export(record,
                                format: configuration.format,
                                quality: configuration.quality,
                                maxDimension: configuration.resolution.longestSide,
                                to: destination)
                            return .success(destination)
                        } catch { return .failure(error) }
                    }.value
                    switch result {
                    case .success(let url):
                        if !self.completedFiles.contains(url) { self.completedFiles.append(url) }
                    case .failure(let error):
                        self.failures.append(ExportFailure(record: record, message: error.localizedDescription))
                    }
                    self.completedCount = index + 1
                    self.progress = Double(self.completedCount) / Double(self.totalCount)
                }
            } catch {
                for record in records { self.failures.append(ExportFailure(record: record, message: error.localizedDescription)) }
            }
            self.currentFilename = ""
            self.isExporting = false
            self.job = nil
        }
    }
}
