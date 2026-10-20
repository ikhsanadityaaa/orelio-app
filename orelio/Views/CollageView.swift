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
    @State private var isWorking = false
    @State private var output: [URL] = []
    @State private var showShare = false
    @State private var errorText: String?
    private let projectKey = "orelio.collage.pages.v03"

    private var currentPage: CollagePage { pages[pageIndex] }

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
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(pages.indices, id: \.self) { index in
                                Button { pageIndex = index } label: {
                                    VStack(spacing: 5) {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(index == pageIndex ? Color.orange.opacity(0.35) : .white.opacity(0.1))
                                            .frame(width: 60, height: 78)
                                            .overlay(Image(systemName: "square.on.square").foregroundStyle(.white))
                                        Text("Page \(index + 1)").font(.caption2)
                                    }
                                    .padding(4)
                                    .background(index == pageIndex ? .white.opacity(0.09) : .clear, in: RoundedRectangle(cornerRadius: 9))
                                }.buttonStyle(.plain)
                            }
                            Button {
                                guard pages.count < 20 else { return }
                                pages.append(CollagePage(layout: .single))
                                pageIndex = pages.count - 1
                                output = []
                            } label: {
                                VStack(spacing: 5) {
                                    RoundedRectangle(cornerRadius: 7)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                                        .frame(width: 60, height: 78)
                                        .overlay(Image(systemName: "plus"))
                                    Text("Add Page").font(.caption2)
                                }.padding(4)
                            }.buttonStyle(.plain).disabled(pages.count >= 20)
                        }
                    }.scrollIndicators(.hidden)
                    HStack {
                        Text("Page \(pageIndex + 1) of \(pages.count)").font(.headline)
                        Spacer()
                        Button { showLayouts = true } label: { Label("Choose Layout", systemImage: "square.grid.2x2") }
                            .buttonStyle(.bordered)
                    }
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
                        Slider(value: Binding(get: { currentPage.margin }, set: { pages[pageIndex].margin = $0 }), in: 0...0.075)
                        Button(role: .destructive) { removePage() } label: { Image(systemName: "trash") }
                            .disabled(pages.count < 2)
                    }
                    Text("Tap a frame to choose a photo from Library. Layouts and page order can be changed anytime.")
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
                    Button { exportPages() } label: {
                        Label("Export \(pages.count) Page\(pages.count == 1 ? "" : "s")", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(OrelioActionButtonStyle(tone: .primary)).disabled(isWorking || pages.allSatisfy { $0.photoIDs.allSatisfy { $0 == nil } })
                }.padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Collage")
            .sheet(isPresented: $showLayouts) { layoutSheet }
            .sheet(isPresented: $showPhotos) { photoSheet }
            .sheet(isPresented: $showShare) { ActivityShareSheet(files: output) }
            .onAppear { loadProject() }
            .onChange(of: pages) { _, _ in saveProject() }
        }
    }

    private var pageCanvas: some View {
        GeometryReader { geo in
            let bounds = CGSize(width: geo.size.width, height: geo.size.height)
            ZStack(alignment: .topLeading) {
                Color(red: 0.95, green: 0.93, blue: 0.89)
                ForEach(0..<currentPage.layout.slotCount, id: \.self) { i in
                    let rect = currentPage.layout.rects[i].insetBy(dx: currentPage.margin, dy: currentPage.margin)
                    let width = max(1, bounds.width * rect.width)
                    let height = max(1, bounds.height * rect.height)
                    Button {
                        slotIndex = i
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
                    .position(x: bounds.width * rect.midX, y: bounds.height * rect.midY)
                }
            }
        }
        .aspectRatio(4.0 / 5.0, contentMode: .fit)
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
                if !currentPage.photoIDs.isEmpty, currentPage.photoIDs.indices.contains(slotIndex), currentPage.photoIDs[slotIndex] != nil {
                    Button("Clear Frame", role: .destructive) {
                        pages[pageIndex].photoIDs[slotIndex] = nil
                        showPhotos = false
                    }
                }
                ForEach(store.photos) { photo in
                    Button {
                        pages[pageIndex].photoIDs[slotIndex] = photo.id
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
    private func exportPages() {
        guard !isWorking else { return }
        isWorking = true
        errorText = nil
        output = []
        let selectedPages = pages
        let photos = store.photos
        Task {
            do {
                output = try await Task.detached(priority: .userInitiated) {
                    try CollageRenderer.shared.renderPages(pages: selectedPages, photos: photos)
                }.value
            } catch { errorText = error.localizedDescription }
            isWorking = false
        }
    }
}
