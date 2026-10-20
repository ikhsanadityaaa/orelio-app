import Foundation
import SwiftUI
import PhotosUI
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var photos: [PhotoRecord] = []
    @Published var selectedIDs: Set<UUID> = []
    @Published var selectionMode = false
    @Published var activeID: UUID?
    @Published var currentTab: AppTab = .library
    @Published private(set) var copiedRecipe: EditRecipe?
    @Published private(set) var lastPasteCount = 0
    @Published private(set) var canUndoPaste = false
    private var undoPasteSnapshots: [UUID: EditRecipe] = [:]
    @Published private(set) var isImporting = false
    @Published private(set) var errorMessage: String?

    init() {
        do {
            try AppFolders.prepare()
            if FileManager.default.fileExists(atPath: AppFolders.manifest.path) {
                let data = try Data(contentsOf: AppFolders.manifest)
                let decoded = try JSONDecoder().decode([PhotoRecord].self, from: data)
                photos = decoded.filter { FileManager.default.fileExists(atPath: AppFolders.original($0).path) }
            }
            activeID = photos.first?.id
        } catch {
            errorMessage = "Library could not be loaded: \(error.localizedDescription)"
        }
    }

    var selectedPhotos: [PhotoRecord] { photos.filter { selectedIDs.contains($0.id) } }
    var activePhoto: PhotoRecord? { photos.first { $0.id == activeID } }

    func photo(_ id: UUID) -> PhotoRecord? { photos.first { $0.id == id } }

    func open(_ id: UUID) {
        if selectionMode {
            toggleSelection(id)
        } else {
            activeID = id
            currentTab = .editor
        }
    }

    func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
    }

    func selectAll() { selectedIDs = Set(photos.map(\.id)) }
    func clearSelection() { selectedIDs.removeAll() }

    func updateRecipe(for id: UUID, _ mutate: (inout EditRecipe) -> Void) {
        guard let index = photos.firstIndex(where: { $0.id == id }) else { return }
        undoPasteSnapshots.removeAll()
        canUndoPaste = false
        mutate(&photos[index].recipe)
        persist()
    }

    func resetRecipe(for id: UUID) { updateRecipe(for: id) { $0 = EditRecipe() } }

    func copyRecipe(from id: UUID) {
        copiedRecipe = photo(id)?.recipe
    }

    @discardableResult
    func pasteRecipe(to ids: Set<UUID>, options: PasteOptions = .all) -> Int {
        guard let recipe = copiedRecipe, options.hasAny else { return 0 }
        let previous = Dictionary(uniqueKeysWithValues: photos.filter { ids.contains($0.id) }.map { ($0.id, $0.recipe) })
        let count = BatchRecipeOperation.apply(recipe, to: &photos, ids: ids, options: options)
        lastPasteCount = count
        undoPasteSnapshots = count == 0 ? [:] : previous
        canUndoPaste = count > 0
        if count > 0 { persist() }
        return count
    }

    func undoLastPaste() {
        guard canUndoPaste else { return }
        for index in photos.indices {
            if let prior = undoPasteSnapshots[photos[index].id] { photos[index].recipe = prior }
        }
        undoPasteSnapshots.removeAll()
        canUndoPaste = false
        lastPasteCount = 0
        persist()
    }

    func applyActiveRecipeToSelection() {
        guard let activeID, let recipe = photo(activeID)?.recipe else { return }
        copiedRecipe = recipe
        pasteRecipe(to: selectedIDs)
    }

    func importFromPicker(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isImporting = true
        defer { isImporting = false }
        var failures = 0
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self), !data.isEmpty else {
                    failures += 1; continue
                }
                let suggested = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })?.preferredFilenameExtension?.lowercased() ?? "jpg"
                let supported = ["jpg", "jpeg", "png", "heic", "heif", "tif", "tiff", "dng"]
                let ext = supported.contains(suggested) ? suggested : "jpg"
                let id = UUID()
                let original = "\(id.uuidString).\(ext)"
                let thumb = "\(id.uuidString).jpg"
                let originalURL = AppFolders.originals.appendingPathComponent(original)
                try data.write(to: originalURL, options: .atomic)
                let thumbURL = AppFolders.thumbnails.appendingPathComponent(thumb)
                let created = await Task.detached(priority: .utility) {
                    ImagePipeline.shared.makeThumbnail(from: originalURL, to: thumbURL)
                }.value
                guard created else {
                    try? FileManager.default.removeItem(at: originalURL)
                    failures += 1; continue
                }
                photos.insert(PhotoRecord(id: id, originalFilename: original, thumbnailFilename: thumb), at: 0)
                activeID = id
                persist()
            } catch {
                failures += 1
            }
        }
        if failures > 0 { errorMessage = "\(failures) file(s) could not be imported. Check format and available storage." }
    }

    func deleteSelected() {
        undoPasteSnapshots.removeAll()
        canUndoPaste = false
        for record in selectedPhotos {
            try? FileManager.default.removeItem(at: AppFolders.original(record))
            try? FileManager.default.removeItem(at: AppFolders.thumbnail(record))
        }
        photos.removeAll { selectedIDs.contains($0.id) }
        selectedIDs.removeAll()
        if !photos.contains(where: { $0.id == activeID }) { activeID = photos.first?.id }
        persist()
    }

    func clearError() { errorMessage = nil }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(photos).write(to: AppFolders.manifest, options: .atomic)
        } catch {
            errorMessage = "Edits could not be saved: \(error.localizedDescription)"
        }
    }
}
