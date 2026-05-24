import Foundation
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
        hc_spine_title_offset_x_inches: 0.025
        back_author_bio_paragraph_gap_points: 10
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
        XCTAssertEqual(data.frontCoverImage, "cover/assets/base.png")
        XCTAssertFalse(data.frontText)
        XCTAssertEqual(data.resolvedImageOffsetX(), 0.18, accuracy: 0.0001)
        XCTAssertEqual(data.spineTitleOffsetXInches, 0.025, accuracy: 0.0001)
        XCTAssertEqual(data.authorPhotoScaleInches, 1.18, accuracy: 0.0001)
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
        data.hcFrontSubtitleOffsetYInches = 0.08
        data.hcFrontAuthorOffsetYInches = -0.3
        try ProjectManager.save(data, to: coverURL)

        let saved = try savedFrontmatterMap(from: coverURL)
        XCTAssertEqual(try numericValue(saved, "hc_front_image_offset_x_inches"), 0.22, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_front_title_offset_x_inches"), -0.35, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_front_subtitle_offset_y_inches"), 0.08, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "hc_front_author_offset_y_inches"), -0.3, accuracy: 0.0001)
        XCTAssertEqual(try numericValue(saved, "pb_front_title_offset_x_inches"), 0.05, accuracy: 0.0001)
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
}
