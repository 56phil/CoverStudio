import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest

@testable import CoverStudio

final class FrontImageFitterTests: XCTestCase {
    private var temporaryRoots: [URL] = []

    override func tearDownWithError() throws {
        for root in temporaryRoots {
            try? FileManager.default.removeItem(at: root)
        }
        temporaryRoots.removeAll()
        try super.tearDownWithError()
    }

    // ── Mode resolution ──────────────────────────────────────────────

    func testAutoFitsCloseAspectAsCover() {
        XCTAssertEqual(
            FrontImageFit.auto.resolved(
                sourceWidth: 600, sourceHeight: 900, panelWidth: 1800, panelHeight: 2700),
            .cover
        )
    }

    func testAutoStretchesMismatchedAspect() {
        XCTAssertEqual(
            FrontImageFit.auto.resolved(
                sourceWidth: 1200, sourceHeight: 800, panelWidth: 1800, panelHeight: 2700),
            .stretch
        )
    }

    func testExplicitModesOverrideAuto() {
        XCTAssertEqual(
            FrontImageFit.cover.resolved(
                sourceWidth: 1200, sourceHeight: 800, panelWidth: 1800, panelHeight: 2700),
            .cover
        )
        XCTAssertEqual(
            FrontImageFit.stretch.resolved(
                sourceWidth: 600, sourceHeight: 900, panelWidth: 1800, panelHeight: 2700),
            .stretch
        )
    }

    // ── Fitted copy materialization ──────────────────────────────────

    func testFitterWritesExactPanelDimensionsCoverMode() throws {
        let source = try makeSourceImage(width: 600, height: 900)

        let fittedPath = FrontImageFitter.updateFittedImage(
            sourcePath: source.path, fit: .cover,
            panelWidth: 1800, panelHeight: 2700,
            relativeTo: nil
        )

        XCTAssertNotNil(fittedPath)
        let fittedURL = URL(fileURLWithPath: fittedPath!)
        XCTAssertTrue(fittedURL.lastPathComponent.hasSuffix("-fitted.png"))

        let fitted = try XCTUnwrap(
            NSImage(contentsOfFile: fittedPath!)?.cgImage(
                forProposedRect: nil, context: nil, hints: nil))
        XCTAssertEqual(fitted.width, 1800)
        XCTAssertEqual(fitted.height, 2700)

        // Cover mode fills the whole panel, so every corner is source-red, not black.
        let px = try pixels(
            in: CGRect(x: 0, y: 0, width: fitted.width, height: fitted.height), from: fitted)
        XCTAssertTrue(px.contains { $0.red > 200 && $0.green < 80 && $0.blue < 80 })
    }

    func testFitterWritesExactPanelDimensionsStretchMode() throws {
        let source = try makeSourceImage(width: 1200, height: 800)

        let fittedPath = FrontImageFitter.updateFittedImage(
            sourcePath: source.path, fit: .stretch,
            panelWidth: 1800, panelHeight: 2700,
            relativeTo: nil
        )

        let fitted = try XCTUnwrap(
            NSImage(contentsOfFile: fittedPath!)?.cgImage(
                forProposedRect: nil, context: nil, hints: nil))
        XCTAssertEqual(fitted.width, 1800)
        XCTAssertEqual(fitted.height, 2700)
    }

    func testFitterRegeneratesWhenSourceChanges() throws {
        let source = try makeSourceImage(width: 600, height: 900)

        _ = FrontImageFitter.updateFittedImage(
            sourcePath: source.path, fit: .cover,
            panelWidth: 1800, panelHeight: 2700, relativeTo: nil
        )
        let fittedURL = FrontImageFitter.fittedPath(for: source)
        let firstData = try Data(contentsOf: fittedURL)

        // Change the source content and push its modification time into the future.
        try writePNG(makeSolidImage(width: 600, height: 900, green: 0, blue: 255), to: source)
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(3600)],
            ofItemAtPath: source.path
        )

        _ = FrontImageFitter.updateFittedImage(
            sourcePath: source.path, fit: .cover,
            panelWidth: 1800, panelHeight: 2700, relativeTo: nil
        )
        let secondData = try Data(contentsOf: fittedURL)
        XCTAssertNotEqual(
            firstData, secondData, "Fitted copy should be regenerated when the source changes.")
    }

    func testRelativeFittedPathReturnsNilWhenNoCopyExists() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoverStudioTests-\(UUID().uuidString)", isDirectory: true)
        temporaryRoots.append(root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let cover = root.appendingPathComponent("cover", isDirectory: true)
        try FileManager.default.createDirectory(at: cover, withIntermediateDirectories: true)
        let coverURL = cover.appendingPathComponent("cover.md")
        try "---\nschema_version: 2\n---\n".write(to: coverURL, atomically: true, encoding: .utf8)

        let baseURL = cover.appendingPathComponent("base.png")
        try writePNG(makeSolidImage(width: 600, height: 900, green: 0, blue: 0), to: baseURL)
        XCTAssertNil(
            FrontImageFitter.relativeFittedPath(for: "cover/base.png", relativeTo: coverURL))
        _ = FrontImageFitter.updateFittedImage(
            sourcePath: "cover/base.png", fit: .cover,
            panelWidth: 1800, panelHeight: 2700, relativeTo: coverURL
        )
        XCTAssertEqual(
            FrontImageFitter.relativeFittedPath(for: "cover/base.png", relativeTo: coverURL),
            "cover/base-fitted.png"
        )
    }

    // ── Trim-switch scenario (6×9 → 5×8) ──────────────────────────────

    func testTrimSwitchRegeneratesFittedCopyAtNewPanelSize() throws {
        let source = try makeSourceImage(width: 600, height: 900)  // 2:3 art

        var data = CoverData()
        data.bindingType = .pb
        data.trimSize = .sixX9
        data.pbPageCount = 200
        data.interiorType = .blackWhite
        data.paperType = .white

        // First fit: 6×9 paperback, image region includes the right bleed.
        var geometry = try computeGeometry(from: data)
        _ = FrontImageFitter.updateFittedImage(
            sourcePath: source.path, fit: .auto,
            panelWidth: geometry.frontImageWidth, panelHeight: geometry.totalHeight, relativeTo: nil
        )
        let fittedURL = FrontImageFitter.fittedPath(for: source)
        var fitted = try XCTUnwrap(NSImage(contentsOfFile: fittedURL.path)?.cgImage(forProposedRect: nil, context: nil, hints: nil))
        XCTAssertEqual(fitted.width, geometry.frontImageWidth)
        XCTAssertEqual(fitted.height, geometry.totalHeight)

        // Switch to 5×8: the copy regenerates at the exact new dimensions.
        data.trimSize = .fiveX8
        geometry = try computeGeometry(from: data)
        _ = FrontImageFitter.updateFittedImage(
            sourcePath: source.path, fit: .auto,
            panelWidth: geometry.frontImageWidth, panelHeight: geometry.totalHeight, relativeTo: nil
        )
        fitted = try XCTUnwrap(NSImage(contentsOfFile: fittedURL.path)?.cgImage(forProposedRect: nil, context: nil, hints: nil))
        XCTAssertEqual(fitted.width, geometry.frontImageWidth)
        XCTAssertEqual(fitted.height, geometry.totalHeight)

        // All four corners are filled with art (red), not letterboxed black.
        let px = try pixels(in: CGRect(x: 0, y: 0, width: fitted.width, height: fitted.height), from: fitted)
        XCTAssertTrue(px.contains { $0.red > 200 && $0.green < 80 && $0.blue < 80 })
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private func makeSourceImage(width: Int, height: Int, in directory: URL? = nil) throws -> URL {
        let dir = directory ?? FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("test-\(UUID().uuidString.prefix(8)).png")
        try writePNG(makeSolidImage(width: width, height: height, green: 0, blue: 0), to: url)
        return url
    }

    private func makeSolidImage(width: Int, height: Int, green: Int, blue: Int) throws -> CGImage {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for i in stride(from: 0, to: bytes.count, by: 4) {
            bytes[i] = 255
            bytes[i + 1] = UInt8(green)
            bytes[i + 2] = UInt8(blue)
            bytes[i + 3] = 255
        }
        let ctx = try XCTUnwrap(
            CGContext(
                data: &bytes, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    | CGBitmapInfo.byteOrder32Big.rawValue
            ))
        return try XCTUnwrap(ctx.makeImage())
    }

    private func writePNG(_ image: CGImage, to url: URL) throws {
        guard
            let dest = CGImageDestinationCreateWithURL(
                url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else {
            throw CocoaError(.fileWriteUnknown)
        }
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
        guard let cropped = image.cropping(to: rect.integral) else {
            XCTFail("Could not crop rendered image")
            return []
        }
        let width = cropped.width
        let height = cropped.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard
            let context = CGContext(
                data: &bytes,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    | CGBitmapInfo.byteOrder32Big.rawValue
            )
        else {
            XCTFail("Could not allocate bitmap context")
            return []
        }
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 0, to: bytes.count, by: 4).map { offset in
            Pixel(red: bytes[offset], green: bytes[offset + 1], blue: bytes[offset + 2])
        }
    }
}
