import Foundation
import XCTest
@testable import CoverStudio

final class ValidationTests: XCTestCase {
    private var temporaryRoots: [URL] = []

    override func tearDownWithError() throws {
        for root in temporaryRoots {
            try? FileManager.default.removeItem(at: root)
        }
        temporaryRoots.removeAll()
        try super.tearDownWithError()
    }

    // MARK: - Front cover image path resolution

    func testValidationPassesWhenFrontImageExistsAtResolvedPath() throws {
        let (coverURL, imageURL) = try makeCoverProjectWithImage()
        var data = CoverData()
        data.frontCoverImage = "cover/assets/base.png"
        data.pbPageCount = 200
        data.blurb = "A blurb."

        // Create the image file so it resolves
        try Data().write(to: imageURL)

        let issues = Validation.validate(data, sourceURL: coverURL)
        let imageErrors = issues.filter { $0.field == "front_cover_image" && $0.severity == .error }
        XCTAssertTrue(imageErrors.isEmpty, "Should not report missing image when file exists at resolved path")
    }

    func testValidationFailsWhenFrontImageMissing() throws {
        let (coverURL, _) = try makeCoverProjectWithImage()
        var data = CoverData()
        data.frontCoverImage = "cover/assets/base.png"
        data.pbPageCount = 200

        // Do NOT create the image file
        let issues = Validation.validate(data, sourceURL: coverURL)
        let imageErrors = issues.filter { $0.field == "front_cover_image" && $0.severity == .error }
        XCTAssertFalse(imageErrors.isEmpty, "Should report error when relative image path does not resolve to an existing file")
    }

    func testValidationReportsErrorForAbsoluteMissingImage() {
        var data = CoverData()
        data.frontCoverImage = "/nonexistent/path/cover.png"
        data.pbPageCount = 200

        let issues = Validation.validate(data)
        let imageErrors = issues.filter { $0.field == "front_cover_image" && $0.severity == .error }
        XCTAssertFalse(imageErrors.isEmpty)
    }

    func testValidationReportsErrorWhenFrontImageEmpty() {
        var data = CoverData()
        data.frontCoverImage = ""
        data.pbPageCount = 200

        let issues = Validation.validate(data)
        let imageErrors = issues.filter { $0.field == "front_cover_image" }
        XCTAssertFalse(imageErrors.isEmpty)
    }

    // MARK: - Colors

    func testValidationAcceptsValidHexColors() {
        var data = CoverData()
        data.pbPageCount = 200
        data.colorTitle  = "#daa520"
        data.colorAccent = "#ffffff"
        data.colorBody   = "#cccccc"
        data.colorSoft   = "#888888"

        let issues = Validation.validate(data)
        let colorErrors = issues.filter {
            ["color_title", "color_accent", "color_body", "color_soft"].contains($0.field) && $0.severity == .error
        }
        XCTAssertTrue(colorErrors.isEmpty)
    }

    func testValidationRejectsInvalidHexColor() {
        var data = CoverData()
        data.pbPageCount = 200
        data.colorTitle = "not-a-color"

        let issues = Validation.validate(data)
        let colorErrors = issues.filter { $0.field == "color_title" && $0.severity == .error }
        XCTAssertFalse(colorErrors.isEmpty)
    }

    func testValidationAcceptsHexColorWithoutHash() {
        var data = CoverData()
        data.pbPageCount = 200
        data.colorTitle = "daa520"

        let issues = Validation.validate(data)
        let colorErrors = issues.filter { $0.field == "color_title" && $0.severity == .error }
        XCTAssertTrue(colorErrors.isEmpty)
    }

    // MARK: - Page count

    func testValidationRejectsPageCountBelowMinimum() {
        var data = CoverData()
        data.pbPageCount = 10

        let issues = Validation.validate(data)
        XCTAssertTrue(issues.contains { $0.field == "page_count" && $0.severity == .error })
    }

    func testValidationPassesMinimumPageCount() {
        var data = CoverData()
        data.pbPageCount = 24

        let issues = Validation.validate(data)
        XCTAssertFalse(issues.contains { $0.field == "page_count" && $0.severity == .error })
    }

    // MARK: - Hardcover template

    func testValidationRequiresTemplateDimensionsForHardcover() {
        var data = CoverData()
        data.bindingType = .hc
        data.hcPageCount = 200

        let issues = Validation.validate(data)
        let templateErrors = issues.filter {
            $0.field.hasPrefix("template_") && $0.severity == .error
        }
        XCTAssertEqual(templateErrors.count, 7, "All 7 template fields should be flagged when missing for HC")
    }

    func testValidationPassesHardcoverWithAllTemplateFields() {
        var data = CoverData()
        data.bindingType = .hc
        data.hcPageCount = 200
        data.templateFullCoverWidth  = 13.996
        data.templateFullCoverHeight = 10.417
        data.templateFrontCoverWidth = 6.197
        data.templateFrontCoverHeight = 9.236
        data.templateSpineWidth = 0.421
        data.templateHingeWidth = 0.394
        data.templateWrapWidth  = 0.591

        let issues = Validation.validate(data)
        let templateErrors = issues.filter {
            $0.field.hasPrefix("template_") && $0.severity == .error
        }
        XCTAssertTrue(templateErrors.isEmpty)
    }

    // MARK: - Helpers

    private func makeCoverProjectWithImage() throws -> (coverURL: URL, imageURL: URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ValidationTests-\(UUID().uuidString)", isDirectory: true)
        temporaryRoots.append(root)

        let coverDir = root.appendingPathComponent("cover", isDirectory: true)
        let assetsDir = coverDir.appendingPathComponent("assets", isDirectory: true)
        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)

        let coverURL = coverDir.appendingPathComponent("cover.md")
        try "---\nschema_version: 1\n---\n".write(to: coverURL, atomically: true, encoding: .utf8)

        let imageURL = assetsDir.appendingPathComponent("base.png")
        return (coverURL, imageURL)
    }
}
