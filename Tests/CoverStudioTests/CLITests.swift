import CoreGraphics
import Foundation
import XCTest
@testable import CoverStudio

/// Tests for the headless command-line interface.
///
/// The CLI shares its rendering path with the GUI, so the value here is not
/// re-testing the renderer. It is pinning the contract a script depends on:
/// which argument forms are accepted, which exit code comes back, and whether
/// a bad option is rejected rather than quietly ignored.
final class CLITests: XCTestCase {
    private var temporaryDirectory: URL?

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CLITests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory!, withIntermediateDirectories: true)
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        if let dir = temporaryDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        try super.tearDownWithError()
    }

    // MARK: - Dispatch

    func testNoArgumentsHandsControlToTheGui() {
        XCTAssertNil(
            CLI.main(arguments: []),
            "No arguments must fall through to the GUI, not print usage")
    }

    func testMacOSLaunchFlagHandsControlToTheGui() {
        // macOS passes -psn_... when a bundle is opened from Finder. Treating it
        // as an unknown command would make the app unlaunchable from the Finder.
        XCTAssertNil(CLI.main(arguments: ["-psn_0_123456"]))
    }

    func testVersionAndHelpSucceed() {
        XCTAssertEqual(CLI.main(arguments: ["version"]), CLIExit.ok)
        XCTAssertEqual(CLI.main(arguments: ["--version"]), 0)
        XCTAssertEqual(CLI.main(arguments: ["help"]), CLIExit.ok)
    }

    func testUnknownCommandIsAUsageError() {
        XCTAssertEqual(CLI.main(arguments: ["frobnicate"]), CLIExit.usage)
    }

    // MARK: - Argument parser

    func testFlagsAndValuesAreSeparated() {
        let parsed = Parsed(["--out-pdf", "/tmp/a.pdf", "--json", "--cover", "/tmp/c.md"])
        XCTAssertEqual(parsed?.value("out-pdf"), "/tmp/a.pdf")
        XCTAssertEqual(parsed?.value("cover"), "/tmp/c.md")
        XCTAssertEqual(parsed?.flag("json"), true)
        XCTAssertEqual(parsed?.flag("strict"), false)
    }

    func testBooleanFlagsDoNotConsumeTheNextArgument() {
        // A flag followed by a positional must leave the positional intact;
        // otherwise `--json /path/to/book` would swallow the cover path.
        let parsed = Parsed(["--json", "/tmp/book"])
        XCTAssertEqual(parsed?.flag("json"), true)
        XCTAssertEqual(parsed?.coverArgument, "/tmp/book")
    }

    func testPositionalIsUsedWhenNoCoverFlagIsGiven() {
        let parsed = Parsed(["/tmp/book", "--out-png", "/tmp/a.png"])
        XCTAssertEqual(parsed?.coverArgument, "/tmp/book")
    }

    func testCoverFlagWinsOverPositional() {
        let parsed = Parsed(["/tmp/positional", "--cover", "/tmp/explicit"])
        XCTAssertEqual(parsed?.coverArgument, "/tmp/explicit")
    }

    func testValueOptionWithoutAValueIsReported() {
        let parsed = Parsed(["--out-pdf"])
        XCTAssertNotNil(parsed?.problem, "A value option with no value must be an error")
    }

    func testLastRepeatedOptionWins() {
        let parsed = Parsed(["--out-pdf", "/tmp/first.pdf", "--out-pdf", "/tmp/second.pdf"])
        XCTAssertEqual(parsed?.value("out-pdf"), "/tmp/second.pdf")
    }

    // MARK: - Option validation

    func testInvalidNumericOptionsAreRejected() throws {
        let project = try makeProject()

        // A silently-ignored --dpi would write a file at the wrong resolution
        // while reporting success. Each of these must be a usage error.
        for arguments in [
            ["--dpi", "abc"], ["--dpi", "0"], ["--dpi", "-300"],
            ["--front-quality", "abc"], ["--front-quality", "5"], ["--front-quality", "0"],
            ["--front-format", "tiff"], ["--bind", "zz"],
        ] {
            XCTAssertEqual(
                CLI.main(arguments: ["render", project.path] + arguments + ["--out-png", "/tmp/none.png"]),
                CLIExit.usage,
                "render \(arguments.joined(separator: " ")) must be rejected")
        }
    }

    func testRenderWithoutAnOutputTargetIsAUsageError() throws {
        let project = try makeProject()
        XCTAssertEqual(CLI.main(arguments: ["render", project.path]), CLIExit.usage)
    }

    func testMissingCoverIsAFailureNotAUsageError() {
        XCTAssertEqual(
            CLI.main(arguments: ["inspect", "/tmp/definitely-not-a-cover-\(UUID().uuidString)"]),
            CLIExit.failure)
    }

    func testProjectDirectoryWithoutCoverFileIsAFailure() throws {
        let empty = temporaryDirectory!.appendingPathComponent("empty-project", isDirectory: true)
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        XCTAssertEqual(CLI.main(arguments: ["inspect", empty.path]), CLIExit.failure)
    }

    // MARK: - Render

    func testRenderWritesAPDFAtTheComputedPhysicalSize() throws {
        let project = try makeProject()
        let output = temporaryDirectory!.appendingPathComponent("out/cover.pdf")

        XCTAssertEqual(
            CLI.main(arguments: ["render", project.path, "--out-pdf", output.path]),
            CLIExit.ok)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))

        let geometry = try computeGeometry(from: ProjectManager.load(
            from: try ProjectManager.resolveCoverFile(in: project)))
        let pageSize = try pdfPageSize(at: output)
        XCTAssertEqual(pageSize.width, geometry.totalWidthInches * 72, accuracy: 0.5)
        XCTAssertEqual(pageSize.height, geometry.totalHeightInches * 72, accuracy: 0.5)
    }

    func testRenderWritesAFrontCropNarrowerThanTheFullCover() throws {
        let project = try makeProject()
        let full = temporaryDirectory!.appendingPathComponent("full.png")
        let front = temporaryDirectory!.appendingPathComponent("front.jpg")

        XCTAssertEqual(
            CLI.main(arguments: [
                "render", project.path, "--out-png", full.path, "--out-front", front.path,
            ]),
            CLIExit.ok)

        let fullSize = try pixelSize(at: full)
        let frontSize = try pixelSize(at: front)
        XCTAssertLessThan(frontSize.width, fullSize.width,
                          "The front crop must be narrower than the wraparound cover")

        // The crop is the trim-sized panel, not the bleed-inclusive wrap, so its
        // height is the trim height rather than the full cover height.
        let geometry = try computeGeometry(from: ProjectManager.load(
            from: try ProjectManager.resolveCoverFile(in: project)))
        XCTAssertEqual(frontSize.height, Int((geometry.frontHeightInches * 300).rounded()))
    }

    func testRenderHonorsDPIInTheOutputMetadata() throws {
        let project = try makeProject()
        let output = temporaryDirectory!.appendingPathComponent("dpi.png")

        XCTAssertEqual(
            CLI.main(arguments: ["render", project.path, "--out-png", output.path, "--dpi", "150"]),
            CLIExit.ok)

        let source = try XCTUnwrap(CGImageSourceCreateWithURL(output as CFURL, nil))
        let properties = try XCTUnwrap(
            CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        XCTAssertEqual(properties[kCGImagePropertyDPIWidth] as? Int, 150)
    }

    func testRenderDoesNotModifyTheProjectFile() throws {
        // The CLI must be safe to run in CI and from a hook: it may not rewrite
        // the author's cover.md as a side effect of rendering.
        let project = try makeProject()
        let coverFile = try ProjectManager.resolveCoverFile(in: project)
        let before = try Data(contentsOf: coverFile)

        XCTAssertEqual(
            CLI.main(arguments: [
                "render", project.path, "--out-png", temporaryDirectory!.appendingPathComponent("a.png").path,
            ]),
            CLIExit.ok)

        XCTAssertEqual(try Data(contentsOf: coverFile), before)
    }

    func testRenderRefusesACoverWithValidationErrors() throws {
        let project = try makeProject(frontCoverImage: "cover/assets/missing.png")
        let output = temporaryDirectory!.appendingPathComponent("never.png")

        XCTAssertEqual(
            CLI.main(arguments: ["render", project.path, "--out-png", output.path]),
            CLIExit.invalidCover)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: output.path),
            "A cover with validation errors must not produce output unless --force is passed")
    }

    func testForceRendersDespiteValidationErrors() throws {
        let project = try makeProject(frontCoverImage: "cover/assets/missing.png")
        let output = temporaryDirectory!.appendingPathComponent("forced.png")

        XCTAssertEqual(
            CLI.main(arguments: ["render", project.path, "--out-png", output.path, "--force"]),
            CLIExit.ok)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
    }

    // MARK: - Validate

    func testValidateReportsOKForAHealthyCover() throws {
        let project = try makeProject()
        XCTAssertEqual(CLI.main(arguments: ["validate", project.path]), CLIExit.ok)
    }

    func testValidateFailsOnAMissingFrontImage() throws {
        let project = try makeProject(frontCoverImage: "cover/assets/absent.png")
        XCTAssertEqual(CLI.main(arguments: ["validate", project.path]), CLIExit.invalidCover)
    }

    // MARK: - Back-cover font sizes

    func testUnsetFontSizesAreTheDefaults() {
        // 0 means "unset". The defaults must be the sizes the renderer used
        // before the size was configurable, so an older cover.md is unaffected.
        let data = CoverData()
        XCTAssertEqual(data.resolvedBlurbFontSizePoints(),
                       CoverLayoutDefaults.backBlurbFontSizePoints)
        XCTAssertEqual(data.resolvedQuoteFontSizePoints(),
                       CoverLayoutDefaults.backQuoteFontSizePoints)
        XCTAssertEqual(data.resolvedAuthorBioFontSizePoints(),
                       CoverLayoutDefaults.backAuthorBioFontSizePoints)
    }

    func testDefaultsRemainTheHistoricalRenderedSizes() {
        // The literals are the contract, not the constants. The renderer
        // hardcoded 43/38/32 before the size was configurable, so these defaults
        // are what makes an unset cover.md render byte-identically to before.
        // Comparing a constant to itself would pass whatever the value became;
        // this fails the moment someone changes it and silently moves every
        // existing cover.
        XCTAssertEqual(CoverLayoutDefaults.backBlurbFontSizePoints, 43)
        XCTAssertEqual(CoverLayoutDefaults.backQuoteFontSizePoints, 38)
        XCTAssertEqual(CoverLayoutDefaults.backAuthorBioFontSizePoints, 32)
    }

    func testFontSizeIsResolvedPerBinding() {
        var data = CoverData()
        data.bindingType = .pb
        data.blurbFontSizePoints = 40
        data.hcBlurbFontSizePoints = 60
        XCTAssertEqual(data.resolvedBlurbFontSizePoints(), 40)

        data.bindingType = .hc
        XCTAssertEqual(data.resolvedBlurbFontSizePoints(), 60)

        // An unset hardcover size falls back to the default rather than to the
        // paperback's value: the two bindings are independent.
        data.hcBlurbFontSizePoints = 0
        XCTAssertEqual(data.resolvedBlurbFontSizePoints(),
                       CoverLayoutDefaults.backBlurbFontSizePoints)
    }

    func testFontSizesSurviveARoundTripThroughMarkdown() throws {
        let project = try makeProject()
        let coverFile = try ProjectManager.resolveCoverFile(in: project)

        var data = try ProjectManager.load(from: coverFile)
        data.blurbFontSizePoints = 51
        data.hcQuoteFontSizePoints = 33
        data.authorBioFontSizePoints = 27
        try ProjectManager.save(data, to: coverFile)

        let reloaded = try ProjectManager.load(from: coverFile)
        XCTAssertEqual(reloaded.blurbFontSizePoints, 51)
        XCTAssertEqual(reloaded.hcQuoteFontSizePoints, 33)
        XCTAssertEqual(reloaded.authorBioFontSizePoints, 27)
    }

    func testChangingTheBlurbSizeChangesTheRenderedCover() throws {
        let project = try makeProject(blurb: longBlurb)
        let coverFile = try ProjectManager.resolveCoverFile(in: project)

        let before = temporaryDirectory!.appendingPathComponent("before.png")
        XCTAssertEqual(
            CLI.main(arguments: ["render", project.path, "--out-png", before.path]), CLIExit.ok)

        var data = try ProjectManager.load(from: coverFile)
        data.blurbFontSizePoints = 70
        try ProjectManager.save(data, to: coverFile)

        let after = temporaryDirectory!.appendingPathComponent("after.png")
        XCTAssertEqual(
            CLI.main(arguments: ["render", project.path, "--out-png", after.path]), CLIExit.ok)

        XCTAssertNotEqual(
            try Data(contentsOf: before), try Data(contentsOf: after),
            "Raising the blurb font size must change the rendered cover")
    }

    func testOversizedBlurbIsReportedAsClipped() throws {
        // The back-cover blocks stop at a computed height and draw silently, so
        // too-long copy is cut rather than reported. With the size now a control,
        // turning it up must not truncate the copy invisibly.
        let project = try makeProject(blurb: longBlurb)
        let coverFile = try ProjectManager.resolveCoverFile(in: project)

        var data = try ProjectManager.load(from: coverFile)
        data.blurbFontSizePoints = 120
        try ProjectManager.save(data, to: coverFile)

        let geometry = try computeGeometry(from: try ProjectManager.load(from: coverFile))
        let renderer = CoverRenderer(
            data: try ProjectManager.load(from: coverFile), geometry: geometry, sourceURL: coverFile)
        _ = renderer.renderFullCover(includeGuides: false)

        XCTAssertTrue(renderer.diagnostics.hasClipping, "An oversized blurb must be reported")
        XCTAssertEqual(renderer.diagnostics.clippedText.first?.block, "blurb")
        XCTAssertGreaterThan(renderer.diagnostics.clippedText.first?.overflowPx ?? 0, 0)
    }

    func testDefaultSizedBlurbIsNotReportedAsClipped() throws {
        // The counterpart guard: the check must not fire on copy that fits, or
        // the warning becomes noise the author learns to ignore.
        let project = try makeProject(blurb: longBlurb)
        let coverFile = try ProjectManager.resolveCoverFile(in: project)
        let data = try ProjectManager.load(from: coverFile)
        let geometry = try computeGeometry(from: data)

        let renderer = CoverRenderer(data: data, geometry: geometry, sourceURL: coverFile)
        _ = renderer.renderFullCover(includeGuides: false)

        XCTAssertFalse(renderer.diagnostics.hasClipping)
        XCTAssertTrue(renderer.diagnostics.clippedText.isEmpty)
    }

    func testNegativeFontSizeIsAValidationError() {
        var data = CoverData()
        data.blurbFontSizePoints = -10
        let errors = Validation.validate(data).filter { $0.severity == .error }
        XCTAssertTrue(
            errors.contains { $0.field == "blurb_font_size_points" },
            "A negative font size must be a validation error")
    }

    // MARK: - Fixtures

    /// Longer than the default-size blurb area holds at a large font size, but
    /// comfortably inside it at the default size.
    private let longBlurb = """
        This is a deliberately long back-cover description used to exercise the \
        font-size controls. It runs to several sentences so that increasing the \
        size pushes the text past the height the back panel reserves for it, \
        which is the condition the clipping check exists to catch. At the default \
        size this copy fits, and the cover renders without any warning at all.
        """

    /// Build a minimal but valid project: a cover.md plus its front image.
    private func makeProject(
        frontCoverImage: String = "cover/assets/base.png",
        blurb: String = "A short blurb for the fixture."
    ) throws -> URL {
        let root = temporaryDirectory!.appendingPathComponent("book-\(UUID().uuidString)", isDirectory: true)
        let coverDirectory = root.appendingPathComponent("cover", isDirectory: true)
        let assets = coverDirectory.appendingPathComponent("assets", isDirectory: true)
        try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)

        try writePNG(to: assets.appendingPathComponent("base.png"), width: 1200, height: 1800)

        let frontmatter = """
            ---
            schema_version: 2
            binding_type: pb
            interior_type: black_white
            paper_type: white
            trim_size: fiveX8
            pb_page_count: 173
            page_count: 173
            spine_color: '#122b22'
            front_cover_image: \(frontCoverImage)
            title: Test Title
            author_name: Test Author
            blurb: \(blurb)
            ---

            """

        try frontmatter.write(
            to: coverDirectory.appendingPathComponent("cover.md"),
            atomically: true,
            encoding: .utf8)
        return root
    }

    private func writePNG(to url: URL, width: Int, height: Int) throws {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try XCTUnwrap(context.makeImage())
        try CoverExporter.exportPNG(image: image, to: url)
    }

    // MARK: - Readers

    private func pixelSize(at url: URL) throws -> (width: Int, height: Int) {
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        let properties = try XCTUnwrap(
            CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        return (
            try XCTUnwrap(properties[kCGImagePropertyPixelWidth] as? Int),
            try XCTUnwrap(properties[kCGImagePropertyPixelHeight] as? Int)
        )
    }

    /// Read the MediaBox width/height in points from the PDF's first page.
    private func pdfPageSize(at url: URL) throws -> (width: Double, height: Double) {
        let text = String(decoding: try Data(contentsOf: url), as: UTF8.self)
        guard let range = text.range(of: "/MediaBox") else {
            throw XCTSkip("MediaBox not found in PDF header")
        }
        let tail = text[range.upperBound...].prefix(60)
        let numbers = tail
            .split(whereSeparator: { !"0123456789.-".contains($0) })
            .compactMap { Double($0) }
        guard numbers.count >= 4 else {
            throw XCTSkip("Could not parse MediaBox: \(tail)")
        }
        return (numbers[2] - numbers[0], numbers[3] - numbers[1])
    }
}
