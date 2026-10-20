import SwiftUI
import PhotosUI

struct LibraryView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showDeleteConfirmation = false
    @State private var showPasteSheet = false
    @State private var pasteOptions = PasteOptions()
    private let columns = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]

    var body: some View {
        NavigationStack {
            Group {
                if store.photos.isEmpty {
                    EmptyPrompt(symbol: "photo.on.rectangle.angled", title: "Your film library",
                                subtitle: "Import photographs to start editing, building collages and batch exporting.")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(store.photos) { photo in
                                Button { store.open(photo.id) } label: {
                                    PhotoTile(record: photo, selected: store.selectedIDs.contains(photo.id), selecting: store.selectionMode)
                                }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 4).padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !store.photos.isEmpty {
                        Button(store.selectionMode ? "Done" : "Select") {
                            store.selectionMode.toggle()
                            if !store.selectionMode { store.clearSelection() }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $pickerItems, maxSelectionCount: 0, matching: .images) {
                        Label("Import", systemImage: "plus")
                    }.disabled(store.isImporting)
                }
            }
            .overlay {
                if store.isImporting {
                    ProgressView("Importing locally…")
                        .padding(22)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
            }
            .safeAreaInset(edge: .bottom) {
                if store.selectionMode && !store.photos.isEmpty {
                    selectionActions
                }
            }
            .sheet(isPresented: $showPasteSheet) { pasteSheet }
            .confirmationDialog("Delete selected photos from this app?", isPresented: $showDeleteConfirmation) {
                Button("Delete local copies", role: .destructive) { store.deleteSelected() }
            } message: {
                Text("Original photos in the system Photos library are not affected.")
            }
            .onChange(of: pickerItems) { newItems in
                guard !newItems.isEmpty else { return }
                Task {
                    await store.importFromPicker(newItems)
                    pickerItems = []
                }
            }
        }
    }

    private var selectionActions: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(store.selectedIDs.count) selected").font(.subheadline.weight(.semibold))
                Spacer()
                Button("All") { store.selectAll() }
                Button("Clear") { store.clearSelection() }
            }
            HStack(spacing: 12) {
                Button { showPasteSheet = true } label: {
                    Label("Paste Edits", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.copiedRecipe == nil || store.selectedIDs.isEmpty)

                Button {
                    store.currentTab = .export
                } label: { Label("Export", systemImage: "square.and.arrow.up") }
                .buttonStyle(.bordered)
                .disabled(store.selectedIDs.isEmpty)

                Button(role: .destructive) { showDeleteConfirmation = true } label: {
                    Image(systemName: "trash")
                }.buttonStyle(.bordered).disabled(store.selectedIDs.isEmpty)
            }
            .font(.caption)
            if store.canUndoPaste {
                HStack(spacing: 12) {
                    Text("Applied to \(store.lastPasteCount) photo(s)")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Undo last paste") { store.undoLastPaste() }
                        .font(.caption)
                }
            }
        }
        .padding(14)
        .background(.bar)
    }

    private var pasteSheet: some View {
        NavigationStack {
            Form {
                Section("Copy these settings") {
                    Toggle("Film look", isOn: $pasteOptions.film)
                    Toggle("Tone & color", isOn: $pasteOptions.tone)
                    Toggle("Grain, fade & vignette", isOn: $pasteOptions.texture)
                    Toggle("Lighting layers", isOn: $pasteOptions.lighting)
                    Toggle("Outline / border", isOn: $pasteOptions.border)
                }
                Section {
                    Text("Apply selected settings to \(store.selectedIDs.count) photo(s). Other adjustments will remain untouched. You can undo this paste.")
                        .foregroundStyle(.secondary)
                }
                Section {
                    Button("Apply to \(store.selectedIDs.count) Photos") {
                        store.pasteRecipe(to: store.selectedIDs, options: pasteOptions)
                        showPasteSheet = false
                    }
                    .disabled(!pasteOptions.hasAny || store.selectedIDs.isEmpty || store.copiedRecipe == nil)
                }
            }
            .navigationTitle("Paste Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { showPasteSheet = false }
            } }
        }
        .presentationDetents([.medium, .large])
    }
}
