import Foundation
import XCTest
@testable import CoverStudio

final class GeometryTests: XCTestCase {

    // MARK: - Paperback

    func testPaperbackGeometryDimensions() throws {
        var data = CoverData()
        data.bindingType   = .pb
        data.trimSize      = .sixX9
        data.pbPageCount   = 200
        data.interiorType  = .blackWhite
        data.paperType     = .white

        let g = try computeGeometry(from: data)

        XCTAssertEqual(g.frontWidth,  CoverGeometry.px(6.0))
        XCTAssertEqual(g.frontHeight, CoverGeometry.px(9.0))
        XCTAssertEqual(g.bleed,       CoverGeometry.px(0.125))
        XCTAssertEqual(g.spineWidth,  CoverGeometry.px(200.0 * 0.002252))

        // totalWidth and totalHeight are computed from the sum of all inches then rounded once,
        // so independent component sums can differ by ±1 px. Test the total-inches path directly.
        XCTAssertEqual(g.totalWidth,  CoverGeometry.px(2 * 0.125 + 6.0 + 6.0 + 200.0 * 0.002252))
        XCTAssertEqual(g.totalHeight, CoverGeometry.px(2 * 0.125 + 9.0))
    }

    func testPaperbackPanelLayout() throws {
        var data = CoverData()
        data.bindingType = .pb
        data.trimSize    = .sixX9
        data.pbPageCount = 200

        let g = try computeGeometry(from: data)

        // Panel adjacency: back | spine | front
        XCTAssertEqual(g.spineLeft,  g.backRight)
        XCTAssertEqual(g.spineRight, g.frontLeft)

        // No hinge for paperback
        XCTAssertEqual(g.hinge, 0)

        // LTR: back is on the left, front on the right
        XCTAssertLessThan(g.effectiveBackLeft, g.effectiveFrontLeft)
    }

    func testPaperbackRTLSwapsBackAndFront() throws {
        var data = CoverData()
        data.bindingType      = .pb
        data.trimSize         = .sixX9
        data.pbPageCount      = 200
        data.readingDirection = .rtl

        let g = try computeGeometry(from: data)

        XCTAssertEqual(g.effectiveFrontLeft, g.backLeft)
        XCTAssertEqual(g.effectiveBackLeft,  g.frontLeft)
    }

    func testCustomSpineOverridesCalculated() throws {
        var data = CoverData()
        data.bindingType           = .pb
        data.trimSize              = .sixX9
        data.pbPageCount           = 200
        data.customSpineWidthInches = 0.5

        let g = try computeGeometry(from: data)
        XCTAssertEqual(g.spineWidth, CoverGeometry.px(0.5))
    }

    func testCustomTrimGeometry() throws {
        var data = CoverData()
        data.bindingType              = .pb
        data.trimSize                 = .custom
        data.customTrimWidthInches    = 5.5
        data.customTrimHeightInches   = 8.5
        data.customBleedInches        = 0.125
        data.customSafeMarginInches   = 0.375
        data.pbPageCount              = 300

        let g = try computeGeometry(from: data)
        XCTAssertEqual(g.frontWidth,  CoverGeometry.px(5.5))
        XCTAssertEqual(g.frontHeight, CoverGeometry.px(8.5))
    }

    // MARK: - Hardcover

    func testHardcoverGeometryUsesTemplateFields() throws {
        var data = CoverData()
        data.bindingType              = .hc
        data.templateFullCoverWidth   = 13.996
        data.templateFullCoverHeight  = 10.417
        data.templateFrontCoverWidth  = 6.197
        data.templateFrontCoverHeight = 9.236
        data.templateSpineWidth       = 0.421
        data.templateHingeWidth       = 0.394
        data.templateWrapWidth        = 0.591

        let g = try computeGeometry(from: data)

        XCTAssertEqual(g.totalWidth,  CoverGeometry.px(13.996))
        XCTAssertEqual(g.totalHeight, CoverGeometry.px(10.417))
        XCTAssertEqual(g.frontWidth,  CoverGeometry.px(6.197))
        XCTAssertEqual(g.frontHeight, CoverGeometry.px(9.236))
        XCTAssertEqual(g.spineWidth,  CoverGeometry.px(0.421))
        XCTAssertEqual(g.hinge,       CoverGeometry.px(0.394))
        XCTAssertEqual(g.wrap,        CoverGeometry.px(0.591))
        XCTAssertEqual(g.bleed,       0)
    }

    // MARK: - Error cases

    func testGeometryThrowsForZeroCustomTrimWidth() {
        var data = CoverData()
        data.bindingType           = .pb
        data.trimSize              = .custom
        data.customTrimWidthInches = 0
        data.customTrimHeightInches = 9

        XCTAssertThrowsError(try computeGeometry(from: data)) { error in
            guard let gErr = error as? GeometryError,
                  case .customTrimMustBePositive = gErr else {
                XCTFail("Expected GeometryError.customTrimMustBePositive, got \(error)")
                return
            }
        }
    }

    func testGeometryThrowsForMissingHardcoverTemplate() {
        var data = CoverData()
        data.bindingType = .hc

        XCTAssertThrowsError(try computeGeometry(from: data)) { error in
            guard let gErr = error as? GeometryError,
                  case .hardcoverMissingTemplate = gErr else {
                XCTFail("Expected GeometryError.hardcoverMissingTemplate, got \(error)")
                return
            }
        }
    }

    func testGeometryThrowsForUnknownSpineMultiplierCombination() {
        var data = CoverData()
        data.bindingType  = .pb
        data.trimSize     = .sixX9
        data.interiorType = .standardColor
        data.paperType    = .cream   // no multiplier for standardColor + cream

        XCTAssertThrowsError(try computeGeometry(from: data)) { error in
            guard let gErr = error as? GeometryError,
                  case .noSpineMultiplier = gErr else {
                XCTFail("Expected GeometryError.noSpineMultiplier, got \(error)")
                return
            }
        }
    }

    // MARK: - DPI helper

    func testPxHelperRoundsCorrectly() {
        XCTAssertEqual(CoverGeometry.px(1.0),    300)
        XCTAssertEqual(CoverGeometry.px(0.5),    150)
        XCTAssertEqual(CoverGeometry.px(0.125),   38)  // 37.5 rounds to 38
        XCTAssertEqual(CoverGeometry.px(6.0),   1800)
        XCTAssertEqual(CoverGeometry.px(9.0),   2700)
    }
}
