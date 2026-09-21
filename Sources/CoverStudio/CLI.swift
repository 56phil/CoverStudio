import Foundation
import CoreGraphics

// Headless command-line interface.
//
// The GUI and the CLI render through the same code path — ProjectManager to read
// cover.md, computeGeometry for the layout, CoverRenderer for the pixels, and
// CoverExporter to write files. Nothing here re-implements layout, so a cover
// rendered headless is the cover the window would have shown.
//
// The CLI reads the project and writes only the paths the caller names. It does
// not save cover.md, so running it cannot rewrite a project file behind the
// author's back.

enum CLIExit {
  static let ok: Int32 = 0
  static let usage: Int32 = 1
  static let invalidCover: Int32 = 2
  static let failure: Int32 = 3
}

/// Kept in step with `CFBundleShortVersionString` in Resources/Info.plist and the
/// `VERSION` default in build-app.sh, so `--version` and the bundle agree.
let coverStudioVersion = "0.1.0"

enum CLI {

  static let usageText = """
    CoverStudio — headless cover rendering.

    Usage:
      CoverStudio render   <cover.md|project-dir> [options]
      CoverStudio validate <cover.md|project-dir> [options]
      CoverStudio inspect  <cover.md|project-dir> [options]
      CoverStudio help
      CoverStudio version

    Running with no arguments opens the app window, so this tool is a drop-in
    replacement for the GUI in scripts and CI.

    Common options:
      --cover <path>        Cover file or book project directory. May be given
                            instead of the positional argument.
      --json                Emit machine-readable JSON on stdout.
      -h, --help            Show this help.
      -V, --version         Show the version.

    render options:
      --out-pdf <path>      Write the full wraparound cover as PDF.
      --out-png <path>      Write the full wraparound cover as PNG.
      --out-front <path>    Write the front-cover crop.
      --front-format <fmt>  jpg (default) or png for --out-front.
      --front-quality <q>   JPEG quality 0.0-1.0 for --out-front (default 0.95).
      --dpi <n>             DPI recorded in PNG/JPEG output (default 300).
      --bind <pb|hc>        Override binding_type for this run only.
      --guides              Draw trim/spine guide lines into the output.
      --no-fit              Skip regenerating the <base>-fitted.png front image.
      --force               Render even when validation reports errors.

    validate options:
      --strict              Treat warnings as failures too.

    Exit codes:
      0  success
      1  usage error
      2  the cover has validation errors
      3  rendering or I/O failed
    """

  /// Returns nil when the process should fall through to the GUI.
  static func main(arguments: [String]) -> Int32? {
    guard let command = arguments.first else { return nil }

    switch command {
    case "version", "--version", "-V":
      print("CoverStudio \(coverStudioVersion)")
      return CLIExit.ok
    case "help", "--help", "-h":
      print(usageText)
      return CLIExit.ok
    default:
      break
    }

    // An unrecognized leading dash is not ours. A macOS launch may pass flags of
    // its own (for example -psn_...), and those must still open the window.
    if command.hasPrefix("-") { return nil }

    let options = Array(arguments.dropFirst())

    switch command {
    case "render":
      return runRender(options)
    case "validate":
      return runValidate(options)
    case "inspect":
      return runInspect(options)
    default:
      FileHandle.standardError.write(Data("Unknown command: \(command)\n\n\(usageText)\n".utf8))
      return CLIExit.usage
    }
  }

  // ── Commands ───────────────────────────────────────

  private static func runRender(_ options: [String]) -> Int32 {
    guard let parsed = Parsed(options) else {
      FileHandle.standardError.write(Data("Could not parse options.\n".utf8))
      return CLIExit.usage
    }
    guard let coverArgument = parsed.coverArgument else {
      FileHandle.standardError.write(Data("render: a cover file or project directory is required.\n".utf8))
      return CLIExit.usage
    }
    if let problem = parsed.problem {
      FileHandle.standardError.write(Data("\(problem)\n".utf8))
      return CLIExit.usage
    }

    let destinations = [parsed.value("out-pdf"), parsed.value("out-png"), parsed.value("out-front")]
      .compactMap { $0 }
    guard !destinations.isEmpty else {
      FileHandle.standardError.write(
        Data("render: name at least one output with --out-pdf, --out-png, or --out-front.\n".utf8))
      return CLIExit.usage
    }

    let frontFormat = (parsed.value("front-format") ?? "jpg").lowercased()
    guard frontFormat == "jpg" || frontFormat == "jpeg" || frontFormat == "png" else {
      FileHandle.standardError.write(Data("render: --front-format must be jpg or png.\n".utf8))
      return CLIExit.usage
    }

    let quality: Double
    if let raw = parsed.value("front-quality") {
      guard let value = Double(raw), value > 0, value <= 1 else {
        FileHandle.standardError.write(Data("render: --front-quality must be between 0 and 1.\n".utf8))
        return CLIExit.usage
      }
      quality = value
    } else {
      quality = 0.95
    }

    let dpi: Int
    if let raw = parsed.value("dpi") {
      guard let value = Int(raw), value > 0 else {
        FileHandle.standardError.write(Data("render: --dpi must be a positive integer.\n".utf8))
        return CLIExit.usage
      }
      dpi = value
    } else {
      dpi = 300
    }

    do {
      let coverURL = try resolveCover(coverArgument)
      var data = try ProjectManager.load(from: coverURL)

      if let binding = parsed.value("bind") {
        guard let parsedBinding = BindingType(rawValue: binding.lowercased()) else {
          FileHandle.standardError.write(Data("render: --bind must be pb or hc.\n".utf8))
          return CLIExit.usage
        }
        data.bindingType = parsedBinding
      }

      // Validation runs before rendering so a broken cover fails loudly rather
      // than producing a plausible image with a missing front art or a bad color.
      let issues = Validation.validate(data, sourceURL: coverURL)
      let errors = issues.filter { $0.severity == .error }
      if !errors.isEmpty, !parsed.flag("force") {
        report(issues, asJSON: false)
        FileHandle.standardError.write(
          Data("render: refusing to render \(errors.count) validation error(s). Pass --force to override.\n".utf8))
        return CLIExit.invalidCover
      }

      let geometry = try computeGeometry(from: data)

      if !parsed.flag("no-fit") {
        FrontImageFitter.updateFittedImage(
          sourcePath: data.frontCoverImage,
          fit: data.frontImageFit,
          panelWidth: geometry.frontImageWidth,
          panelHeight: geometry.totalHeight,
          dpi: dpi,
          relativeTo: coverURL
        )
      }

      let renderer = CoverRenderer(data: data, geometry: geometry, sourceURL: coverURL)
      let includeGuides = parsed.flag("guides")

      var written: [String] = []

      if let pdfPath = parsed.value("out-pdf") {
        guard let full = renderer.renderFullCover(includeGuides: includeGuides) else {
          throw CLIError.renderFailed
        }
        let url = URL(fileURLWithPath: pdfPath)
        try makeParentDirectory(for: url)
        try CoverExporter.exportPDF(
          image: full,
          widthInches: geometry.totalWidthInches,
          heightInches: geometry.totalHeightInches,
          to: url
        )
        written.append(url.path)
      }

      if let pngPath = parsed.value("out-png") {
        guard let full = renderer.renderFullCover(includeGuides: includeGuides) else {
          throw CLIError.renderFailed
        }
        let url = URL(fileURLWithPath: pngPath)
        try makeParentDirectory(for: url)
        try CoverExporter.exportPNG(image: full, dpi: dpi, to: url)
        written.append(url.path)
      }

      if let frontPath = parsed.value("out-front") {
        guard let front = renderer.renderFrontCrop() else {
          throw CLIError.renderFailed
        }
        let url = URL(fileURLWithPath: frontPath)
        try makeParentDirectory(for: url)
        if frontFormat == "png" {
          try CoverExporter.exportPNG(image: front, dpi: dpi, to: url)
        } else {
          try CoverExporter.exportJPG(image: front, dpi: dpi, quality: CGFloat(quality), to: url)
        }
        written.append(url.path)
      }

      if parsed.flag("json") {
        emitJSON([
          "ok": true,
          "cover": coverURL.path,
          "binding": data.bindingType.rawValue,
          "spine_inches": round6(geometry.spineInches),
          "total_width_inches": round6(geometry.totalWidthInches),
          "total_height_inches": round6(geometry.totalHeightInches),
          "outputs": written,
        ])
      } else {
        for path in written { print(path) }
      }
      return CLIExit.ok
    } catch {
      return fail(error)
    }
  }

  private static func runValidate(_ options: [String]) -> Int32 {
    guard let parsed = Parsed(options), let coverArgument = parsed.coverArgument else {
      FileHandle.standardError.write(Data("validate: a cover file or project directory is required.\n".utf8))
      return CLIExit.usage
    }
    do {
      let coverURL = try resolveCover(coverArgument)
      let data = try ProjectManager.load(from: coverURL)
      let issues = Validation.validate(data, sourceURL: coverURL)

      let failed = issues.contains { $0.severity == .error }
        || (parsed.flag("strict") && issues.contains { $0.severity == .warning })

      report(issues, asJSON: parsed.flag("json"))
      return failed ? CLIExit.invalidCover : CLIExit.ok
    } catch {
      return fail(error)
    }
  }

  private static func runInspect(_ options: [String]) -> Int32 {
    guard let parsed = Parsed(options), let coverArgument = parsed.coverArgument else {
      FileHandle.standardError.write(Data("inspect: a cover file or project directory is required.\n".utf8))
      return CLIExit.usage
    }
    do {
      let coverURL = try resolveCover(coverArgument)
      var data = try ProjectManager.load(from: coverURL)
      if let binding = parsed.value("bind") {
        guard let parsedBinding = BindingType(rawValue: binding.lowercased()) else {
          FileHandle.standardError.write(Data("inspect: --bind must be pb or hc.\n".utf8))
          return CLIExit.usage
        }
        data.bindingType = parsedBinding
      }
      let geometry = try computeGeometry(from: data)

      let fields: [(String, Any)] = [
        ("cover", coverURL.path),
        ("schema_version", data.schemaVersion),
        ("binding", data.bindingType.rawValue),
        ("interior", data.interiorType.rawValue),
        ("paper", data.paperType.rawValue),
        ("reading_direction", data.readingDirection.rawValue),
        ("trim_size", data.trimSize.rawValue),
        ("trim_width_inches", round6(geometry.frontWidthInches)),
        ("trim_height_inches", round6(geometry.frontHeightInches)),
        ("pages", data.resolvedPageCount()),
        ("spine_inches", round6(geometry.spineInches)),
        ("bleed_inches", round6(geometry.bleedInches)),
        ("hinge_inches", round6(geometry.hingeInches)),
        ("wrap_inches", round6(geometry.wrapInches)),
        ("total_width_inches", round6(geometry.totalWidthInches)),
        ("total_height_inches", round6(geometry.totalHeightInches)),
        ("total_width_px", geometry.totalWidth),
        ("total_height_px", geometry.totalHeight),
        ("front_panel_px", [geometry.frontImageWidth, geometry.totalHeight]),
        ("spine_color", data.spineColor),
        ("front_cover_image", data.frontCoverImage),
      ]

      if parsed.flag("json") {
        emitJSON(Dictionary(uniqueKeysWithValues: fields))
      } else {
        for (key, value) in fields {
          if let pair = value as? [Int] {
            print("\(key): \(pair[0]) x \(pair[1])")
          } else {
            print("\(key): \(value)")
          }
        }
      }
      return CLIExit.ok
    } catch {
      return fail(error)
    }
  }

  // ── Helpers ────────────────────────────────────────

  private static func resolveCover(_ argument: String) throws -> URL {
    let candidate = URL(fileURLWithPath: argument)
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDirectory) else {
      throw CLIError.coverNotFound(argument)
    }
    if isDirectory.boolValue {
      guard let preferred = ProjectManager.preferredCoverFile(in: candidate) else {
        throw CLIError.noCoverInProject(argument)
      }
      return preferred
    }
    return candidate
  }

  private static func makeParentDirectory(for url: URL) throws {
    let parent = url.deletingLastPathComponent()
    if !parent.path.isEmpty {
      try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
    }
  }

  private static func report(_ issues: [Validation.Issue], asJSON: Bool) {
    if asJSON {
      let payload: [String: Any] = [
        "ok": !issues.contains { $0.severity == .error },
        "issues": issues.map { ["severity": $0.severity.rawValue, "field": $0.field, "message": $0.message] },
      ]
      emitJSON(payload)
    } else if issues.isEmpty {
      print("OK    no issues")
    } else {
      for issue in issues {
        print("\(issue.severity.rawValue.uppercased())  \(issue.field): \(issue.message)")
      }
    }
  }

  private static func emitJSON(_ payload: [String: Any]) {
    guard let data = try? JSONSerialization.data(
      withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
      let text = String(data: data, encoding: .utf8)
    else {
      print("{}")
      return
    }
    print(text)
  }

  private static func round6(_ value: Double) -> Double {
    (value * 1_000_000).rounded() / 1_000_000
  }

  private static func fail(_ error: Error) -> Int32 {
    FileHandle.standardError.write(Data("error: \(error.localizedDescription)\n".utf8))
    return CLIExit.failure
  }
}

/// Minimal `--key value` and `--flag` parser.
///
/// Options are read on demand, so each command accepts exactly the flags it
/// documents. A repeated option keeps the last value, which is the least
/// surprising rule for a script that appends an override.
struct Parsed {
  private var values: [String: String] = [:]
  private var flags: Set<String> = []
  private let positionals: [String]
  let problem: String?

  /// Flags that never take a value.
  private static let booleanFlags: Set<String> = [
    "json", "strict", "guides", "no-fit", "force", "help",
  ]

  init?(_ arguments: [String]) {
    var values: [String: String] = [:]
    var flags: Set<String> = []
    var positionals: [String] = []
    var problem: String?

    var index = 0
    while index < arguments.count {
      let argument = arguments[index]
      if argument.hasPrefix("--") {
        let name = String(argument.dropFirst(2))
        if Self.booleanFlags.contains(name) {
          flags.insert(name)
          index += 1
          continue
        }
        guard index + 1 < arguments.count else {
          problem = "Option --\(name) needs a value."
          index += 1
          continue
        }
        values[name] = arguments[index + 1]
        index += 2
        continue
      }
      positionals.append(argument)
      index += 1
    }

    self.values = values
    self.flags = flags
    self.positionals = positionals
    self.problem = problem
  }

  func value(_ name: String) -> String? { values[name] }
  func flag(_ name: String) -> Bool { flags.contains(name) }

  /// The cover path, from `--cover` or the first positional argument.
  var coverArgument: String? { values["cover"] ?? positionals.first }
}

enum CLIError: LocalizedError {
  case coverNotFound(String)
  case noCoverInProject(String)
  case renderFailed

  var errorDescription: String? {
    switch self {
    case .coverNotFound(let path):
      "No such cover file or project directory: \(path)"
    case .noCoverInProject(let path):
      "No cover/cover.md in project directory: \(path)"
    case .renderFailed:
      "The renderer did not produce an image. Check the front cover image path and template dimensions."
    }
  }
}
