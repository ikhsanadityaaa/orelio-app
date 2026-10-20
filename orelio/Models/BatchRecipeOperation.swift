import Foundation

/// Pure, testable selective paste. Never mutates originals or unselected photos.
enum BatchRecipeOperation {
    @discardableResult
    static func apply(_ recipe: EditRecipe, to photos: inout [PhotoRecord],
                      ids: Set<UUID>, options: PasteOptions = .all) -> Int {
        guard options.hasAny else { return 0 }
        var changed = 0
        for index in photos.indices where ids.contains(photos[index].id) {
            var target = photos[index].recipe
            if options.film { target.look = recipe.look; target.strength = recipe.strength }
            if options.tone {
                target.exposure = recipe.exposure
                target.contrast = recipe.contrast
                target.saturation = recipe.saturation
                target.warmth = recipe.warmth
                target.shadows = recipe.shadows
                target.highlights = recipe.highlights
                target.clarity = recipe.clarity
                target.sharpen = recipe.sharpen
                target.preWarmth = recipe.preWarmth
                target.postWarmth = recipe.postWarmth
                target.preTint = recipe.preTint
                target.postTint = recipe.postTint
            }
            if options.texture {
                target.fade = recipe.fade
                target.grain = recipe.grain
                target.vignette = recipe.vignette
                target.grainSize = recipe.grainSize
                target.dust = recipe.dust
                target.dateStamp = recipe.dateStamp
                target.dateStampText = recipe.dateStampText
                target.vintageLens = recipe.vintageLens
            }
            if options.lighting {
                target.lighting = recipe.lighting
                target.lightX = recipe.lightX
                target.lightY = recipe.lightY
                target.lightRadius = recipe.lightRadius
                target.lightIntensity = recipe.lightIntensity
                target.lightLayers = recipe.lightLayers
            }
            if options.border {
                target.borderEnabled = recipe.borderEnabled
                target.borderPlacement = recipe.borderPlacement
                target.borderColor = recipe.borderColor
                target.borderThickness = recipe.borderThickness
            }
            if target != photos[index].recipe {
                photos[index].recipe = target
                changed += 1
            }
        }
        return changed
    }
}
