import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError("FAILED: \(message)") }
}

let original = EditRecipe()
check(original.look == .original, "default film look")
check(original.lightLayers.isEmpty, "default light layers")
check(FilmLook.allCases.count == 27, "film presets")
check(LightKind.addable.count == 5, "addable light kinds")

var edited = original
edited.look = .amber
edited.exposure = 0.35
edited.grain = 0.65
edited.lightLayers = [LightLayer(kind: .warmSun, x: 0.2, y: 0.4), LightLayer(kind: .anamorphic, rotation: 30)]
let reference = PhotoRecord(originalFilename: "1.jpg", thumbnailFilename: "1-thumb.jpg", recipe: edited)
let encoded = try JSONEncoder().encode(reference)
let decoded = try JSONDecoder().decode(PhotoRecord.self, from: encoded)
check(decoded.recipe == edited, "layers survive JSON encode/decode")
check(decoded.id == reference.id, "identifiers are stable")
check(original.look == .original, "non-destructive value semantics")
print("PASS: layer data and recipe round-trip")

let legacyJSON = """
{"look":"chrome","exposure":0.1,"contrast":1.1,"saturation":1.0,"warmth":0.0,"shadows":0.0,"highlights":0.0,"fade":0.0,"grain":0.0,"vignette":0.0,"lighting":"lightLeak","lightX":0.3,"lightY":0.4,"lightRadius":0.6,"lightIntensity":0.7}
"""
var legacy = try JSONDecoder().decode(EditRecipe.self, from: Data(legacyJSON.utf8))
check(legacy.lightLayers.isEmpty, "old library loads with no new layers")
legacy.migrateLightingIfNeeded()
check(legacy.lightLayers.count == 1 && legacy.lighting == .none, "old lighting migrates")
check(legacy.lightLayers[0].kind == .lightLeak, "legacy kind preserved")
check(abs(legacy.lightLayers[0].x - 0.3) < 0.001, "legacy position preserved")
legacy.migrateLightingIfNeeded()
check(legacy.lightLayers.count == 1, "legacy migration is idempotent")
print("PASS: v0.1 manifest backwards compatibility")

var set = [
    reference,
    PhotoRecord(originalFilename: "2.jpg", thumbnailFilename: "2-thumb.jpg"),
    PhotoRecord(originalFilename: "3.jpg", thumbnailFilename: "3-thumb.jpg")
]
set[1].recipe.warmth = 0.9
set[1].recipe.lightLayers = [LightLayer(kind: .coolGlow)]
let snapshot = set
let count = BatchRecipeOperation.apply(edited, to: &set, ids: [set[1].id],
                                      options: PasteOptions(film: true, tone: false, texture: true, lighting: false))
check(count == 1, "exactly one photo changes")
check(set[1].recipe.look == .amber && set[1].recipe.grain == 0.65, "selected groups changed")
check(set[1].recipe.warmth == 0.9 && set[1].recipe.lightLayers.count == 1, "excluded groups retained")
check(set[0] == snapshot[0] && set[2] == snapshot[2], "unselected photos unchanged")
let ignored = BatchRecipeOperation.apply(edited, to: &set, ids: [set[2].id],
                                         options: PasteOptions(film: false, tone: false, texture: false, lighting: false, border: false))
check(ignored == 0 && set[2] == snapshot[2], "empty paste options are no-op")
let noIDs = BatchRecipeOperation.apply(edited, to: &set, ids: [UUID()])
check(noIDs == 0, "invalid selection no-op")
print("PASS: selective paste, isolation, no-ops")

check(ExportResolution.original.longestSide == nil, "full resolution export")
check(ExportResolution.large.longestSide == 3000, "large export")
check(ExportResolution.social.longestSide == 2048, "social export")
print("PASS: resolution presets")

check(FilmCategory.allCases.count == 3, "three film families; no Vintage or Slide tab")
check(FilmLook.inCategory(.negative).count == 14, "Negative includes Vintage color and former Slide looks")
check(FilmLook.inCategory(.bw).count == 7, "B&W includes monochrome looks formerly in Negative and Vintage")
check(FilmLook.inCategory(.bw).contains(.negCool), "Trix moved to B&W")
check(FilmLook.inCategory(.bw).contains(.vintage1979), "Panchro moved to B&W")
check(FilmLook.inCategory(.negative).contains(.faded), "Vintage color merged into Negative")
check(FilmLook.inCategory(.negative).contains(.slideVivid), "Slide looks merged into Negative")
check(Set(FilmCategory.allCases.flatMap { FilmLook.inCategory($0) }).count == FilmLook.allCases.count - 1,
      "all non-original film looks remain accessible exactly once")
for category in FilmCategory.allCases {
    let looks = FilmLook.inCategory(category)
    let names = looks.map(\.title)
    check(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending },
          "\(category.rawValue) presets sorted A-Z")
}
check(FilmCategory.allCases.map(\.rawValue) == ["Negative", "Instant", "B&W"],
      "exact category order Negative, Instant, B&W")
var improved = EditRecipe()
improved.strength = 0.4
improved.clarity = 0.7
improved.postTint = -0.2
let improvedEncoded = try JSONEncoder().encode(improved)
let restored = try JSONDecoder().decode(EditRecipe.self, from: improvedEncoded)
check(restored == improved, "new adjustments survive encode/decode")
var page = CollagePage(layout: .editorial)
check(page.photoIDs.count == 3, "editorial slots")
page.changeLayout(.mosaic)
check(page.photoIDs.count == 4, "new layout slots")
print("PASS: film catalog, adjustment roundtrip, page layouts")

// v0.5: border settings round-trip and preserve old manifests.
var framed = EditRecipe()
framed.borderEnabled = true
framed.borderPlacement = .outside
framed.borderColor = .black
framed.borderThickness = 0.045
let framedJSON = try JSONEncoder().encode(framed)
let restoredBorder = try JSONDecoder().decode(EditRecipe.self, from: framedJSON)
check(restoredBorder == framed, "border settings survive JSON encode/decode")
let oldBorder = try JSONDecoder().decode(EditRecipe.self, from: Data(legacyJSON.utf8))
check(oldBorder.borderEnabled == false && oldBorder.borderPlacement == .inside,
      "legacy photos have border disabled")
var framedPhotos = [PhotoRecord(originalFilename:"4.jpg", thumbnailFilename:"4-thumb.jpg")]
let applied = BatchRecipeOperation.apply(framed, to: &framedPhotos, ids:[framedPhotos[0].id],
    options: PasteOptions(film:false,tone:false,texture:false,lighting:false,border:true))
check(applied == 1 && framedPhotos[0].recipe.borderPlacement == .outside && framedPhotos[0].recipe.borderColor == .black,
      "paste selected border without other settings")
let before = framedPhotos[0]
let skipped = BatchRecipeOperation.apply(EditRecipe(), to: &framedPhotos, ids:[framedPhotos[0].id],
    options: PasteOptions(film:false,tone:false,texture:false,lighting:false,border:false))
check(skipped == 0 && before == framedPhotos[0], "excluded border not pasted")
check(CompositionGrid.allCases.count == 6 && GridSettings().kind == .off,
      "five guide types plus off, default hidden")
print("PASS: border backward compatibility, selective paste, and grid defaults")
