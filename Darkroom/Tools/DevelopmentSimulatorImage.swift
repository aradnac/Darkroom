//
//  DevelopmentSimulatorImage.swift
//  Darkroom
//
//  The example frame the simulator acts on, and the filter chain that acts on
//  it. The frame is drawn rather than photographed: a wet street at dusk, with
//  a full range of tones, fine window and railing detail and a lamp for a
//  highlight, so contrast, density, grain and fog all have something to show.
//
//  The filters are the model's business, not a film scan's: exposure follows the
//  development, contrast follows the contrast percentage, a lifted black point
//  reads as fog, and the grain tracks the grain steps.
//

import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

// MARK: - The frame

enum DevelopmentSimulatorFrame {
    static let pixelSize = CGSize(width: 1200, height: 700)

    /// Drawn once and reused: every preview is a filter over this image.
    static let image: CGImage? = draw()

    private static func draw() -> CGImage? {
        let width = Int(pixelSize.width)
        let height = Int(pixelSize.height)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        // Work with y running down from the top.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        func fill(_ rect: CGRect, _ value: Double) {
            context.setFillColor(CGColor(red: value, green: value, blue: value, alpha: 1))
            context.fill(rect)
        }

        var random = SeededRandom(seed: 0x5EED_1234_ABCD)
        let canvasWidth = CGFloat(width)
        let canvasHeight = CGFloat(height)
        let horizon = canvasHeight * 0.62

        // Sky: a pale overcast evening, darker at the top.
        if let sky = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [CGColor(red: 0.74, green: 0.74, blue: 0.75, alpha: 1),
                     CGColor(red: 0.84, green: 0.84, blue: 0.85, alpha: 1),
                     CGColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1)] as CFArray,
            locations: [0, 0.6, 1]
        ) {
            context.saveGState()
            context.clip(to: CGRect(x: 0, y: 0, width: canvasWidth, height: horizon))
            context.drawLinearGradient(
                sky,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: horizon),
                options: []
            )
            context.restoreGState()
        }

        // The far terrace: a long row of buildings, lightened by the distance.
        var x: CGFloat = -10
        while x < canvasWidth + 10 {
            let buildingWidth = CGFloat(46 + random.value() * 78)
            let buildingHeight = CGFloat(120 + random.value() * 140)
            let top = horizon - buildingHeight
            let value = 0.50 + random.value() * 0.06
            fill(CGRect(x: x, y: top, width: buildingWidth, height: buildingHeight), value)

            // Chimneys and roof lines.
            fill(CGRect(x: x + buildingWidth * 0.2, y: top - 9, width: 8, height: 9), 0.46)
            fill(CGRect(x: x + buildingWidth * 0.68, y: top - 5, width: 6, height: 5), 0.46)

            // Windows: a few lit, most dark.
            var windowY = top + 13
            while windowY < horizon - 12 {
                var windowX = x + 9
                while windowX < x + buildingWidth - 12 {
                    let roll = random.value()
                    if roll > 0.80 {
                        fill(CGRect(x: windowX, y: windowY, width: 5, height: 7), 0.88)
                    } else if roll > 0.46 {
                        fill(CGRect(x: windowX, y: windowY, width: 5, height: 7), 0.30)
                    }
                    windowX += 12
                }
                windowY += 16
            }

            x += buildingWidth + 2
        }

        // The near terrace: taller, darker, with a shopfront band.
        x = -30
        while x < canvasWidth + 30 {
            let buildingWidth = CGFloat(96 + random.value() * 90)
            let buildingHeight = CGFloat(190 + random.value() * 130)
            let top = horizon - buildingHeight
            let value = 0.30 + random.value() * 0.06
            fill(CGRect(x: x, y: top, width: buildingWidth, height: buildingHeight), value)

            // Window rows.
            var windowY = top + 16
            while windowY < horizon - 40 {
                var windowX = x + 12
                while windowX < x + buildingWidth - 16 {
                    let roll = random.value()
                    if roll > 0.82 {
                        fill(CGRect(x: windowX, y: windowY, width: 9, height: 13), 0.72)
                    } else {
                        fill(CGRect(x: windowX, y: windowY, width: 9, height: 13), 0.16)
                    }
                    windowX += 20
                }
                windowY += 22
            }

            // Shopfront glass at street level.
            fill(CGRect(x: x + 10, y: horizon - 34, width: buildingWidth - 20, height: 26), 0.20)
            fill(CGRect(x: x + 14, y: horizon - 30, width: buildingWidth - 34, height: 4), 0.55)

            x += buildingWidth + 4
        }

        // Road: wet and darker towards the bottom of the frame.
        if let road = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [CGColor(red: 0.40, green: 0.40, blue: 0.41, alpha: 1),
                     CGColor(red: 0.24, green: 0.24, blue: 0.25, alpha: 1),
                     CGColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 1)] as CFArray,
            locations: [0, 0.45, 1]
        ) {
            context.saveGState()
            context.clip(to: CGRect(x: 0, y: horizon, width: canvasWidth, height: canvasHeight - horizon))
            context.drawLinearGradient(
                road,
                start: CGPoint(x: 0, y: horizon),
                end: CGPoint(x: 0, y: canvasHeight),
                options: []
            )
            context.restoreGState()
        }

        // Reflections of the sky and the lamp across the wet road.
        for _ in 0..<16 {
            let reflectionWidth = CGFloat(20 + random.value() * 130)
            let reflectionX = CGFloat(random.value()) * canvasWidth
            let reflectionY = horizon + 6 + CGFloat(random.value()) * (canvasHeight - horizon - 20)
            let reflectionHeight = CGFloat(2 + random.value() * 5)
            let value = 0.45 + random.value() * 0.22
            fill(CGRect(x: reflectionX, y: reflectionY, width: reflectionWidth, height: reflectionHeight), value)
        }

        // A pavement line and a kerb.
        fill(CGRect(x: 0, y: horizon - 5, width: canvasWidth, height: 3), 0.52)

        // The lamp: a post, a lantern and its glow.
        let lampX = canvasWidth * 0.635
        fill(CGRect(x: lampX - 5, y: CGFloat(height) * 0.26, width: 10, height: horizon - CGFloat(height) * 0.26), 0.08)
        fill(CGRect(x: lampX - 7, y: CGFloat(height) * 0.30, width: 14, height: 10), 0.12)
        fill(CGRect(x: lampX - 15, y: CGFloat(height) * 0.235, width: 30, height: 30), 0.10)
        fill(CGRect(x: lampX - 11, y: CGFloat(height) * 0.245, width: 22, height: 19), 0.96)
        fill(CGRect(x: lampX - 21, y: CGFloat(height) * 0.227, width: 42, height: 6), 0.08)

        if let glow = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [CGColor(red: 1, green: 1, blue: 1, alpha: 0.80),
                     CGColor(red: 1, green: 1, blue: 1, alpha: 0.22),
                     CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray,
            locations: [0, 0.35, 1]
        ) {
            let centre = CGPoint(x: lampX, y: CGFloat(height) * 0.255)
            context.drawRadialGradient(
                glow,
                startCenter: centre,
                startRadius: 0,
                endCenter: centre,
                endRadius: 150,
                options: []
            )
        }

        // A railing on the right, with the fine bars that show detail.
        let railingX = canvasWidth * 0.80
        fill(CGRect(x: railingX, y: canvasHeight * 0.36, width: 5, height: canvasHeight * 0.28), 0.10)
        var barX = railingX + 14
        while barX < canvasWidth - 6 {
            fill(CGRect(x: barX, y: canvasHeight * 0.40, width: 2.5, height: canvasHeight * 0.24), 0.12)
            barX += 11
        }
        fill(CGRect(x: railingX, y: canvasHeight * 0.395, width: canvasWidth - railingX, height: 3), 0.09)

        // Two distant headlights.
        fill(CGRect(x: canvasWidth * 0.33, y: horizon - 12, width: 12, height: 6), 0.93)
        fill(CGRect(x: canvasWidth * 0.36, y: horizon - 12, width: 9, height: 5), 0.86)

        // Vignette: the corners fall away, as they do on a wet night.
        if let vignette = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [CGColor(red: 0, green: 0, blue: 0, alpha: 0),
                     CGColor(red: 0, green: 0, blue: 0, alpha: 0.06),
                     CGColor(red: 0, green: 0, blue: 0, alpha: 0.36)] as CFArray,
            locations: [0, 0.6, 1]
        ) {
            let centre = CGPoint(x: canvasWidth / 2, y: canvasHeight * 0.55)
            context.drawRadialGradient(
                vignette,
                startCenter: centre,
                startRadius: canvasHeight * 0.25,
                endCenter: centre,
                endRadius: canvasHeight * 0.85,
                options: []
            )
        }

        return context.makeImage()
    }
}

/// A small deterministic generator, so the example frame is the same picture
/// every launch rather than a different street each time.
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func value() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0xFFFFFF) / Double(0xFFFFFF)
    }
}

// MARK: - The filters

enum DevelopmentSimulatorRenderer {
    private static let context = CIContext(options: [CIContextOption.cacheIntermediates: false])

    /// One noise field for the whole run, so the grain sits in the same place
    /// while a slider moves instead of shimmering at every touch.
    private static let noiseField = CIFilter.randomGenerator().outputImage

    /// The main preview, and the stop either side of it.
    static func render(reading: DevelopmentSimulatorReading) -> DevelopmentSimulatorRender {
        guard let frame = DevelopmentSimulatorFrame.image else { return .empty }

        let base = CIImage(cgImage: frame)
        let small = base.transformed(by: CGAffineTransform(scaleX: 0.34, y: 0.34))

        return DevelopmentSimulatorRender(
            main: render(base, parameters: reading.parameters()),
            minusOneStop: render(small, parameters: reading.parameters(shiftingStops: -1)),
            plusOneStop: render(small, parameters: reading.parameters(shiftingStops: 1))
        )
    }

    private static func render(
        _ base: CIImage,
        parameters: DevelopmentSimulatorRenderParameters
    ) -> CGImage? {
        var image = base

        if parameters.grain > 0.01 {
            image = addGrain(to: image, amount: parameters.grain)
        }

        let exposure = CIFilter.exposureAdjust()
        exposure.inputImage = image
        exposure.ev = Float(parameters.exposureEV)
        if let output = exposure.outputImage { image = output }

        let controls = CIFilter.colorControls()
        controls.inputImage = image
        controls.contrast = Float(parameters.contrast)
        controls.saturation = 0
        controls.brightness = 0
        if let output = controls.outputImage { image = output }

        if parameters.blackLift > 0.001 {
            let lift = CIFilter.colorMatrix()
            lift.inputImage = image
            let value = CGFloat(parameters.blackLift)
            lift.biasVector = CIVector(x: value, y: value, z: value, w: 0)
            if let output = lift.outputImage { image = output }
        }

        let extent = base.extent
        image = image.cropped(to: extent)
        return context.createCGImage(image, from: extent)
    }

    /// A monochrome noise field laid over the frame. The overlay blend leaves the
    /// base alone at mid-grey and modulates it either side, and the contrast of
    /// the field is what sets how visible the grain is.
    private static func addGrain(to image: CIImage, amount: Double) -> CIImage {
        guard let noise = noiseField else { return image }

        let mono = CIFilter.colorMatrix()
        mono.inputImage = noise.cropped(to: image.extent)
        let luma = CIVector(x: 0.34, y: 0.34, z: 0.34, w: 0)
        mono.rVector = luma
        mono.gVector = luma
        mono.bVector = luma
        mono.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        guard let grey = mono.outputImage else { return image }

        let spread = CIFilter.colorControls()
        spread.inputImage = grey
        spread.contrast = Float(1 + min(1, max(0, amount)) * 2.4)
        spread.saturation = 0
        guard let field = spread.outputImage else { return image }

        let blend = CIFilter.overlayBlendMode()
        blend.inputImage = field.cropped(to: image.extent)
        blend.backgroundImage = image
        return blend.outputImage ?? image
    }
}
