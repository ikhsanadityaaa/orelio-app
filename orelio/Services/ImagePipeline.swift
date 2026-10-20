import Foundation
import UIKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers

private struct FilmGrade {
    var contrast: Double
    var saturation: Double
    var warmth: Double
    var brightness: Double
    var mono: Bool
}

private extension FilmLook {
    var grade: FilmGrade {
        // All grades are orelio originals, NOT preset coefficients extracted from RNI.
        switch self {
        case .original: FilmGrade(contrast: 1, saturation: 1, warmth: 0, brightness: 0, mono: false)
        case .amber: FilmGrade(contrast: 1.12, saturation: 0.89, warmth: 0.42, brightness: 0.015, mono: false)
        case .forest: FilmGrade(contrast: 1.08, saturation: 0.92, warmth: -0.18, brightness: -0.018, mono: false)
        case .negSoft: FilmGrade(contrast: 0.89, saturation: 0.93, warmth: 0.04, brightness: 0.035, mono: false)
        case .negPortra: FilmGrade(contrast: 1.03, saturation: 0.83, warmth: 0.18, brightness: 0.015, mono: false)
        case .negCool: FilmGrade(contrast: 0.98, saturation: 0.83, warmth: -0.30, brightness: 0, mono: false)
        case .negMatte: FilmGrade(contrast: 0.85, saturation: 0.70, warmth: 0.08, brightness: 0.045, mono: false)
        case .chrome: FilmGrade(contrast: 0.96, saturation: 0.83, warmth: -0.16, brightness: 0.025, mono: false)
        case .slideVivid: FilmGrade(contrast: 1.21, saturation: 1.28, warmth: 0.06, brightness: -0.01, mono: false)
        case .slidePastel: FilmGrade(contrast: 0.88, saturation: 0.88, warmth: 0.13, brightness: 0.045, mono: false)
        case .slideCool: FilmGrade(contrast: 1.10, saturation: 1.05, warmth: -0.32, brightness: 0, mono: false)
        case .slideDeep: FilmGrade(contrast: 1.28, saturation: 0.94, warmth: -0.05, brightness: -0.02, mono: false)
        case .instantWarm: FilmGrade(contrast: 0.86, saturation: 0.85, warmth: 0.38, brightness: 0.055, mono: false)
        case .instantSoft: FilmGrade(contrast: 0.79, saturation: 0.75, warmth: 0.09, brightness: 0.075, mono: false)
        case .instantPink: FilmGrade(contrast: 0.86, saturation: 0.89, warmth: 0.28, brightness: 0.05, mono: false)
        case .instantDust: FilmGrade(contrast: 0.82, saturation: 0.70, warmth: 0.43, brightness: 0.035, mono: false)
        case .instantBleach: FilmGrade(contrast: 0.75, saturation: 0.61, warmth: 0.1, brightness: 0.075, mono: false)
        case .faded: FilmGrade(contrast: 0.82, saturation: 0.82, warmth: 0.21, brightness: 0.055, mono: false)
        case .vintageGolden: FilmGrade(contrast: 1.05, saturation: 0.87, warmth: 0.48, brightness: 0.015, mono: false)
        case .vintageTeal: FilmGrade(contrast: 1.03, saturation: 0.82, warmth: -0.23, brightness: 0.0, mono: false)
        case .vintageMuted: FilmGrade(contrast: 0.82, saturation: 0.64, warmth: 0.15, brightness: 0.06, mono: false)
        case .vintage1979: FilmGrade(contrast: 1.12, saturation: 0.81, warmth: 0.32, brightness: -0.005, mono: false)
        case .mono: FilmGrade(contrast: 1.22, saturation: 0, warmth: 0, brightness: 0, mono: true)
        case .monoSoft: FilmGrade(contrast: 0.87, saturation: 0, warmth: 0, brightness: 0.025, mono: true)
        case .monoHigh: FilmGrade(contrast: 1.40, saturation: 0, warmth: 0, brightness: -0.025, mono: true)
        case .monoMatte: FilmGrade(contrast: 0.77, saturation: 0, warmth: 0, brightness: 0.06, mono: true)
        case .monoSilver: FilmGrade(contrast: 1.17, saturation: 0, warmth: 0, brightness: 0.02, mono: true)
        }
    }
}

enum RenderError: LocalizedError {
    case cannotRead, cannotRender, cannotWrite
    var errorDescription: String? {
        switch self {
        case .cannotRead: "Original image could not be decoded."
        case .cannotRender: "Image rendering failed."
        case .cannotWrite: "The exported image could not be written."
        }
    }
}

/// Original GPU-backed pipeline for orelio (not extracted from RNI Films).
final class ImagePipeline {
    static let shared = ImagePipeline()
    private let context = CIContext(options: [.cacheIntermediates: false])
    private init() {}

    private func source(_ record: PhotoRecord) throws -> CIImage {
        guard let image = CIImage(contentsOf: AppFolders.original(record), options: [.applyOrientationProperty: true]),
              image.extent.width > 0, image.extent.height > 0 else { throw RenderError.cannotRead }
        return image
    }

    private func filter(_ name: String, image: CIImage, values: [String: Any]) -> CIImage {
        guard let f = CIFilter(name: name) else { return image }
        f.setValue(image, forKey: kCIInputImageKey)
        for (key, value) in values { f.setValue(value, forKey: key) }
        return f.outputImage ?? image
    }

    private func apply(_ recipe: EditRecipe, to image: CIImage, date: Date) -> CIImage {
        var output = image
        let grade = recipe.look.grade
        let strength = max(0, min(1, recipe.strength))
        let contrast = max(0.2, min(2.4, (1 + (grade.contrast - 1) * strength) * recipe.contrast * (1 - recipe.fade * 0.27)))
        output = filter("CIColorControls", image: output, values: [
            kCIInputBrightnessKey: grade.brightness * strength + recipe.exposure * 0.26 + recipe.fade * 0.035,
            kCIInputContrastKey: contrast,
            kCIInputSaturationKey: (1 + ((grade.mono ? 0 : grade.saturation) - 1) * strength) * recipe.saturation
        ])
        let warmth = min(1, max(-1, recipe.warmth + recipe.preWarmth + recipe.postWarmth + grade.warmth * strength))
        let tint = min(1, max(-1, recipe.preTint + recipe.postTint))
        if abs(warmth) > 0.001 || abs(tint) > 0.001 {
            output = filter("CIColorMatrix", image: output, values: [
                "inputRVector": CIVector(x: CGFloat(1 + warmth * 0.085 + tint * 0.035), y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: CGFloat(1 + warmth * 0.012 - tint * 0.060), z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: CGFloat(1 - warmth * 0.095 + tint * 0.028), w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])
        }
        if recipe.clarity > 0 {
            output = filter("CIUnsharpMask", image: output, values: ["inputRadius": 2.8, "inputIntensity": recipe.clarity * 0.75])
        }
        if recipe.sharpen > 0 {
            output = filter("CISharpenLuminance", image: output, values: ["inputSharpness": recipe.sharpen * 1.5])
        }
        if recipe.shadows != 0 || recipe.highlights != 0 {
            output = filter("CIHighlightShadowAdjust", image: output, values: [
                "inputShadowAmount": recipe.shadows,
                "inputHighlightAmount": max(0, min(1, 1 - recipe.highlights * 0.75))
            ])
        }
        if recipe.vignette > 0 || recipe.vintageLens > 0 {
            output = filter("CIVignette", image: output, values: [
                kCIInputIntensityKey: recipe.vignette * 1.7 + recipe.vintageLens * 0.5,
                kCIInputRadiusKey: min(output.extent.width, output.extent.height) * 0.78
            ])
        }
        if recipe.grain > 0, let random = CIFilter(name: "CIRandomGenerator")?.outputImage {
            let grainScale = max(0.4, min(3.0, recipe.grainSize * 2.5))
            let grainSource = random.transformed(by: CGAffineTransform(scaleX: grainScale, y: grainScale)).cropped(to: output.extent)
            let noise = filter("CIColorControls", image: grainSource, values: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 1.5
            ])
            let opacityNoise = filter("CIColorMatrix", image: noise, values: [
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(recipe.grain * 0.24))
            ])
            output = filter("CIOverlayBlendMode", image: opacityNoise,
                            values: [kCIInputBackgroundImageKey: output]).cropped(to: image.extent)
        }
        output = addLighting(recipe, to: output)
        if recipe.dust > 0 { output = addDust(recipe.dust, to: output) }
        if recipe.dateStamp { output = addDateStamp(recipe.dateStampText, date: date, to: output) }
        // Outline is intentionally last: it is included in previews, full-size files
        // and batch exports. The composition grid is NEVER part of this pipeline.
        return applyBorder(recipe, to: output.cropped(to: image.extent))
    }

    /// Inside preserves exact dimensions. Outside grows the canvas, so the stroke
    /// never clips at the image edge. Uses Core Image rectangles for crisp pixels.
    private func applyBorder(_ recipe: EditRecipe, to input: CIImage) -> CIImage {
        guard recipe.borderEnabled else { return input }
        let bounds = input.extent.integral
        guard bounds.width > 1, bounds.height > 1 else { return input }
        let fraction = min(0.08, max(0.002, recipe.borderThickness))
        let thickness = CGFloat(max(1, Int((min(bounds.width, bounds.height) * fraction).rounded())))
        let color: CIColor = recipe.borderColor == .white
            ? CIColor(red: 1, green: 1, blue: 1, alpha: 1)
            : CIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let infiniteColor = CIImage(color: color)
        func over(_ foreground: CIImage, _ background: CIImage, rect: CGRect) -> CIImage {
            filter("CISourceOverCompositing", image: foreground.cropped(to: rect),
                   values: [kCIInputBackgroundImageKey: background]).cropped(to: background.extent)
        }
        if recipe.borderPlacement == .outside {
            let canvas = bounds.insetBy(dx: -thickness, dy: -thickness)
            let background = infiniteColor.cropped(to: canvas)
            return over(input, background, rect: bounds).cropped(to: canvas)
        }
        let t = min(thickness, floor(min(bounds.width, bounds.height) / 2))
        let rectangles = [
            CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: t),
            CGRect(x: bounds.minX, y: bounds.maxY - t, width: bounds.width, height: t),
            CGRect(x: bounds.minX, y: bounds.minY + t, width: t, height: max(0, bounds.height - 2 * t)),
            CGRect(x: bounds.maxX - t, y: bounds.minY + t, width: t, height: max(0, bounds.height - 2 * t))
        ]
        var result = input
        for rect in rectangles where rect.width > 0 && rect.height > 0 {
            result = over(infiniteColor, result, rect: rect)
        }
        return result.cropped(to: bounds)
    }

    /// Offline additive lighting, composited one layer at a time on Core Image / GPU.
    /// These are artistic procedural effects, not photorealistic object-aware light.
    private func addLighting(_ recipe: EditRecipe, to image: CIImage) -> CIImage {
        let layers: [LightLayer]
        if !recipe.lightLayers.isEmpty {
            layers = recipe.lightLayers
        } else if recipe.lighting != .none {
            layers = [LightLayer(kind: recipe.lighting, x: recipe.lightX, y: recipe.lightY,
                                 radius: recipe.lightRadius, opacity: recipe.lightIntensity)]
        } else {
            return image
        }
        var composited = image
        for layer in layers where layer.kind != .none && layer.opacity > 0 {
            composited = compositeLight(layer, over: composited)
        }
        return composited.cropped(to: image.extent)
    }

    private func compositeLight(_ layer: LightLayer, over image: CIImage) -> CIImage {
        let bounds = image.extent
        let center = CGPoint(x: bounds.minX + bounds.width * CGFloat(min(1, max(0, layer.x))),
                             y: bounds.minY + bounds.height * CGFloat(1 - min(1, max(0, layer.y))))
        let radius = max(bounds.width, bounds.height) * CGFloat(min(1.5, max(0.05, layer.radius)))
        let alpha = CGFloat(min(1, max(0, layer.opacity)))
        let rgb: (CGFloat, CGFloat, CGFloat)
        switch layer.kind {
        case .none: return image
        case .warmSun, .sunRays: rgb = (1, 0.67, 0.28)
        case .coolGlow, .anamorphic: rgb = (0.40, 0.68, 1)
        case .lightLeak: rgb = (1, 0.25, 0.12)
        }

        func gradient(scaleX: CGFloat, scaleY: CGFloat, degrees: Double, strength: CGFloat) -> CIImage? {
            guard let filter = CIFilter(name: "CIRadialGradient") else { return nil }
            let soft = CGFloat(min(1, max(0, layer.softness)))
            filter.setValue(CIVector(x: 0, y: 0), forKey: "inputCenter")
            filter.setValue(radius * (1 - soft) * 0.6, forKey: "inputRadius0")
            filter.setValue(radius, forKey: "inputRadius1")
            filter.setValue(CIColor(red: rgb.0, green: rgb.1, blue: rgb.2,
                                    alpha: alpha * strength), forKey: "inputColor0")
            filter.setValue(CIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 0), forKey: "inputColor1")
            guard let base = filter.outputImage else { return nil }
            let scaled = base.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            let rotated = scaled.transformed(by: CGAffineTransform(rotationAngle: CGFloat(degrees * .pi / 180)))
            return rotated.transformed(by: CGAffineTransform(translationX: center.x, y: center.y))
                .cropped(to: bounds)
        }

        func screen(_ top: CIImage, _ bottom: CIImage) -> CIImage {
            filter("CIScreenBlendMode", image: top,
                   values: [kCIInputBackgroundImageKey: bottom]).cropped(to: bounds)
        }

        switch layer.kind {
        case .warmSun, .coolGlow:
            guard let overlay = gradient(scaleX: 1, scaleY: 1, degrees: 0, strength: 0.74) else { return image }
            return screen(overlay, image)
        case .lightLeak:
            guard let overlay = gradient(scaleX: 0.42, scaleY: 1.85, degrees: layer.rotation,
                                         strength: 0.82) else { return image }
            return screen(overlay, image)
        case .anamorphic:
            guard let overlay = gradient(scaleX: 2.6, scaleY: 0.08, degrees: layer.rotation,
                                         strength: 0.85) else { return image }
            return screen(overlay, image)
        case .sunRays:
            // Three soft crossed beams + a low-energy source glow. No internet or ML required.
            var result = image
            for offset in [-18.0, 0, 18.0] {
                if let ray = gradient(scaleX: 0.13, scaleY: 2.2,
                                      degrees: layer.rotation + offset,
                                      strength: offset == 0 ? 0.58 : 0.32) {
                    result = screen(ray, result)
                }
            }
            if let halo = gradient(scaleX: 0.55, scaleY: 0.55,
                                   degrees: 0, strength: 0.23) { result = screen(halo, result) }
            return result
        case .none: return image
        }
    }

    /// Deterministic lightweight dust overlay; generated at fixed size then scaled locally.
    private func addDust(_ strength: Double, to input: CIImage) -> CIImage {
        let amount = min(1, max(0, strength))
        let side: CGFloat = 800
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let output = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { renderer in
            let context = renderer.cgContext
            var seed: UInt64 = 321_673_141
            func rand() -> CGFloat {
                seed = seed &* 2862933555777941757 &+ 3037000493
                return CGFloat((seed >> 34) % 10000) / 10000
            }
            for _ in 0..<Int(65 * amount) {
                let x = rand() * side, y = rand() * side
                let diameter = 1.4 + rand() * 3.5
                context.setFillColor(UIColor(white: 0.93, alpha: CGFloat(0.13 + amount * 0.19)).cgColor)
                context.fillEllipse(in: CGRect(x: x, y: y, width: diameter, height: diameter))
            }
            for _ in 0..<Int(10 * amount) {
                let x = rand() * side, y = rand() * side
                context.setStrokeColor(UIColor(white: 0.95, alpha: CGFloat(amount * 0.19)).cgColor)
                context.setLineWidth(0.7 + rand() * 0.8)
                context.move(to: CGPoint(x: x, y: y))
                context.addLine(to: CGPoint(x: x + rand() * 7, y: min(side, y + 15 + rand() * 150)))
                context.strokePath()
            }
        }
        guard let overlay = CIImage(image: output) else { return input }
        let target = input.extent
        let scaled = overlay.transformed(by: CGAffineTransform(scaleX: target.width / side, y: target.height / side))
            .transformed(by: CGAffineTransform(translationX: target.minX, y: target.minY))
        return filter("CISourceOverCompositing", image: scaled, values: [kCIInputBackgroundImageKey: input]).cropped(to: target)
    }

    private func addDateStamp(_ caption: String, date: Date, to input: CIImage) -> CIImage {
        let bounds = input.extent
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        let label = caption.isEmpty ? dateFormatter.string(from: date) : String(caption.prefix(30))
        let width: CGFloat = 800, height: CGFloat = 1000
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let ui = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { _ in
            (label as NSString).draw(at: CGPoint(x: 42, y: 928), withAttributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor(red: 0.99, green: 0.64, blue: 0.32, alpha: 0.90)
            ])
        }
        guard let overlay = CIImage(image: ui) else { return input }
        let scaled = overlay.transformed(by: CGAffineTransform(scaleX: bounds.width / width, y: bounds.height / height))
            .transformed(by: CGAffineTransform(translationX: bounds.minX, y: bounds.minY))
        return filter("CISourceOverCompositing", image: scaled, values: [kCIInputBackgroundImageKey: input]).cropped(to: bounds)
    }

    func renderPreview(_ record: PhotoRecord, maxDimension: CGFloat = 1700) -> UIImage? {
        guard var ci = try? source(record) else { return nil }
        let side = max(ci.extent.width, ci.extent.height)
        if side > maxDimension {
            let ratio = maxDimension / side
            ci = ci.transformed(by: CGAffineTransform(scaleX: ratio, y: ratio))
        }
        let image = apply(record.recipe, to: ci, date: record.importedAt)
        guard let rendered = context.createCGImage(image, from: image.extent) else { return nil }
        return UIImage(cgImage: rendered)
    }

    func renderFullSize(_ record: PhotoRecord, maxDimension: Int? = nil) throws -> CGImage {
        var original = try source(record)
        if let maxDimension, maxDimension > 0 {
            let longest = max(original.extent.width, original.extent.height)
            if longest > CGFloat(maxDimension) {
                let ratio = CGFloat(maxDimension) / longest
                original = original.transformed(by: CGAffineTransform(scaleX: ratio, y: ratio))
            }
        }
        let image = apply(record.recipe, to: original, date: record.importedAt)
        guard let result = context.createCGImage(image, from: image.extent) else { throw RenderError.cannotRender }
        return result
    }

    @discardableResult
    func makeThumbnail(from file: URL, to destination: URL) -> Bool {
        guard let src = CGImageSourceCreateWithURL(file as CFURL, nil) else { return false }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 500,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary),
              let encoded = UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.75) else { return false }
        do { try encoded.write(to: destination, options: .atomic); return true }
        catch { return false }
    }

    func export(_ record: PhotoRecord, format: ExportFormat, quality: Double,
                maxDimension: Int? = nil, to output: URL) throws {
        let image = try renderFullSize(record, maxDimension: maxDimension)
        let identifier: String
        switch format {
        case .jpeg: identifier = UTType.jpeg.identifier
        case .png: identifier = UTType.png.identifier
        case .heic: identifier = UTType.heic.identifier
        }
        guard let destination = CGImageDestinationCreateWithURL(output as CFURL, identifier as CFString, 1, nil) else {
            throw RenderError.cannotWrite
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: max(0.1, min(1.0, quality))] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { throw RenderError.cannotWrite }
    }
}
