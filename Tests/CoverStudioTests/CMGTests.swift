import Foundation
import XCTest
@testable import CoverStudio

final class CMGTests: XCTestCase {

    private var tempURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("cmg")
    }

    func testCMGRoundTripPreservesAllFields() throws {
        var original = CoverData()
        original.title           = "The Long Dark"
        original.authorName      = "Jane Doe"
        original.subtitle        = "A Novel"
        original.bindingType     = .hc
        original.pbPageCount     = 312
        original.colorTitle      = "#FF3300"
        original.frontTitleScale = 1.25
        original.frontText       = false

        let url = tempURL
        defer { try? FileManager.default.removeItem(at: url) }

        try ProjectManager.save(original, to: url)
        let loaded = try ProjectManager.load(from: url)

        XCTAssertEqual(loaded.title,           original.title)
        XCTAssertEqual(loaded.authorName,      original.authorName)
        XCTAssertEqual(loaded.subtitle,        original.subtitle)
        XCTAssertEqual(loaded.bindingType,     original.bindingType)
        XCTAssertEqual(loaded.pbPageCount,     original.pbPageCount)
        XCTAssertEqual(loaded.colorTitle,      original.colorTitle)
        XCTAssertEqual(loaded.frontTitleScale, original.frontTitleScale)
        XCTAssertEqual(loaded.frontText,       original.frontText)
    }

    func testCMGProducesBinaryPlistMagicBytes() throws {
        let url = tempURL
        defer { try? FileManager.default.removeItem(at: url) }

        try ProjectManager.save(CoverData(), to: url)

        let raw = try Data(contentsOf: url)
        // Binary plist files begin with the ASCII bytes "bplist"
        let magic = String(bytes: raw.prefix(6), encoding: .ascii)
        XCTAssertEqual(magic, "bplist")
    }

    func testCMGThrowsOnCorruptData() throws {
        let url = tempURL
        defer { try? FileManager.default.removeItem(at: url) }

        // Write garbage bytes that are not a valid binary plist
        try Data([0xDE, 0xAD, 0xBE, 0xEF]).write(to: url)

        XCTAssertThrowsError(try ProjectManager.load(from: url))
    }

    func testCMGIsIncludedInCoverContentTypes() {
        let extensions = ProjectManager.coverContentTypes.compactMap { $0.preferredFilenameExtension }
        XCTAssertTrue(extensions.contains("cmg"), "coverContentTypes should include .cmg")
    }
}
