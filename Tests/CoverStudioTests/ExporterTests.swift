import CoreGraphics
import Foundation
import XCTest
@testable import CoverStudio

final class ExporterTests: XCTestCase {
    private var temporaryDirectory: URL?

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExporterTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory!, withIntermediateDirectories: true)
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        if let dir = temporaryDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        try super.tearDownWithError()
    }

    // MARK: - PNG

    func testExportPNGCreatesNonEmptyFile() throws {
        let url = temporaryDirectory!.appendingPathComponent("test.png")
        try CoverExporter.exportPNG(image: makeTestImage(), to: url)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
        XCTAssertGreaterThan(size, 0)
    }

    // MARK: - JPEG

    func testExportJPGCreatesNonEmptyFile() throws {
        let url = temporaryDirectory!.appendingPathComponent("test.jpg")
        try CoverExporter.exportJPG(image: makeTestImage(), to: url)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
        XCTAssertGreaterThan(size, 0)
    }

    func testExportJPGHonorsQuality() throws {
        let highURL = temporaryDirectory!.appendingPathComponent("high.jpg")
        let lowURL  = temporaryDirectory!.appendingPathComponent("low.jpg")
        let img = makeTestImage(width: 400, height: 400)

        try CoverExporter.exportJPG(image: img, quality: 0.95, to: highURL)
        try CoverExporter.exportJPG(image: img, quality: 0.1,  to: lowURL)

        let highSize = try FileManager.default.attributesOfItem(atPath: highURL.path)[.size] as? Int ?? 0
        let lowSize  = try FileManager.default.attributesOfItem(atPath: lowURL.path)[.size] as? Int ?? 0
        XCTAssertGreaterThan(highSize, lowSize, "Higher quality should produce a larger JPEG file")
    }

    // MARK: - PDF

    func testExportPDFCreatesNonEmptyFile() throws {
        let url = temporaryDirectory!.appendingPathComponent("test.pdf")
        try CoverExporter.exportPDF(image: makeTestImage(), widthInches: 6.0, heightInches: 9.0, to: url)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
        XCTAssertGreaterThan(size, 0)
    }

    func testExportPDFStartsWithPDFHeader() throws {
        let url = temporaryDirectory!.appendingPathComponent("test.pdf")
        try CoverExporter.exportPDF(image: makeTestImage(), widthInches: 6.0, heightInches: 9.0, to: url)

        let data = try Data(contentsOf: url)
        XCTAssertTrue(data.starts(with: [0x25, 0x50, 0x44, 0x46]), "PDF must begin with %PDF")
    }

    // MARK: - Helper

    private func makeTestImage(width: Int = 100, height: Int = 100) -> CGImage {
        let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(CGColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()!
    }
}
