import SwiftUI
import UIKit

// Film and tools are intentionally separate, as on a dedicated analog editor.
/// Small vector icon of a 35mm film canister with a short perforated film leader.
/// Drawn locally so the Film menu never falls back to a clapperboard/film-strip SF Symbol.
private struct FilmCanisterIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(.primary.opacity(0.12))
                .overlay { RoundedRectangle(cornerRadius: 2.5).strokeBorder(lineWidth: 1.5) }
                .frame(width: 12, height: 17)
                .offset(x: -3, y: 2.5)
            RoundedRectangle(cornerRadius: 1.0)
                .fill(.primary.opacity(0.85))
                .frame(width: 7.5, height: 3)
                .offset(x: -3, y: -8)
            Capsule().fill(.primary.opacity(0.7))
                .frame(width: 11, height: 1.4)
                .offset(x: -3, y: -2.5)
            Capsule().fill(.primary.opacity(0.7))
                .frame(width: 11, height: 1.4)
                .offset(x: -3, y: 8.5)
            RoundedRectangle(cornerRadius: 0.9)
                .fill(.primary.opacity(0.22))
                .frame(width: 8, height: 5.5)
                .offset(x: -3, y: 2.5)
            Path { path in
                path.move(to: CGPoint(x: 15, y: 7))
                path.addQuadCurve(to: CGPoint(x: 21, y: 12),
                                  control: CGPoint(x: 21, y: 6))
                path.addLine(to: CGPoint(x: 21, y: 21))
            }
            .stroke(.primary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .frame(width: 24, height: 24)
            VStack(spacing: 2.6) {
                Capsule().fill(.primary).frame(width: 3, height: 1.1)
                Capsule().fill(.primary).frame(width: 3, height: 1.1)
                Capsule().fill(.primary).frame(width: 3, height: 1.1)
            }
            .offset(x: 9, y: 3.5)
        }
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}

private enum EditorPanel: String, CaseIterable, Identifiable {
    case film = "Film", tools = "Tools", lighting = "Lighting", composition = "Composition", border = "Border"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .film: "film" // custom 35mm canister is rendered below
        case .tools: "slider.horizontal.3"
        case .lighting: "sun.max"
        case .composition: "crop.rotate"
        case .border: "square.dashed"
        }
    }
}

private enum EditorTool: String, CaseIterable, Identifiable {
    case exposure, contrast, highlights, shadows, clarity, saturation, warmth
    case preWarmth, postWarmth, preTint, postTint
    case sharpen, grain, grainSize, vignette, fade, vintageLens, dust, dateStamp

    var id: String { rawValue }
    var title: String {
        switch self {
        case .exposure: "Exposure"
        case .contrast: "Contrast"
        case .highlights: "Highlights"
        case .shadows: "Shadows"
        case .clarity: "Clarity"
        case .saturation: "Saturation"
        case .warmth: "Warmth"
        case .preWarmth: "Pre Warmth"
        case .postWarmth: "Post Warmth"
        case .preTint: "Pre Tint"
        case .postTint: "Post Tint"
        case .sharpen: "Sharpen"
        case .grain: "Grain"
        case .grainSize: "Grain Size"
        case .vignette: "Vignette"
        case .fade: "Fade"
        case .vintageLens: "Vintage Lens"
        case .dust: "Dust"
        case .dateStamp: "Date Stamp"
        }
    }
    var icon: String {
        switch self {
        case .exposure: "sun.max"
        case .contrast: "circle.lefthalf.filled"
        case .highlights: "sun.max.fill"
        case .shadows: "moon.fill"
        case .clarity: "circle.hexagongrid"
        case .saturation: "drop.fill"
        case .warmth, .preWarmth, .postWarmth: "thermometer.medium"
        case .preTint, .postTint: "eyedropper.halffull"
        case .sharpen: "triangle"
        case .grain: "circle.dotted"
        case .grainSize: "circle.grid.3x3"
        case .vignette: "circle.dashed.inset.filled"
        case .fade: "circle.bottomhalf.filled"
        case .vintageLens: "camera.filters"
        case .dust: "sparkles"
        case .dateStamp: "calendar"
        }
    }
    var keyPath: WritableKeyPath<EditRecipe, Double>? {
        switch self {
        case .exposure: \.exposure
        case .contrast: \.contrast
        case .highlights: \.highlights
        case .shadows: \.shadows
        case .clarity: \.clarity
        case .saturation: \.saturation
        case .warmth: \.warmth
        case .preWarmth: \.preWarmth
        case .postWarmth: \.postWarmth
        case .preTint: \.preTint
        case .postTint: \.postTint
        case .sharpen: \.sharpen
        case .grain: \.grain
        case .grainSize: \.grainSize
        case .vignette: \.vignette
        case .fade: \.fade
        case .vintageLens: \.vintageLens
        case .dust: \.dust
        case .dateStamp: nil
        }
    }
    var limits: ClosedRange<Double> {
        switch self {
        case .exposure, .warmth, .preWarmth, .postWarmth, .preTint, .postTint: -1...1
        case .contrast, .saturation: 0.4...1.8
        case .grainSize: 0.2...1
        default: 0...1
        }
    }
    var neutral: Double {
        switch self {
        case .contrast, .saturation: 1
        case .grainSize: 0.5
        default: 0
        }
    }
}

struct EditorView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var panel: EditorPanel = .film
    @State private var selectedTool: EditorTool = .exposure
    @State private var filmCategory: FilmCategory = .negative
    @State private var showReset = false
    @State private var showCopyConfirmation = false
    @State private var selectedLightID: UUID?
    // Editor-only composition guides: persisted locally, never in photo recipes.
    @AppStorage("orelio.grid.kind") private var gridKindRaw: String = "off"
    @AppStorage("orelio.grid.turns") private var gridTurns: Int = 0
    @AppStorage("orelio.grid.mirrored") private var gridMirror: Bool = false
    @AppStorage("orelio.grid.dark") private var gridDark: Bool = false
    @AppStorage("orelio.grid.opacity") private var gridOpacity: Double = 0.72
    private var gridSettings: GridSettings {
        GridSettings(kind: CompositionGrid(rawValue: gridKindRaw) ?? .off,
                     quarterTurns: gridTurns, mirrored: gridMirror,
                     darkLines: gridDark, opacity: gridOpacity)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let record = store.activePhoto {
                    VStack(spacing: 0) {
                        ZStack {
                            Color.black
                            RenderedPhoto(record: record,
                                activeLight: panel == .lighting ? selectedLayer(in: record.recipe) : nil,
                                onLightMove: panel == .lighting ? { x, y in moveSelectedLight(x: x, y: y) } : nil,
                                grid: gridSettings)
                                .padding(10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("film-preview")

                        HStack(spacing: 0) {
                            ForEach(EditorPanel.allCases) { mode in
                                Button {
                                    panel = mode
                                    if mode == .lighting, let id = store.activeID {
                                        store.updateRecipe(for: id) { $0.migrateLightingIfNeeded() }
                                    }
                                } label: {
                                    VStack(spacing: 5) {
                                        if mode == .film {
                                            FilmCanisterIcon()
                                        } else {
                                            Image(systemName: mode.symbol)
                                                .font(.system(size: 18, weight: panel == mode ? .semibold : .regular))
                                        }
                                        Text(mode.rawValue)
                                            .font(.system(size: 10, weight: panel == mode ? .semibold : .medium, design: .rounded))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .foregroundStyle(panel == mode ? Color(red: 0.87, green: 0.62, blue: 0.45) : .secondary)
                                    .frame(maxWidth: .infinity, minHeight: 55)
                                    .background(panel == mode ? Color.orange.opacity(0.11) : .clear,
                                                in: RoundedRectangle(cornerRadius: 11))
                                    .overlay(alignment: .bottom) {
                                        if panel == mode { Capsule().fill(Color.orange.opacity(0.9)).frame(width: 25, height: 2) }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 8)
                        .background(Color(.secondarySystemBackground))
                        .onChange(of: store.activeID) { _, _ in selectedLightID = nil }

                        Group {
                            switch panel {
                            case .film: filmPanel
                            case .tools: toolPanel
                            case .lighting: lightingPanel
                            case .composition: gridPanel
                            case .border: borderPanel
                            }
                        }
                        .frame(height: panel == .lighting || panel == .composition || panel == .border ? 251 : 225)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Button { store.copyRecipe(from: record.id); showCopyConfirmation = true } label: {
                                Image(systemName: "doc.on.doc")
                            }.accessibilityLabel("Copy edits")
                            Button { showReset = true } label: {
                                Image(systemName: "arrow.counterclockwise")
                            }.accessibilityLabel("Reset edits")
                        }
                    }
                    .confirmationDialog("Reset all edits?", isPresented: $showReset) {
                        Button("Reset", role: .destructive) { store.resetRecipe(for: record.id) }
                    }
                    .alert("Edits Copied", isPresented: $showCopyConfirmation) {
                        Button("Select Photos") { store.selectionMode = true; store.currentTab = .library }
                        Button("OK", role: .cancel) {}
                    } message: { Text("Open Library, select multiple photos, then tap Paste Edits.") }
                } else {
                    EmptyPrompt(symbol: "slider.horizontal.3", title: "Choose a photo", subtitle: "Tap an image in your Library to edit it.")
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func setting(_ path: WritableKeyPath<EditRecipe, Double>, fallback: Double) -> Binding<Double> {
        Binding(
            get: { store.activePhoto?.recipe[keyPath: path] ?? fallback },
            set: { newValue in
                guard let id = store.activeID else { return }
                store.updateRecipe(for: id) { $0[keyPath: path] = newValue }
            }
        )
    }

    private var filmPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(FilmCategory.allCases) { category in
                        Button(category.rawValue.uppercased()) { filmCategory = category }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(filmCategory == category ? .primary : .secondary)
                            .overlay(alignment: .bottom) {
                                if category == filmCategory {
                                    Rectangle().fill(Color.orange).frame(height: 2).offset(y: 6)
                                }
                            }
                    }
                }.padding(.horizontal, 16).padding(.vertical, 7)
            }.scrollIndicators(.hidden)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 9) {
                    filmButton(.original)
                    ForEach(FilmLook.inCategory(filmCategory)) { look in filmButton(look) }
                }.padding(.horizontal, 16)
            }.scrollIndicators(.hidden)

            if store.activeID != nil {
                AdjustmentSlider(title: "Film Strength", value: setting(\.strength, fallback: 1), limits: 0...1)
                    .padding(.horizontal, 16)
            }
        }.padding(.top, 9)
    }

    private func filmButton(_ look: FilmLook) -> some View {
        let selected = store.activePhoto?.recipe.look == look
        return Button {
            guard let id = store.activeID else { return }
            store.updateRecipe(for: id) { $0.look = look }
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    FilmCanisterIcon().scaleEffect(0.75).frame(width: 19, height: 19)
                    Spacer(minLength: 0)
                }
                .frame(width: 80, height: 19)
                .accessibilityHidden(true)
                Group {
                    if let photo = store.activePhoto,
                       let thumbnail = UIImage(contentsOfFile: AppFolders.thumbnail(photo).path) {
                        Image(uiImage: thumbnail)
                            .resizable().scaledToFill()
                            .saturation(look.category == .bw ? 0 : look.category == .vintage ? 0.7 : 0.9)
                            .overlay(look.category == .instant ? Color.orange.opacity(0.12) : Color.clear)
                    } else { Rectangle().fill(.gray.opacity(0.2)) }
                }
                .frame(width: 80, height: 82).clipped()
                .overlay(alignment: .bottom) {
                    if selected { Rectangle().fill(Color.orange).frame(height: 3) }
                }
                Text(look.title).font(.system(size: 10)).lineLimit(1)
                    .foregroundStyle(selected ? .primary : .secondary)
            }.frame(width: 82)
        }.buttonStyle(.plain)
    }

    private var toolPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let keyPath = selectedTool.keyPath {
                AdjustmentSlider(title: selectedTool.title,
                                 value: setting(keyPath, fallback: selectedTool.neutral), limits: selectedTool.limits)
                    .padding(.horizontal, 16)
                    .padding(.top, 19)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Toggle("Date Stamp", isOn: Binding(
                        get: { store.activePhoto?.recipe.dateStamp ?? false },
                        set: { newValue in
                            guard let id = store.activeID else { return }
                            store.updateRecipe(for: id) { $0.dateStamp = newValue }
                        }))
                    TextField("Caption (optional)", text: Binding(
                        get: { store.activePhoto?.recipe.dateStampText ?? "" },
                        set: { text in
                            guard let id = store.activeID else { return }
                            store.updateRecipe(for: id) { $0.dateStampText = String(text.prefix(30)) }
                        }))
                        .textFieldStyle(.roundedBorder)
                }.padding(.horizontal, 16).padding(.top, 9)
            }
            Spacer(minLength: 0)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 4) {
                    ForEach(EditorTool.allCases) { tool in
                        Button { selectedTool = tool } label: {
                            VStack(spacing: 9) {
                                Image(systemName: tool.icon).font(.system(size: 20))
                                Text(tool.title).font(.system(size: 10)).lineLimit(1)
                            }
                            .foregroundStyle(selectedTool == tool ? .primary : .secondary)
                            .frame(width: 80, height: 76)
                            .background(selectedTool == tool ? Color.orange.opacity(0.15) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 9))
                            .overlay(alignment: .bottom) {
                                if selectedTool == tool { Rectangle().fill(Color.orange).frame(height: 2) }
                            }
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal, 10)
            }
            .scrollIndicators(.hidden)
        }.padding(.bottom, 12)
    }

    private func selectedLayer(in recipe: EditRecipe) -> LightLayer? {
        recipe.lightLayers.first(where: { $0.id == selectedLightID }) ?? recipe.lightLayers.last
    }
    private func moveSelectedLight(x: Double, y: Double) {
        guard let photo = store.activePhoto, let layer = selectedLayer(in: photo.recipe) else { return }
        store.updateRecipe(for: photo.id) { recipe in
            guard let index = recipe.lightLayers.firstIndex(where: { $0.id == layer.id }) else { return }
            recipe.lightLayers[index].x = min(1, max(0, x))
            recipe.lightLayers[index].y = min(1, max(0, y))
        }
    }
    private func layerSetting(_ path: WritableKeyPath<LightLayer, Double>, fallback: Double) -> Binding<Double> {
        Binding(
            get: { store.activePhoto.flatMap { selectedLayer(in: $0.recipe) }?[keyPath: path] ?? fallback },
            set: { value in
                guard let photo = store.activePhoto, let layer = selectedLayer(in: photo.recipe) else { return }
                store.updateRecipe(for: photo.id) { recipe in
                    if let index = recipe.lightLayers.firstIndex(where: { $0.id == layer.id }) {
                        recipe.lightLayers[index][keyPath: path] = value
                    }
                }
            }
        )
    }
    private func addLight(_ kind: LightKind) {
        guard let id = store.activeID else { return }
        let layer = LightLayer(kind: kind)
        store.updateRecipe(for: id) { recipe in
            recipe.migrateLightingIfNeeded()
            guard recipe.lightLayers.count < 8 else { return }
            recipe.lightLayers.append(layer)
        }
        selectedLightID = layer.id
    }
    private func removeLight(_ id: UUID) {
        guard let photoID = store.activeID else { return }
        store.updateRecipe(for: photoID) { $0.lightLayers.removeAll { $0.id == id } }
        selectedLightID = nil
    }

    private func borderEnabledBinding() -> Binding<Bool> {
        Binding(get: { store.activePhoto?.recipe.borderEnabled ?? false },
                set: { newValue in
                    guard let id = store.activeID else { return }
                    store.updateRecipe(for: id) { $0.borderEnabled = newValue }
                })
    }

    private func borderPlacementBinding() -> Binding<BorderPlacement> {
        Binding(get: { store.activePhoto?.recipe.borderPlacement ?? .inside },
                set: { value in
                    guard let id = store.activeID else { return }
                    store.updateRecipe(for: id) { $0.borderPlacement = value }
                })
    }

    private func borderColorBinding() -> Binding<BorderColor> {
        Binding(get: { store.activePhoto?.recipe.borderColor ?? .white },
                set: { value in
                    guard let id = store.activeID else { return }
                    store.updateRecipe(for: id) { $0.borderColor = value }
                })
    }

    private var borderPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Outline / Border", isOn: borderEnabledBinding())
                    .font(.subheadline.weight(.medium))
                Picker("Placement", selection: borderPlacementBinding()) {
                    ForEach(BorderPlacement.allCases) { place in
                        Text(place.title).tag(place)
                    }
                }.pickerStyle(.segmented)
                HStack(spacing: 12) {
                    Text("Color").font(.subheadline)
                    Spacer()
                    ForEach(BorderColor.allCases) { shade in
                        Button {
                            borderColorBinding().wrappedValue = shade
                        } label: {
                            HStack(spacing: 5) {
                                Circle().fill(shade == .white ? .white : .black)
                                    .frame(width: 19, height: 19)
                                    .overlay(Circle().strokeBorder(Color.gray, lineWidth: 1))
                                Text(shade.title).font(.caption)
                            }
                            .padding(8)
                            .background(borderColorBinding().wrappedValue == shade ? Color.orange.opacity(0.17) : Color.gray.opacity(0.10),
                                        in: RoundedRectangle(cornerRadius: 8))
                        }.buttonStyle(.plain)
                    }
                }
                VStack(spacing: 5) {
                    HStack {
                        Text("Thickness").font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f%%", (store.activePhoto?.recipe.borderThickness ?? 0.015) * 100))
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    Slider(value: setting(\.borderThickness, fallback: 0.015), in: 0.002...0.08)
                        .tint(Color(red: 0.773, green: 0.482, blue: 0.337))
                }
                Text("Outside adds real pixels to the export. Inside keeps the original image dimensions.")
                    .font(.caption2).foregroundStyle(.secondary)
            }.padding(16)
        }
    }

    private var gridPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Composition Guides", systemImage: "viewfinder").font(.subheadline.weight(.medium))
                    Spacer()
                    Picker("Type", selection: $gridKindRaw) {
                        ForEach(CompositionGrid.allCases) { kind in Text(kind.title).tag(kind.rawValue) }
                    }.pickerStyle(.menu)
                }
                if gridKindRaw != CompositionGrid.off.rawValue {
                    if gridKindRaw == CompositionGrid.goldenSpiral.rawValue {
                        HStack(spacing: 12) {
                            Button { gridTurns = (gridTurns + 3) % 4 } label: {
                                Label("Rotate Left", systemImage: "rotate.left")
                            }
                            Button { gridTurns = (gridTurns + 1) % 4 } label: {
                                Label("Rotate Right", systemImage: "rotate.right")
                            }
                            Spacer()
                            Text("\(gridTurns * 90)°").monospacedDigit()
                        }.font(.caption).buttonStyle(.bordered)
                        Toggle("Mirror spiral", isOn: $gridMirror).font(.caption)
                    }
                    Toggle("Black guide lines", isOn: $gridDark).font(.caption)
                    AdjustmentSlider(title: "Guide opacity", value: $gridOpacity, limits: 0.15...1)
                }
                Text("Guides are visible only while editing. They never appear in exported photos.")
                    .font(.caption2).foregroundStyle(.secondary)
            }.padding(16)
        }
    }

    private var lightingPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text("LIGHTING LAYERS").font(.caption.weight(.semibold)).tracking(1)
                    Spacer()
                    Menu {
                        ForEach(LightKind.addable) { kind in Button(kind.title) { addLight(kind) } }
                    } label: { Label("Add Light", systemImage: "plus.circle") }
                        .disabled((store.activePhoto?.recipe.lightLayers.count ?? 0) >= 8)
                }
                if let layers = store.activePhoto?.recipe.lightLayers {
                    ScrollView(.horizontal) {
                        HStack(spacing: 7) {
                            ForEach(layers) { layer in
                                Button { selectedLightID = layer.id } label: {
                                    Text(layer.kind.title)
                                        .font(.caption2)
                                        .padding(9)
                                        .background(selectedLayer(in: store.activePhoto?.recipe ?? EditRecipe())?.id == layer.id ? Color.orange.opacity(0.2) : Color.gray.opacity(0.15), in: Capsule())
                                }
                            }
                        }
                    }.scrollIndicators(.hidden)
                }
                if let layer = store.activePhoto.flatMap({ selectedLayer(in: $0.recipe) }) {
                    HStack {
                        Text(layer.kind.title).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button(role: .destructive) { removeLight(layer.id) } label: { Label("Remove", systemImage: "trash") }
                            .font(.caption2)
                    }
                    AdjustmentSlider(title: "Strength", value: layerSetting(\.opacity, fallback: 0.55), limits: 0...1)
                    AdjustmentSlider(title: "Size", value: layerSetting(\.radius, fallback: 0.4), limits: 0.08...1.4)
                    AdjustmentSlider(title: "Softness", value: layerSetting(\.softness, fallback: 0.85), limits: 0...1)
                    if layer.kind == .lightLeak || layer.kind == .anamorphic || layer.kind == .sunRays {
                        AdjustmentSlider(title: "Angle", value: layerSetting(\.rotation, fallback: 0), limits: -180...180)
                    }
                    Text("Drag on the image to position the light. Everything outside the photo stays black.")
                        .font(.caption2).foregroundStyle(.secondary)
                } else {
                    Text("Tap Add Light to place an effect on this photo.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.padding(16)
        }
    }
}
