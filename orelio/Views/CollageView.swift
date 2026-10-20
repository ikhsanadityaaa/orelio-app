import SwiftUI
import UIKit

/// Offline multipage layout editor. Design projects are stored only on the device.
struct CollageView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var pages: [CollagePage] = [CollagePage(layout: .editorial)]
    @State private var pageIndex = 0
    @State private var slotIndex = 0
    @State private var showLayouts = false
    @State private var showPhotos = false
    @State private var addPhotoAsNewPage = false
    @State private var isWorking = false
    @State private var output: [URL] = []
    @State private var showShare = false
    @State private var showExportOptions = false
    @State private var selectedPageIDs: Set<UUID> = []
    @State private var errorText: String?
    private let projectKey = "orelio.collage.pages.v03"

    private var currentPage: CollagePage { pages[pageIndex] }
    private enum ExportScope { case current, selected, all }
    private func toggleSelection(for id: UUID) {
        if selectedPageIDs.contains(id) { selectedPageIDs.remove(id) }
        else { selectedPageIDs.insert(id) }
    }
    private func exportIndices(for scope: ExportScope) -> [Int] {
        switch scope {
        case .current: [pageIndex]
        case .selected: pages.indices.filter { selectedPageIDs.contains(pages[$0].id) }
        case .all: Array(pages.indices)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("CREATE").font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary)
                            Text("Collage").font(.largeTitle.weight(.semibold))
                        }
                        Spacer()
                        Text("OFFLINE").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("\(selectedPageIDs.count) selected", systemImage: "checkmark.circle")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button("Select All") { selectedPageIDs = Set(pages.map(\.id)) }.font(.caption)
                        Button("Clear") { selectedPageIDs.removeAll() }
                            .font(.caption).disabled(selectedPageIDs.isEmpty)
                    }
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(pages.indices, id: \.self) { index in
                                VStack(spacing: 5) {
                                    Button { pageIndex = index } label: {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(pages[index].background == .black ? Color.black : Color.white)
                                            .frame(width: 64, height: 79)
                                            .overlay {
                                                Image(systemName: "square.on.square")
                                                    .foregroundStyle(pages[index].background == .black ? Color.white : Color.black)
                                            }
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 7)
                                                    .strokeBorder(index == pageIndex ? Color.orange : Color.gray.opacity(0.4),
                                                                  lineWidth: index == pageIndex ? 2 : 1)
                                            }
                                    }.buttonStyle(.plain)
                                    Button { toggleSelection(for: pages[index].id) } label: {
                                        Label("Page \(index + 1)",
                                              systemImage: selectedPageIDs.contains(pages[index].id) ?
                                              "checkmark.circle.fill" : "circle")
                                            .font(.caption2)
                                            .foregroundStyle(selectedPageIDs.contains(pages[index].id) ?
                                                             Color.orange : Color.primary)
                                    }.buttonStyle(.plain)
                                }.padding(3)
                            }
                            Button { addContinuationPage() } label: {
                                VStack(spacing: 5) {
                                    RoundedRectangle(cornerRadius: 7)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                                        .frame(width: 64, height: 79)
                                        .overlay(Image(systemName: "plus"))
                                    Text("New Page").font(.caption2)
                                }.padding(3)
                            }.buttonStyle(.plain).disabled(pages.count >= 20)
                        }
                    }.scrollIndicators(.hidden)
                    HStack {
                        Text("Page \(pageIndex + 1) of \(pages.count)").font(.headline)
                        Spacer()
                        Button { showLayouts = true } label: { Label("Choose Layout", systemImage: "square.grid.2x2") }
                            .buttonStyle(.bordered)
                    }
                    HStack(spacing: 10) {
                        Picker("Page Ratio", selection: Binding(
                            get: { currentPage.ratio },
                            set: { value in
                                for index in pages.indices { pages[index].ratio = value }
                                output = []
                            })) {
                            ForEach(CollageAspectRatio.allCases) { ratio in
                                Text(ratio.rawValue).tag(ratio)
                            }
                        }.pickerStyle(.menu)
                        Spacer()
                        Toggle("Proportional", isOn: Binding(
                            get: { currentPage.proportionalSpacing },
                            set: { value in
                                for index in pages.indices { pages[index].proportionalSpacing = value }
                                output = []
                            }))
                            .font(.caption)
                    }
                    HStack(spacing: 10) {
                        Text("Page Background").font(.subheadline.weight(.medium))
                        Spacer()
                        Picker("Page Background", selection: Binding(
                            get: { currentPage.background },
                            set: { value in
                                pages[pageIndex].background = value
                                output = []
                            })) {
                            ForEach(CollageBackground.allCases) { color in
                                Text(color.title).tag(color)
                            }
                        }.pickerStyle(.segmented).frame(maxWidth: 180)
                    }
                    Text("Proportional makes every outer margin and shared image seam equally thick.")
                        .font(.caption2).foregroundStyle(.secondary)
                    pageCanvas
                    HStack {
                        Text(currentPage.layout.title).font(.subheadline.weight(.medium))
                        Spacer()
                        Button { shiftPage(-1) } label: { Label("Left", systemImage: "arrow.left") }
                            .buttonStyle(.bordered)
                            .disabled(pageIndex == 0)
                        Button { shiftPage(1) } label: { Label("Right", systemImage: "arrow.right") }
                            .buttonStyle(.bordered)
                            .disabled(pageIndex == pages.count - 1)
                    }.font(.caption)
                    HStack {
                        Text("Spacing").font(.caption)
                        Slider(value: Binding(get: { currentPage.margin }, set: { pages[pageIndex].margin = $0; output = [] }), in: 0...0.075)
                        Button(role: .destructive) { removePage() } label: { Image(systemName: "trash") }
                            .disabled(pages.count < 2)
                    }
                    Text("Tap a frame to choose a photo, or Add as New Page to create the next continuation. Ratio changes apply to all pages.")
                        .font(.caption).foregroundStyle(.secondary)
                    if isWorking { ProgressView("Rendering pages offline…") }
                    if let errorText { Text(errorText).font(.caption).foregroundStyle(.orange) }
                    if !output.isEmpty {
                        Label("\(output.count) pages saved to export folder", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(.green)
                        Button { showShare = true } label: {
                            Label("Share / Save Pages", systemImage: "square.and.arrow.up")
                        }.buttonStyle(OrelioActionButtonStyle())
                    }
                    Button { showExportOptions = true } label: {
                        Label("Export Pages", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(OrelioActionButtonStyle(tone: .primary)).disabled(isWorking || pages.allSatisfy { $0.photoIDs.allSatisfy { $0 == nil } })
                }.padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Collage")
            .sheet(isPresented: $showLayouts) { layoutSheet }
            .sheet(isPresented: $showPhotos) { photoSheet }
            .sheet(isPresented: $showShare) { ActivityShareSheet(files: output) }
            .confirmationDialog("Export Collage", isPresented: $showExportOptions,
                                titleVisibility: .visible) {
                Button("Export Current Page") { exportPages(scope: .current) }
                Button("Export Selected Pages (\(selectedPageIDs.count))") {
                    exportPages(scope: .selected)
                }.disabled(selectedPageIDs.isEmpty)
                Button("Export All Pages (\(pages.count))") { exportPages(scope: .all) }
            } message: {
                Text("Export pages as JPG using each page's background and selected ratio.")
            }
            .onAppear { loadProject() }
            .onChange(of: pages) { _, _ in
                selectedPageIDs.formIntersection(Set(pages.map(\.id)))
                saveProject()
            }
        }
    }

    private var pageCanvas: some View {
        GeometryReader { geo in
            let bounds = CGSize(width: geo.size.width, height: geo.size.height)
            ZStack(alignment: .topLeading) {
                (currentPage.background == .black ? Color.black : Color.white)
                ForEach(0..<currentPage.layout.slotCount, id: \.self) { i in
                    let rect = currentPage.slotRect(i, canvasSize: bounds)
                    let width = max(1, rect.width)
                    let height = max(1, rect.height)
                    Button {
                        slotIndex = i
                        addPhotoAsNewPage = false
                        showPhotos = true
                    } label: {
                        ZStack {
                            Color(red: 0.80, green: 0.77, blue: 0.73)
                            if i < currentPage.photoIDs.count,
                               let id = currentPage.photoIDs[i],
                               let record = store.photo(id),
                               let image = UIImage(contentsOfFile: AppFolders.thumbnail(record).path) {
                                Image(uiImage: image).resizable().scaledToFill()
                            } else {
                                VStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill").font(.title2)
                                    Text("Add Photo").font(.caption2)
                                }.foregroundStyle(.black.opacity(0.6))
                            }
                        }
                        .frame(width: width, height: height)
                        .clipped()
                    }
                    .buttonStyle(.plain)
                    .frame(width: width, height: height)
                    .position(x: rect.midX, y: rect.midY)
                }
            }
        }
        .aspectRatio(currentPage.ratio.ratio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var layoutSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(CollageLayout.allCases) { layout in
                        Button {
                            pages[pageIndex].changeLayout(layout)
                            showLayouts = false
                            output = []
                        } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .topLeading) {
                                    Color(red: 0.95, green: 0.93, blue: 0.89)
                                    GeometryReader { g in
                                        ForEach(layout.rects.indices, id: \.self) { i in
                                            let r = layout.rects[i].insetBy(dx: 0.016, dy: 0.016)
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color(red: 0.47, green: 0.39, blue: 0.33))
                                                .frame(width: g.size.width * r.width, height: g.size.height * r.height)
                                                .position(x: g.size.width * r.midX, y: g.size.height * r.midY)
                                        }
                                    }
                                }.frame(height: 160)
                                Text(layout.title).font(.subheadline.weight(.medium))
                            }
                        }.buttonStyle(.plain)
                    }
                }.padding()
            }.navigationTitle("Choose Layout")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showLayouts = false } } }
        }
    }

    private var photoSheet: some View {
        NavigationStack {
            List {
                Toggle(isOn: $addPhotoAsNewPage) {
                    Label("Add as New Page", systemImage: "plus.square.on.square")
                }
                Text(addPhotoAsNewPage ? "This photo starts the next page, immediately after the current one." :
                     "Replace the selected frame.")
                    .font(.caption).foregroundStyle(.secondary)
                if !addPhotoAsNewPage && !currentPage.photoIDs.isEmpty,
                   currentPage.photoIDs.indices.contains(slotIndex), currentPage.photoIDs[slotIndex] != nil {
                    Button("Clear Frame", role: .destructive) {
                        pages[pageIndex].photoIDs[slotIndex] = nil
                        showPhotos = false
                    }
                }
                ForEach(store.photos) { photo in
                    Button {
                        if addPhotoAsNewPage {
                            addContinuationPage(photoID: photo.id)
                        } else {
                            pages[pageIndex].photoIDs[slotIndex] = photo.id
                        }
                        showPhotos = false
                        output = []
                    } label: {
                        HStack {
                            if let img = UIImage(contentsOfFile: AppFolders.thumbnail(photo).path) {
                                Image(uiImage: img).resizable().scaledToFill().frame(width: 56, height: 56).clipped()
                            }
                            Text("Photo \(store.photos.firstIndex(where: { $0.id == photo.id })! + 1)")
                            Spacer()
                            if currentPage.photoIDs.contains(photo.id) { Image(systemName: "checkmark").foregroundStyle(.orange) }
                        }
                    }.foregroundStyle(.primary)
                }
            }
            .navigationTitle("Choose Photo")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showPhotos = false } } }
        }
    }

    // Sequential insert, rather than appending at the end, so the new page
    // immediately continues the page being edited.
    private func addContinuationPage(photoID: UUID? = nil) {
        guard pages.count < 20 else { return }
        let prior = currentPage
        let created = CollagePage(
            layout: photoID == nil ? prior.layout : .single,
            photoIDs: photoID.map { [$0] } ?? [],
            margin: prior.margin, ratio: prior.ratio,
            proportionalSpacing: prior.proportionalSpacing,
            background: prior.background)
        pages.insert(created, at: pageIndex + 1)
        pageIndex += 1
        output = []
    }

    private func shiftPage(_ delta: Int) {
        let next = pageIndex + delta
        guard pages.indices.contains(next) else { return }
        pages.swapAt(pageIndex, next)
        pageIndex = next
    }
    private func removePage() {
        guard pages.count > 1 else { return }
        pages.remove(at: pageIndex)
        pageIndex = min(pageIndex, pages.count - 1)
        output = []
    }
    private func loadProject() {
        if let data = UserDefaults.standard.data(forKey: projectKey),
           let decoded = try? JSONDecoder().decode([CollagePage].self, from: data),
           !decoded.isEmpty { pages = Array(decoded.prefix(20)); pageIndex = 0 }
    }
    private func saveProject() {
        if let encoded = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(encoded, forKey: projectKey)
        }
    }
    private func exportPages(scope: ExportScope) {
        guard !isWorking else { return }
        let indices = exportIndices(for: scope)
        guard !indices.isEmpty else {
            errorText = "Select at least one page before exporting."
            return
        }
        isWorking = true
        errorText = nil
        output = []
        let subset = indices.map { pages[$0] }
        let pageNumbers = indices.map { $0 + 1 }
        let photos = store.photos
        Task {
            do {
                output = try await Task.detached(priority: .userInitiated) {
                    try CollageRenderer.shared.renderPages(pages: subset,
                                                           photos: photos,
                                                           pageNumbers: pageNumbers)
                }.value
            } catch { errorText = error.localizedDescription }
            isWorking = false
        }
    }
}
