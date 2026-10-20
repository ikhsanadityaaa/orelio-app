import SwiftUI

struct BatchExportView: View {
    @EnvironmentObject private var store: LibraryStore
    @EnvironmentObject private var exporter: ExportManager
    @State private var scope = 0
    @State private var format: ExportFormat = .jpeg
    @State private var resolution: ExportResolution = .original
    @State private var quality = 0.91
    @State private var showShare = false

    private var candidates: [PhotoRecord] { scope == 0 ? store.selectedPhotos : store.photos }

    var body: some View {
        NavigationStack {
            Form {
                Section("Photos") {
                    Picker("Export", selection: $scope) {
                        Text("Selected (\(store.selectedPhotos.count))").tag(0)
                        Text("All (\(store.photos.count))").tag(1)
                    }.pickerStyle(.segmented)
                    if !candidates.isEmpty { ThumbnailStrip(photos: Array(candidates.prefix(15))) }
                    else { Text("Select images in Library first, or choose All.").foregroundStyle(.secondary) }
                }
                Section("Output Settings") {
                    Picker("File format", selection: $format) {
                        ForEach(ExportFormat.allCases) { item in Text(item.title).tag(item) }
                    }
                    Picker("Longest edge", selection: $resolution) {
                        ForEach(ExportResolution.allCases) { item in Text(item.title).tag(item) }
                    }
                    if format != .png {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text("Quality"); Spacer(); Text("\(Int(quality * 100))%") }
                            Slider(value: $quality, in: 0.5...1)
                        }
                    }
                    Text("Exports are rendered offline from non-destructive recipes. Photos are processed sequentially to avoid loading the whole batch into memory.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Export Queue") {
                    if exporter.isExporting {
                        ProgressView(value: exporter.progress)
                        Text("Processed \(exporter.completedCount) / \(exporter.totalCount) images")
                            .foregroundStyle(.secondary)
                        if !exporter.currentFilename.isEmpty {
                            Text("Current: \(exporter.currentFilename)")
                                .font(.caption).lineLimit(1)
                        }
                        Button("Stop after current photo", role: .destructive) { exporter.cancel() }
                            .disabled(exporter.wasCancelled)
                    } else {
                        if exporter.wasCancelled {
                            Label("Export stopped. Files already completed are retained.", systemImage: "pause.circle")
                                .font(.caption).foregroundStyle(.orange)
                        }
                        Button {
                            exporter.start(records: candidates, format: format,
                                           quality: quality, resolution: resolution)
                        } label: {
                            Label("Export \(candidates.count) Photos", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(candidates.isEmpty)
                    }
                    if !exporter.completedFiles.isEmpty {
                        Label("\(exporter.completedFiles.count) image(s) exported", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Button("Share / Save Exported Files") { showShare = true }
                    }
                    if !exporter.failures.isEmpty {
                        Text("\(exporter.failures.count) failures").foregroundStyle(.orange)
                        ForEach(exporter.failures) { failure in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(failure.record.originalFilename).font(.caption.weight(.semibold))
                                Text(failure.message).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Button("Retry Failed Photos") { exporter.retryFailed() }
                            .disabled(exporter.isExporting)
                    }
                    if let folder = exporter.exportFolder {
                        Text("Saved locally: \(folder.lastPathComponent)")
                            .font(.caption2).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Batch Export")
            .sheet(isPresented: $showShare) { ActivityShareSheet(files: exporter.completedFiles) }
        }
    }
}
