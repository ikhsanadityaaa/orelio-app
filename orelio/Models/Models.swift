import Foundation

enum AppTab: Hashable {
    case library, editor, collage, export
}

enum FilmCategory: String, CaseIterable, Identifiable {
    case negative = "Negative", instant = "Instant", bw = "B&W"
    var id: String { rawValue }
}

enum FilmLook: String, CaseIterable, Codable, Identifiable {
    // Old raw values stay stable for migration from v0.1 and v0.2.
    case original, amber, chrome, faded, mono, forest
    case negSoft, negPortra, negCool, negMatte
    case slideVivid, slidePastel, slideCool, slideDeep
    case instantWarm, instantSoft, instantPink, instantDust, instantBleach
    case vintageGolden, vintageTeal, vintageMuted, vintage1979
    case monoSoft, monoHigh, monoMatte, monoSilver
    var id: String { rawValue }
    var category: FilmCategory? {
        switch self {
        case .original: nil
        case .amber, .forest, .negSoft, .negPortra, .negMatte, .faded, .vintageGolden, .vintageTeal, .vintageMuted, .chrome, .slideVivid, .slidePastel, .slideCool, .slideDeep: .negative
        case .instantWarm, .instantSoft, .instantPink, .instantDust, .instantBleach: .instant
        case .negCool, .vintage1979, .mono, .monoSoft, .monoHigh, .monoMatte, .monoSilver: .bw
        }
    }
    // Display names inspired by analog film stocks. Preserve the Codable raw cases for saved edits.
    // Looks are approximate originals, not calibrated or affiliated third-party film emulations.
    var title: String {
        switch self {
        case .original: "Original"
        case .amber: "Gold 200"
        case .forest: "Fujia 200"
        case .negSoft: "Porta 400"
        case .negPortra: "Provia 100"
        case .negCool: "Trix 400"
        case .negMatte: "Gold 800"
        case .chrome: "Ektra 100"
        case .slideVivid: "Velvia 100"
        case .slidePastel: "Astia 50"
        case .slideCool: "Provia 200"
        case .slideDeep: "Kodach 64"
        case .instantWarm: "Insta 600"
        case .instantSoft: "Insta 100"
        case .instantPink: "Polax 400"
        case .instantDust: "SX 70"
        case .instantBleach: "Insta 200"
        case .faded: "Gold 400"
        case .vintageGolden: "Kodach 200"
        case .vintageTeal: "Fujia 400"
        case .vintageMuted: "Color 160"
        case .vintage1979: "Panchro 400"
        case .mono: "Trix 320"
        case .monoSoft: "Delta 100"
        case .monoHigh: "HP5 400"
        case .monoMatte: "PanF 50"
        case .monoSilver: "Tmax 800"
        }
    }
    static func inCategory(_ category: FilmCategory) -> [FilmLook] {
        allCases.filter { $0.category == category }.sorted {
            $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
    }
}

enum LightKind: String, CaseIterable, Codable, Identifiable {
    // `none` stays available to decode v0.1 manifests; it is not a layer users can add.
    case none, warmSun, coolGlow, lightLeak, anamorphic, sunRays
    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: "Off"
        case .warmSun: "Golden Glow"
        case .coolGlow: "Blue Hour"
        case .lightLeak: "Film Leak"
        case .anamorphic: "Lens Streak"
        case .sunRays: "Sun Rays"
        }
    }
    static var addable: [LightKind] { allCases.filter { $0 != .none } }
}

/// Each layer can move independently. Coordinates are normalised, top-left origin.
struct LightLayer: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var kind: LightKind = .warmSun
    var x: Double = 0.75
    var y: Double = 0.25
    var radius: Double = 0.40
    var opacity: Double = 0.55
    var rotation: Double = 0 // -180...180 degrees
    var softness: Double = 0.85

    init(id: UUID = UUID(), kind: LightKind = .warmSun,
         x: Double = 0.75, y: Double = 0.25, radius: Double = 0.40,
         opacity: Double = 0.55, rotation: Double = 0, softness: Double = 0.85) {
        self.id = id; self.kind = kind; self.x = x; self.y = y
        self.radius = radius; self.opacity = opacity; self.rotation = rotation
        self.softness = softness
    }
}

// Inside = a stroke over original pixels; outside = a real, enlarged export canvas.
enum BorderPlacement: String, Codable, CaseIterable, Identifiable {
    case inside, outside
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum BorderColor: String, Codable, CaseIterable, Identifiable {
    case white, black
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum CompositionGrid: String, CaseIterable, Identifiable {
    case off, thirds, goldenSpiral, centerMarker, goldenTriangles, square
    var id: String { rawValue }
    var title: String {
        switch self {
        case .off: "Off"
        case .thirds: "Rule of Thirds"
        case .goldenSpiral: "Fibonacci Spiral"
        case .centerMarker: "Center Marker"
        case .goldenTriangles: "Golden Triangles"
        case .square: "Square Grid"
        }
    }
}

/// The grid belongs to editor display settings, NEVER to the export recipe.
struct GridSettings: Equatable {
    var kind: CompositionGrid = .off
    var quarterTurns: Int = 0
    var mirrored: Bool = false
    var darkLines: Bool = false
    var opacity: Double = 0.72
}

/// A non-destructive, backwards-compatible edit recipe. Originals never change.
struct EditRecipe: Codable, Equatable {
    var look: FilmLook = .original
    var strength: Double = 1
    var clarity: Double = 0
    var sharpen: Double = 0
    var preWarmth: Double = 0
    var postWarmth: Double = 0
    var preTint: Double = 0
    var postTint: Double = 0
    var grainSize: Double = 0.5
    var dust: Double = 0
    var dateStamp: Bool = false
    var dateStampText: String = ""
    var vintageLens: Double = 0
    var borderEnabled: Bool = false
    var borderPlacement: BorderPlacement = .inside
    var borderColor: BorderColor = .white
    // Fraction of the original image's shortest dimension, 0.002...0.08.
    var borderThickness: Double = 0.015
    var exposure: Double = 0
    var contrast: Double = 1
    var saturation: Double = 1
    var warmth: Double = 0
    var shadows: Double = 0
    var highlights: Double = 0
    var fade: Double = 0
    var grain: Double = 0
    var vignette: Double = 0

    // Legacy v0.1 fields are retained so existing library manifests still decode.
    var lighting: LightKind = .none
    var lightX: Double = 0.75
    var lightY: Double = 0.22
    var lightRadius: Double = 0.42
    var lightIntensity: Double = 0.55
    var lightLayers: [LightLayer] = []

    init() {}

    /// The v0.1 Codable payload lacks `lightLayers`; synthesised decoding would throw.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        look = try c.decodeIfPresent(FilmLook.self, forKey: .look) ?? .original
        strength = try c.decodeIfPresent(Double.self, forKey: .strength) ?? 1
        clarity = try c.decodeIfPresent(Double.self, forKey: .clarity) ?? 0
        sharpen = try c.decodeIfPresent(Double.self, forKey: .sharpen) ?? 0
        preWarmth = try c.decodeIfPresent(Double.self, forKey: .preWarmth) ?? 0
        postWarmth = try c.decodeIfPresent(Double.self, forKey: .postWarmth) ?? 0
        preTint = try c.decodeIfPresent(Double.self, forKey: .preTint) ?? 0
        postTint = try c.decodeIfPresent(Double.self, forKey: .postTint) ?? 0
        grainSize = try c.decodeIfPresent(Double.self, forKey: .grainSize) ?? 0.5
        dust = try c.decodeIfPresent(Double.self, forKey: .dust) ?? 0
        dateStamp = try c.decodeIfPresent(Bool.self, forKey: .dateStamp) ?? false
        dateStampText = try c.decodeIfPresent(String.self, forKey: .dateStampText) ?? ""
        vintageLens = try c.decodeIfPresent(Double.self, forKey: .vintageLens) ?? 0
        borderEnabled = try c.decodeIfPresent(Bool.self, forKey: .borderEnabled) ?? false
        borderPlacement = try c.decodeIfPresent(BorderPlacement.self, forKey: .borderPlacement) ?? .inside
        borderColor = try c.decodeIfPresent(BorderColor.self, forKey: .borderColor) ?? .white
        borderThickness = try c.decodeIfPresent(Double.self, forKey: .borderThickness) ?? 0.015
        exposure = try c.decodeIfPresent(Double.self, forKey: .exposure) ?? 0
        contrast = try c.decodeIfPresent(Double.self, forKey: .contrast) ?? 1
        saturation = try c.decodeIfPresent(Double.self, forKey: .saturation) ?? 1
        warmth = try c.decodeIfPresent(Double.self, forKey: .warmth) ?? 0
        shadows = try c.decodeIfPresent(Double.self, forKey: .shadows) ?? 0
        highlights = try c.decodeIfPresent(Double.self, forKey: .highlights) ?? 0
        fade = try c.decodeIfPresent(Double.self, forKey: .fade) ?? 0
        grain = try c.decodeIfPresent(Double.self, forKey: .grain) ?? 0
        vignette = try c.decodeIfPresent(Double.self, forKey: .vignette) ?? 0
        lighting = try c.decodeIfPresent(LightKind.self, forKey: .lighting) ?? .none
        lightX = try c.decodeIfPresent(Double.self, forKey: .lightX) ?? 0.75
        lightY = try c.decodeIfPresent(Double.self, forKey: .lightY) ?? 0.22
        lightRadius = try c.decodeIfPresent(Double.self, forKey: .lightRadius) ?? 0.42
        lightIntensity = try c.decodeIfPresent(Double.self, forKey: .lightIntensity) ?? 0.55
        lightLayers = try c.decodeIfPresent([LightLayer].self, forKey: .lightLayers) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case look, strength, clarity, sharpen, preWarmth, postWarmth, preTint, postTint, grainSize, dust, vintageLens, dateStamp, dateStampText
        case exposure, contrast, saturation, warmth, shadows, highlights
        case fade, grain, vignette, lighting, lightX, lightY, lightRadius
        case lightIntensity, lightLayers, borderEnabled, borderPlacement, borderColor, borderThickness
    }

    /// Legacy lighting is lifted into the new layer editor when first opened.
    mutating func migrateLightingIfNeeded() {
        guard lightLayers.isEmpty, lighting != .none else { return }
        lightLayers = [LightLayer(kind: lighting, x: lightX, y: lightY,
                                 radius: lightRadius, opacity: lightIntensity)]
        lighting = .none
    }
}

struct PasteOptions: Equatable {
    var film = true
    var tone = true
    var texture = true
    var lighting = true
    var border = true
    static let all = PasteOptions()
    var hasAny: Bool { film || tone || texture || lighting || border }
}

struct PhotoRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let originalFilename: String
    let thumbnailFilename: String
    let importedAt: Date
    var recipe: EditRecipe

    init(id: UUID = UUID(), originalFilename: String, thumbnailFilename: String,
         importedAt: Date = Date(), recipe: EditRecipe = EditRecipe()) {
        self.id = id
        self.originalFilename = originalFilename
        self.thumbnailFilename = thumbnailFilename
        self.importedAt = importedAt
        self.recipe = recipe
    }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case jpeg, png, heic
    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
    var fileExtension: String { self == .jpeg ? "jpg" : rawValue }
}

enum ExportResolution: String, CaseIterable, Identifiable {
    case original, large, social
    var id: String { rawValue }
    var title: String {
        switch self {
        case .original: "Original"
        case .large: "3000 px"
        case .social: "2048 px"
        }
    }
    var longestSide: Int? {
        switch self {
        case .original: nil
        case .large: 3000
        case .social: 2048
        }
    }
}

enum CollageStyle: String, CaseIterable, Identifiable {
    case grid, story, seamless
    var id: String { rawValue }
    var title: String {
        switch self {
        case .grid: "Grid"
        case .story: "Story"
        case .seamless: "Carousel"
        }
    }
}

// Layout templates are original to orelio. All coordinates are normalized and deterministic.
enum CollageLayout: String, CaseIterable, Codable, Identifiable {
    case single, splitVertical, splitHorizontal, triptych, editorial, mosaic
    var id: String { rawValue }
    var title: String {
        switch self {
        case .single: "Full Bleed"
        case .splitVertical: "Split V"
        case .splitHorizontal: "Split H"
        case .triptych: "Triptych"
        case .editorial: "Editorial"
        case .mosaic: "Mosaic"
        }
    }
    var rects: [CGRect] {
        switch self {
        case .single: [CGRect(x: 0, y: 0, width: 1, height: 1)]
        case .splitVertical: [CGRect(x: 0, y: 0, width: 0.5, height: 1), CGRect(x: 0.5, y: 0, width: 0.5, height: 1)]
        case .splitHorizontal: [CGRect(x: 0, y: 0, width: 1, height: 0.5), CGRect(x: 0, y: 0.5, width: 1, height: 0.5)]
        case .triptych: [CGRect(x: 0, y: 0, width: 1, height: 0.6), CGRect(x: 0, y: 0.6, width: 0.5, height: 0.4), CGRect(x: 0.5, y: 0.6, width: 0.5, height: 0.4)]
        case .editorial: [CGRect(x: 0, y: 0, width: 0.67, height: 1), CGRect(x: 0.67, y: 0, width: 0.33, height: 0.5), CGRect(x: 0.67, y: 0.5, width: 0.33, height: 0.5)]
        case .mosaic: [CGRect(x: 0, y: 0, width: 0.5, height: 0.5), CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5), CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5), CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)]
        }
    }
    var slotCount: Int {
        switch self {
        case .single: 1
        case .splitVertical, .splitHorizontal: 2
        case .triptych, .editorial: 3
        case .mosaic: 4
        }
    }
}

enum CollageAspectRatio: String, Codable, CaseIterable, Identifiable {
    case portrait = "4:5", square = "1:1", story = "9:16",
         classic = "3:2", wide = "16:9"
    var id: String { rawValue }
    var ratio: CGFloat {
        switch self {
        case .portrait: 4.0 / 5.0
        case .square: 1
        case .story: 9.0 / 16.0
        case .classic: 3.0 / 2.0
        case .wide: 16.0 / 9.0
        }
    }
}

struct CollagePage: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var layout: CollageLayout = .single
    var photoIDs: [UUID?] = [nil]
    // Fraction of shortest side; all borders are consistent in physical pixel units.
    var margin: Double = 0.035
    var ratio: CollageAspectRatio = .portrait
    var proportionalSpacing: Bool = false

    init(id: UUID = UUID(), layout: CollageLayout = .single, photoIDs: [UUID?] = [],
         margin: Double = 0.035, ratio: CollageAspectRatio = .portrait,
         proportionalSpacing: Bool = false) {
        self.id = id
        self.layout = layout
        self.photoIDs = Array((photoIDs + Array(repeating: nil, count: layout.slotCount)).prefix(layout.slotCount))
        self.margin = margin
        self.ratio = ratio
        self.proportionalSpacing = proportionalSpacing
    }

    // Older v0.3 collage projects do not have the new global page settings.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        layout = try c.decodeIfPresent(CollageLayout.self, forKey: .layout) ?? .single
        let saved = try c.decodeIfPresent([UUID?].self, forKey: .photoIDs) ?? []
        photoIDs = Array((saved + Array(repeating: nil, count: layout.slotCount)).prefix(layout.slotCount))
        margin = try c.decodeIfPresent(Double.self, forKey: .margin) ?? 0.035
        ratio = try c.decodeIfPresent(CollageAspectRatio.self, forKey: .ratio) ?? .portrait
        proportionalSpacing = try c.decodeIfPresent(Bool.self, forKey: .proportionalSpacing) ?? false
    }

    mutating func changeLayout(_ value: CollageLayout) {
        layout = value
        photoIDs = Array((photoIDs + Array(repeating: nil, count: value.slotCount)).prefix(value.slotCount))
    }

    // Shared by native canvas and JPEG exporter: internal seams count HALF the
    // inset from EACH image, exterior edges count one full inset.
    func slotRect(_ index: Int, canvasSize: CGSize) -> CGRect {
        let area = layout.rects[index]
        let w = canvasSize.width, h = canvasSize.height
        let gap = CGFloat(max(0, margin)) * min(w, h)
        let left = gap * (proportionalSpacing && area.minX > 0.00001 ? 0.5 : 1)
        let right = gap * (proportionalSpacing && area.maxX < 0.99999 ? 0.5 : 1)
        let top = gap * (proportionalSpacing && area.minY > 0.00001 ? 0.5 : 1)
        let bottom = gap * (proportionalSpacing && area.maxY < 0.99999 ? 0.5 : 1)
        return CGRect(x: area.minX * w + left, y: area.minY * h + top,
                      width: max(1, area.width * w - left - right),
                      height: max(1, area.height * h - top - bottom))
    }
}
