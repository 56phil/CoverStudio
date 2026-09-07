import AppKit
import CoreGraphics
import UniformTypeIdentifiers
import XCTest

@testable import CoverStudio

final class FitFrameTests: XCTestCase {
    private var temporaryRoots: [URL] = []

    override func tearDownWithError() throws {
        for root in temporaryRoots {
            try? FileManager.default.removeItem(at: root)
        }
        temporaryRoots.removeAll()
        try super.tearDownWithError()
    }

    // Fit mode must frame the art to the VISIBLE front cover region
    // (effectiveFrontLeft..frontWidth × trimTop..frontHeight) — the area KDP's
    // previewer shows — not the full panel. On hardcover the panel extends
    // 0.591" (wrap) beyond the visible region top, bottom, and outer edge;
    // art contained to the panel would be truncated by that amount in preview.
    func testFitModeFramesArtToVisibleFrontRegion() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoverStudioTests-\(UUID().uuidString)", isDirectory: true)
        temporaryRoots.append(root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        // Solid red source, aspect 2:3 (like a portrait board design).
        let sourceURL = root.appendingPathComponent("art.png")
        try writePNG(solidImage(width: 800, height: 1200, r: 220, g: 40, b: 40), to: sourceURL)

        var data = CoverData()
        data.bindingType = .hc
        data.trimSize = .sixX9
        data.templateFullCoverWidth = 14.009
        data.templateFullCoverHeight = 10.417
        data.templateFrontCoverWidth = 6.197
        data.templateFrontCoverHeight = 9.236
        data.templateSpineWidth = 0.434
        data.templateHingeWidth = 0.394
        data.templateWrapWidth = 0.591
        data.frontCoverImage = sourceURL.path
        data.frontImageFit = .fit
        data.frontCoverImageCentered = true
        data.frontText = false
        data.spineColor = "#00ff00"

        let geometry = try computeGeometry(from: data)
        let renderer = CoverRenderer(data: data, geometry: geometry)
        let image = try XCTUnwrap(renderer.renderFullCover(includeGuides: false))

        // Contained art: aspect 2:3 in a 6.197×9.236 frame → height-bound:
        // 9.236 tall × 6.157 wide, centered in the visible region. The full-width
        // rows through the visible region's vertical center must be red; the rows
        // inside the wrap strips (top/bottom of the panel) must be green letterbox.
        let centerY = geometry.totalHeight - geometry.trimTop - geometry.frontHeight / 2
        let midRow = try pixels(
            in: CGRect(
                x: geometry.effectiveFrontLeft, y: centerY - 10,
                width: geometry.frontWidth, height: 20), from: image)
        XCTAssertTrue(
            midRow.contains { $0.red > 180 && $0.green < 90 && $0.blue < 90 },
            "Art should fill the visible frame's center.")

        // Top wrap strip (above the visible region): letterbox, not art.
        let wrapStrip = try pixels(
            in: CGRect(
                x: geometry.effectiveFrontLeft, y: geometry.totalHeight - 10,
                width: geometry.frontWidth, height: 10), from: image)
        XCTAssertTrue(
            wrapStrip.contains { $0.green > 180 && $0.red < 90 && $0.blue < 90 },
            "Wrap strip outside the visible frame should be spine-color letterbox.")

        // The art must reach the visible region's top edge — i.e. the red art
        // begins no lower than trimTop (contained to the frame, not the panel).
        let frameTopRow = try pixels(
            in: CGRect(
                x: geometry.effectiveFrontLeft, y: geometry.totalHeight - geometry.trimTop - 4,
                width: geometry.frontWidth, height: 4), from: image)
        XCTAssertTrue(
            frameTopRow.contains { $0.red > 180 && $0.green < 90 && $0.blue < 90 },
            "Art should touch the top of the visible frame (trimTop).")
    }

    // The inset manipulates the frame: +0.5" pulls the art in on all sides.
    func testFitInsetShrinksFrame() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoverStudioTests-\(UUID().uuidString)", isDirectory: true)
        temporaryRoots.append(root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let sourceURL = root.appendingPathComponent("art.png")
        try writePNG(solidImage(width: 800, height: 1200, r: 220, g: 40, b: 40), to: sourceURL)

        var data = CoverData()
        data.bindingType = .pb
        data.trimSize = .sixX9
        data.pbPageCount = 200
        data.frontCoverImage = sourceURL.path
        data.frontImageFit = .fit
        data.frontImageFitInsetInches = 0.5
        data.frontCoverImageCentered = true
        data.frontText = false
        data.spineColor = "#00ff00"

        let geometry = try computeGeometry(from: data)
        let renderer = CoverRenderer(data: data, geometry: geometry)
        let image = try XCTUnwrap(renderer.renderFullCover(includeGuides: false))

        // With inset, a band just inside the trim top must be letterbox (green),
        // while the frame center is still art (red).
        let insetTopBand = try pixels(
            in: CGRect(
                x: geometry.effectiveFrontLeft, y: geometry.totalHeight - geometry.trimTop,
                width: geometry.frontWidth, height: CoverGeometry.px(0.25)), from: image)
        XCTAssertTrue(
            insetTopBand.contains { $0.green > 180 && $0.red < 90 && $0.blue < 90 },
            "Inset band above the frame should be spine-color letterbox.")

        let centerY = geometry.totalHeight - geometry.trimTop - geometry.frontHeight / 2
        let midRow = try pixels(
            in: CGRect(
                x: geometry.effectiveFrontLeft, y: centerY - 10,
                width: geometry.frontWidth, height: 20), from: image)
        XCTAssertTrue(
            midRow.contains { $0.red > 180 && $0.green < 90 && $0.blue < 90 },
            "Art should still fill the inset frame's center.")
    }

    // MARK: - Helpers

    private func solidImage(width: Int, height: Int, r: Int, g: Int, b: Int) -> CGImage {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for i in stride(from: 0, to: bytes.count, by: 4) {
            bytes[i] = UInt8(r)
            bytes[i + 1] = UInt8(g)
            bytes[i + 2] = UInt8(b)
            bytes[i + 3] = 255
        }
        let ctx = CGContext(
            data: &bytes, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                | CGBitmapInfo.byteOrder32Big.rawValue
        )!
        return ctx.makeImage()!
    }

    private func writePNG(_ image: CGImage, to url: URL) throws {
        let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw CocoaError(.fileWriteUnknown)
        }
    }

    private struct Pixel {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
    }

    private func pixels(in rect: CGRect, from image: CGImage) throws -> [Pixel] {
        let cropped = try XCTUnwrap(image.cropping(to: rect.integral))
        let width = cropped.width
        let height = cropped.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = try XCTUnwrap(
            CGContext(
                data: &bytes, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    | CGBitmapInfo.byteOrder32Big.rawValue
            ))
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 0, to: bytes.count, by: 4).map { o in
            Pixel(red: bytes[o], green: bytes[o + 1], blue: bytes[o + 2])
        }
    }
}
