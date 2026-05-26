import Foundation
import AppKit
import XCTest
import Yams
@testable import CoverStudio

final class ProjectManagerTests: XCTestCase {
    private var temporaryRoots: [URL] = []

    override func tearDownWithError() throws {
        for root in temporaryRoots {
            try? FileManager.default.removeItem(at: root)
        }
        temporaryRoots.removeAll()
        try super.tearDownWithError()
    }

    func testLoadsMarkdownFrontmatterWithLegacyHardcoverKeys() throws {
        let coverURL = try makeCoverFile(contents: """
        ---
        schema_version: 1
        binding_type: hc
        trim_size: 6x9
        page_count: 91
        front_cover_image: cover/assets/base.png
        front_text: false
        title: On Proportion
        author_name: Philip Huffman
        hc_front_image_offset_x_inches: 0.18
        hc_front_title_center_x: true
        hc_front_title_center_y: true
        hc_front_subtitle_scale: 1.35
        hc_spine_title_offset_x_inches: 0.025
        back_author_bio_paragraph_gap_points: 10
        author_photo_circular: false
        template_full_cover_width: 13.996
        template_full_cover_height: 10.417
        template_front_cover_width: 6.197
        template_front_cover_height: 9.236
        template_spine_width: 0.421
        template_hinge_width: 0.394
        template_wrap_width: 0.591
        ---

        # Cover Metadata
        """)

        let data = try ProjectManager.load(from: coverURL)

        XCTAssertEqual(data.bindingType, .hc)
        XCTAssertEqual(data.trimSize, .sixX9)
        XCTAssertEqual(data.pbPageCount, 91)
        XCTAssertEqual(data.hcPageCount, 91)
        XCTAssertEqual(data.resolvedPageCount(), 91)
        XCTAssertEqual(data.frontCoverImage, "cover/assets/base.png")
        XCTAssertFalse(data.frontText)
        XCTAssertEqual(data.resolvedImageOffsetX(), 0.18, accuracy: 0.0001)
        XCTAssertTrue(data.resolvedTitleCenterX())
        XCTAssertTrue(data.resolvedTitleCenterY())
        XCTAssertEqual(data.resolvedSubtitleScale(), 1.35, accuracy: 0.0001)
        XCTAssertEqual(data.spineTitleOffsetXInches, 0.025, accuracy: 0.0001)
        XCTAssertEqual(data.spineColorExtensionInches, CoverLayoutDefaults.spineColorExtensionInches, accuracy: 0.0001)
        XCTAssertEqual(data.authorPhotoScaleInches, 1.18, accuracy: 0.0001)
        XCTAssertEqual(data.authorPhotoShape, .square)
        XCTAssertEqual(data.authorBioParagraphGapPoints, 10, accuracy: 0.0001)
    }

    func testResolvesBookRootAndCoverRelativeAssetPaths() throws {
        let coverURL = try makeCoverFile(contents: """
        ---
        schema_version: 1
        title: Example
        ---
        """)
        let bookRoot = ProjectManager.projectRoot(for: coverURL)
        let assetURL = bookRoot
            .appendingPathComponent("cover", isDirectory: true)
            .appendingPathComponent("assets", isDirectory: true)
            .appendingPathComponent("base.png")
        try FileManager.default.createDirectory(
            at: assetURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: assetURL)

        XCTAssertEqual(
            ProjectManager.resolveImagePath("cover/assets/base.png", relativeTo: coverURL),
            assetURL.path
        )
        XCTAssertEqual(
            ProjectManager.resolveImagePath("assets/base.png", relativeTo: coverURL),
            assetURL.path
        )
    }

    func testSavingMarkdownPreservesBodyAndUnknownGeneratorKeys() throws {
        let coverURL = try makeCoverFile(contents: """
        ---
        schema_version: 1
        title: Old Title
        kindle_write_latest: true
        layouts: ""
        ---

        # Cover Metadata

        Edit the YAML frontmatter directly.
        """)

        var data = try ProjectManager.load(from: coverURL)
        data.title = "New Title"
        data.frontText = false
        try ProjectManager.save(data, to: coverURL)

        let saved = try String(contentsOf: coverURL, encoding: .utf8)
        XCTAssertTrue(saved.contains("title: New Title"))
        XCTAssertTrue(saved.contains("front_text: false"))
        XCTAssertTrue(saved.contains("kindle_write_latest: true"))
        XCTAssertTrue(saved.contains("layouts: ''") || saved.contains("layouts: \"\""))
        XCTAssertTrue(saved.contains("# Cover Metadata"))
        XCTAssertTrue(saved.contains("Edit the YAML frontmatter directly."))
    }

    func testSavingMarkdownUpdatesBindingSpecificFrontKeys() throws {
        let coverURL = try makeCoverFile(contents: """
        ---
        schema_version: 1
        binding_type: hc
        title: On Proportion
        hc_front_image_offset_x_inches: 0.18
        hc_front_title_offset_x_inches: -0.3
        hc_front_subtitle_offset_y_inches: 0
        hc_front_author_offset_y_inches: -0.25
        pb_front_title_offset_x_inches: 0.05
        ---
        """)

        var data = try ProjectManager.load(from: coverURL)
        data.hcFrontImageOffsetXInches = 0.22
        data.hcFrontTitleOffsetXInches = -0.35
        data.hcFrontTitleCenterX = true
        data.hcFrontTitleCenterY = true
        data.hcFrontSubtitleOffsetYInches = 0.08
        data.hcFrontSubtitleCenterX = true
        data.hcFrontSubtitleScale = 1.4
        data.hcFrontAuthorOffsetYInches = -0.3
        data.hcFrontAuthorCenterY = true
        try ProjectManager.save(data, to: coverURL)

        let saved = try savedFrontmatterMap(from: coverURL)
        XCTAssertEqual(try numericValue(saved, "hc_front_image_offset_x_inches"), 0.22, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_front_title_offset_x_inches"), -0.35, accuracy: 0.0001)
        XCTAssertEqual(saved["hc_front_title_center_x"] as? Bool, true)
        XCTAssertEqual(saved["hc_front_title_center_y"] as? Bool, true)
        XCTAssertEqual(try numericValue(saved, "hc_front_subtitle_offset_y_inches"), 0.08, accuracy: 0.0001)
        XCTAssertEqual(saved["hc_front_subtitle_center_x"] as? Bool, true)
        XCTAssertEqual(try numericValue(saved, "hc_front_subtitle_scale"), 1.4, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_front_author_offset_y_inches"), -0.3, accuracy: 0.0001)
        XCTAssertEqual(saved["hc_front_author_center_y"] as? Bool, true)
        XCTAssertEqual(try numericValue(saved, "pb_front_title_offset_x_inches"), 0.05, accuracy: 0.0001)
    }

    func testPageCountIsBindingSpecific() throws {
        let coverURL = try makeCoverFile(contents: """
        ---
        schema_version: 1
        binding_type: hc
        page_count: 91
        pb_page_count: 130
        hc_page_count: 91
        template_full_cover_width: 13.996
        template_full_cover_height: 10.417
        template_front_cover_width: 6.197
        template_front_cover_height: 9.236
        template_spine_width: 0.421
        template_hinge_width: 0.394
        template_wrap_width: 0.591
        ---
        """)

        var data = try ProjectManager.load(from: coverURL)
        XCTAssertEqual(data.resolvedPageCount(), 91)

        data.hcPageCount = 95
        try ProjectManager.save(data, to: coverURL)

        let saved = try savedFrontmatterMap(from: coverURL)
        XCTAssertEqual(try numericValue(saved, "page_count"), 95, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "pb_page_count"), 130, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_page_count"), 95, accuracy: 0.0001)
    }

    func testSavingMarkdownPreservesBackTextWidths() throws {
        let coverURL = try makeCoverFile(contents: """
        ---
        schema_version: 1
        title: Width Test
        blurb_width_inches: 4.25
        author_bio_width_inches: 3.5
        ---
        """)

        var data = try ProjectManager.load(from: coverURL)
        XCTAssertEqual(data.blurbWidthInches, 4.25, accuracy: 0.0001)
        XCTAssertEqual(data.authorBioWidthInches, 3.5, accuracy: 0.0001)

        data.blurbWidthInches = 4.0
        data.authorBioWidthInches = 3.25
        try ProjectManager.save(data, to: coverURL)

        let saved = try savedFrontmatterMap(from: coverURL)
        XCTAssertEqual(try numericValue(saved, "blurb_width_inches"), 4.0, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "author_bio_width_inches"), 3.25, accuracy: 0.0001)
    }

    func testBlankBindingSpecificBackKeysFallBackToCanonicalValues() throws {
        let coverURL = try makeCoverFile(contents: """
        ---
        schema_version: 1
        binding_type: hc
        title: Back Cover
        blurb_offset_x_inches: 0.4
        blurb_width_inches: 3.75
        hc_back_blurb_offset_x_inches: ""
        hc_back_blurb_width_inches: ""
        quote_offset_y_inches: 0.2
        hc_back_quote_offset_y_inches: ""
        author_bio_offset_y_inches: -1.5
        author_bio_width_inches: 3.25
        hc_back_author_bio_offset_y_inches: ""
        hc_back_author_bio_width_inches: ""
        author_photo_offset_x_inches: -0.25
        hc_back_author_image_offset_x_inches: ""
        ---
        """)

        let data = try ProjectManager.load(from: coverURL)

        XCTAssertEqual(data.blurbOffsetXInches, 0.4, accuracy: 0.0001)
        XCTAssertEqual(data.blurbWidthInches, 3.75, accuracy: 0.0001)
        XCTAssertEqual(data.quoteOffsetYInches, 0.2, accuracy: 0.0001)
        XCTAssertEqual(data.authorBioOffsetYInches, -1.5, accuracy: 0.0001)
        XCTAssertEqual(data.authorBioWidthInches, 3.25, accuracy: 0.0001)
        XCTAssertEqual(data.authorPhotoOffsetXInches, -0.25, accuracy: 0.0001)
    }

    func testSavingHardcoverUpdatesBindingSpecificBackKeys() throws {
        let coverURL = try makeCoverFile(contents: """
        ---
        schema_version: 1
        binding_type: hc
        title: Back Cover
        hc_back_blurb_offset_x_inches: 0
        hc_back_blurb_width_inches: 0
        hc_back_quote_offset_y_inches: 0
        hc_back_author_bio_offset_y_inches: 0
        hc_back_author_bio_width_inches: 0
        hc_back_author_image_offset_y_inches: 0
        ---
        """)

        var data = try ProjectManager.load(from: coverURL)
        data.blurbOffsetXInches = 0.3
        data.blurbWidthInches = 4.1
        data.quoteOffsetYInches = 0.45
        data.authorBioOffsetYInches = -1.2
        data.authorBioWidthInches = 3.4
        data.authorPhotoOffsetYInches = 0.6
        data.authorPhotoShape = .raw
        try ProjectManager.save(data, to: coverURL)

        let saved = try savedFrontmatterMap(from: coverURL)
        XCTAssertEqual(try numericValue(saved, "hc_back_blurb_offset_x_inches"), 0.3, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_back_blurb_width_inches"), 4.1, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_back_quote_offset_y_inches"), 0.45, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_back_author_bio_offset_y_inches"), -1.2, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_back_author_bio_width_inches"), 3.4, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_back_author_image_offset_y_inches"), 0.6, accuracy: 0.0001)
        XCTAssertEqual(saved["author_photo_shape"] as? String, "raw")
    }

    func testResetDefaultLocationsRestoresAllLayoutOffsetsAndSizes() {
        var data = CoverData()
        data.frontCoverImageOffsetXInches = 0.12
        data.frontTitleOffsetYInches = -0.2
        data.frontSubtitleOffsetYInches = 0.3
        data.frontSubtitleScale = 1.6
        data.frontAuthorOffsetXInches = 0.1
        data.hcFrontTitleOffsetXInches = 0.4
        data.hcFrontSubtitleScale = 0.7
        data.hcFrontAuthorOffsetYInches = -0.15
        data.spineTextOffsetInches = 0.05
        data.spineColorExtensionInches = 0.7
        data.spineTitleOffsetYInches = 0.25
        data.blurbOffsetYInches = 0.5
        data.quoteAttributionOffsetXInches = -0.1
        data.authorBioOffsetYInches = -0.25
        data.authorBioParagraphGapPoints = 14.0
        data.authorPhotoScaleInches = 2.0
        data.authorPhotoOffsetXInches = 0.3

        data.applyDefaultLocations()

        XCTAssertEqual(data.frontCoverImageOffsetXInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.frontTitleOffsetYInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.frontSubtitleOffsetYInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.frontSubtitleScale, 1.0, accuracy: 0.0001)
        XCTAssertEqual(data.frontAuthorOffsetXInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.hcFrontTitleOffsetXInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.hcFrontSubtitleScale, 1.0, accuracy: 0.0001)
        XCTAssertEqual(data.hcFrontAuthorOffsetYInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.spineTextOffsetInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.spineColorExtensionInches, CoverLayoutDefaults.spineColorExtensionInches, accuracy: 0.0001)
        XCTAssertEqual(data.spineTitleOffsetYInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.blurbOffsetYInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.quoteAttributionOffsetXInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.authorBioOffsetYInches, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.authorBioParagraphGapPoints, CoverLayoutDefaults.backAuthorBioParagraphGapPoints, accuracy: 0.0001)
        XCTAssertEqual(data.authorPhotoScaleInches, CoverLayoutDefaults.backAuthorPhotoSizeInches, accuracy: 0.0001)
        XCTAssertEqual(data.authorPhotoOffsetXInches, 0.0, accuracy: 0.0001)
    }

    func testRendererUsesConfiguredTitleColor() throws {
        var data = CoverData()
        data.bindingType = .pb
        data.trimSize = .sixX9
        data.pageCount = 200
        data.frontText = true
        data.title = "TEST"
        data.colorTitle = "#ff0000"

        let geometry = try computeGeometry(from: data)
        let renderer = CoverRenderer(data: data, geometry: geometry)
        guard let image = renderer.renderFullCover(includeGuides: false) else {
            XCTFail("Expected rendered cover image")
            return
        }

        let frontLeft = geometry.effectiveFrontLeft
        let frontRight = geometry.effectiveFrontRight
        let sampleRect = CGRect(
            x: frontLeft,
            y: 0,
            width: frontRight - frontLeft,
            height: image.height
        )

        let pixels = try pixels(in: sampleRect, from: image)
        XCTAssertTrue(
            pixels.contains { pixel in pixel.red > 180 && pixel.green < 80 && pixel.blue < 80 },
            "Rendered title should contain pixels matching the configured red title color."
        )
    }

    func testRendererFrontCropUsesFullFrontPanel() throws {
        var data = CoverData()
        data.bindingType = .hc
        data.trimSize = .sixX9
        data.templateFullCoverWidth = 13.996
        data.templateFullCoverHeight = 10.417
        data.templateFrontCoverWidth = 6.197
        data.templateFrontCoverHeight = 9.236
        data.templateSpineWidth = 0.421
        data.templateHingeWidth = 0.394
        data.templateWrapWidth = 0.591

        let geometry = try computeGeometry(from: data)
        let renderer = CoverRenderer(data: data, geometry: geometry)
        guard let crop = renderer.renderFrontCrop() else {
            XCTFail("Expected front crop image")
            return
        }

        XCTAssertEqual(crop.width, geometry.totalWidth - geometry.spineRight)
        XCTAssertEqual(crop.height, geometry.frontHeight)
    }

    private func makeCoverFile(contents: String) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoverStudioTests-\(UUID().uuidString)", isDirectory: true)
        temporaryRoots.append(root)

        let coverDirectory = root.appendingPathComponent("cover", isDirectory: true)
        try FileManager.default.createDirectory(at: coverDirectory, withIntermediateDirectories: true)
        let coverURL = coverDirectory.appendingPathComponent("cover.md")
        try contents.write(to: coverURL, atomically: true, encoding: .utf8)
        return coverURL
    }

    private func savedFrontmatterMap(from url: URL) throws -> [String: Any] {
        let saved = try String(contentsOf: url, encoding: .utf8)
        let bodyStart = saved.index(saved.startIndex, offsetBy: 4)
        guard saved.hasPrefix("---\n"),
              let closingRange = saved[bodyStart...].range(of: "\n---"),
              let map = try Yams.load(yaml: String(saved[bodyStart..<closingRange.lowerBound])) as? [String: Any] else {
            XCTFail("Saved Markdown frontmatter could not be parsed")
            return [:]
        }
        return map
    }

    private func numericValue(_ map: [String: Any], _ key: String) throws -> Double {
        if let value = map[key] as? Double { return value }
        if let value = map[key] as? Int { return Double(value) }
        if let value = map[key] as? String, let number = Double(value) { return number }
        XCTFail("Missing numeric value for \(key)")
        return .nan
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
        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            XCTFail("Could not allocate bitmap context")
            return []
        }

        context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 0, to: bytes.count, by: 4).map { offset in
            Pixel(red: bytes[offset], green: bytes[offset + 1], blue: bytes[offset + 2])
        }
    }
}
