import Foundation
import Yams
import UniformTypeIdentifiers

struct ProjectManager {
    /// Binary Cover Metadata/Generator format (.cmg)
    static let cmgType: UTType = UTType(filenameExtension: "cmg", conformingTo: .data) ?? .data

    static let coverContentTypes: [UTType] = [
        cmgType,
        .yaml,
        UTType(filenameExtension: "yml") ?? .yaml,
        UTType(filenameExtension: "md") ?? .plainText,
        .json
    ]

    static func load(from url: URL) throws -> CoverData {
        let data: CoverData
        if url.pathExtension.lowercased() == "cmg" {
            let raw = try Data(contentsOf: url)
            data = try PropertyListDecoder().decode(CoverData.self, from: raw)
        } else {
            let contents = try String(contentsOf: url, encoding: .utf8)
            let yamlString = try yamlPayload(from: contents, url: url)
            let decoder = YAMLDecoder()
            data = try decoder.decode(CoverData.self, from: yamlString)
        }
        migrateIfNeeded(data, to: url)
        return data
    }

    /// Silently rewrite the file when it was loaded from an older schema version.
    private static func migrateIfNeeded(_ data: CoverData, to url: URL) {
        guard data.schemaVersion == currentSchemaVersion else { return }
        // Re-read the raw file to check whether the on-disk schema is outdated.
        let onDiskVersion: Int
        if url.pathExtension.lowercased() == "cmg" {
            let raw = (try? Data(contentsOf: url)).flatMap { try? PropertyListDecoder().decode(CoverData.self, from: $0) }
            onDiskVersion = raw?.schemaVersion ?? 1
        } else {
            let contents = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            let yaml = (try? yamlPayload(from: contents, url: url)) ?? ""
            let versionLine = yaml.components(separatedBy: "\n").first { $0.hasPrefix("schema_version:") }
            let parsed = versionLine.flatMap { Int($0.replacingOccurrences(of: "schema_version:", with: "").trimmingCharacters(in: .whitespaces)) }
            onDiskVersion = parsed ?? 1
        }
        guard onDiskVersion < currentSchemaVersion else { return }
        try? save(data, to: url)
    }

    static func save(_ data: CoverData, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if url.pathExtension.lowercased() == "cmg" {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            let raw = try encoder.encode(data)
            try raw.write(to: url, options: .atomic)
            return
        }

        let yamlString = try mergedYAML(for: data, existingAt: url)
        if url.pathExtension.lowercased() == "md" {
            let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            let body = markdownBody(from: existing)
            let frontmatter = yamlString.hasSuffix("\n") ? yamlString : "\(yamlString)\n"
            let markdown = "---\n\(frontmatter)---\n\(body)"
            try markdown.write(to: url, atomically: true, encoding: .utf8)
        } else {
            try yamlString.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    /// Resolve a project path relative to the project directory (the folder containing the YAML file).
    static func resolveProjectPath(_ path: String, relativeTo yamlURL: URL?) -> String {
        if path.hasPrefix("/") { return path }
        guard let yamlURL else { return path }

        if path.hasPrefix("cover/") {
            return projectRoot(for: yamlURL).appendingPathComponent(path).path
        }

        let coverDirectory = yamlURL.deletingLastPathComponent()
        let coverRelative = coverDirectory.appendingPathComponent(path).path
        if FileManager.default.fileExists(atPath: coverRelative) {
            return coverRelative
        }

        return projectRoot(for: yamlURL).appendingPathComponent(path).path
    }

    /// Resolve an image path relative to the project directory (the folder containing the YAML file)
    static func resolveImagePath(_ imagePath: String, relativeTo yamlURL: URL?) -> String {
        resolveProjectPath(imagePath, relativeTo: yamlURL)
    }

    /// Store a path relative to the project root when the file lives inside it; otherwise absolute.
    static func makeRelativePath(_ url: URL, relativeTo sourceURL: URL?) -> String {
        guard let sourceURL else { return url.path }
        let root = projectRoot(for: sourceURL)
        var rootPath = root.path
        if !rootPath.hasSuffix("/") { rootPath += "/" }
        guard url.path.hasPrefix(rootPath) else { return url.path }
        return String(url.path.dropFirst(rootPath.count))
    }

    static func projectRoot(for coverFileURL: URL) -> URL {
        let containingDirectory = coverFileURL.deletingLastPathComponent()
        if containingDirectory.lastPathComponent == "cover" {
            return containingDirectory.deletingLastPathComponent()
        }
        return containingDirectory
    }

    static func preferredCoverFile(in projectRoot: URL) -> URL? {
        let coverDirectory = projectRoot.appendingPathComponent("cover", isDirectory: true)
        let markdownURL = coverDirectory.appendingPathComponent("cover.md")
        let yamlURL = coverDirectory.appendingPathComponent("cover.yaml")

        if FileManager.default.fileExists(atPath: markdownURL.path) {
            return markdownURL
        }
        if FileManager.default.fileExists(atPath: yamlURL.path) {
            return yamlURL
        }
        return nil
    }

    static func defaultCoverFile(in projectRoot: URL) -> URL {
        projectRoot
            .appendingPathComponent("cover", isDirectory: true)
            .appendingPathComponent("cover.md")
    }

    // Find \n--- that ends the line (followed by \n or end-of-string).
    // A bare \n--- mid-token (e.g. \n---key:) is not a valid closing fence.
    private static func frontmatterClose(in text: String, from start: String.Index) -> Range<String.Index>? {
        var search = start
        while let range = text[search...].range(of: "\n---") {
            let after = range.upperBound
            if after == text.endIndex || text[after] == "\n" {
                return range
            }
            guard let next = text.index(range.lowerBound, offsetBy: 1, limitedBy: text.endIndex) else { break }
            search = next
        }
        return nil
    }

    private static func yamlPayload(from contents: String, url: URL) throws -> String {
        guard url.pathExtension.lowercased() == "md" else {
            return contents
        }

        let normalized = contents.replacingOccurrences(of: "\r\n", with: "\n")
        guard normalized.hasPrefix("---\n") else {
            throw ProjectManagerError.missingFrontmatter
        }

        let bodyStart = normalized.index(normalized.startIndex, offsetBy: 4)
        guard let closingRange = frontmatterClose(in: normalized, from: bodyStart) else {
            throw ProjectManagerError.missingFrontmatter
        }

        return String(normalized[bodyStart..<closingRange.lowerBound])
    }

    private static func markdownBody(from contents: String) -> String {
        let normalized = contents.replacingOccurrences(of: "\r\n", with: "\n")
        guard normalized.hasPrefix("---\n") else {
            return contents.isEmpty ? "\n" : contents
        }

        let bodyStart = normalized.index(normalized.startIndex, offsetBy: 4)
        guard let closingRange = frontmatterClose(in: normalized, from: bodyStart) else {
            return "\n"
        }

        let afterFence = closingRange.upperBound
        if afterFence < normalized.endIndex,
           normalized[afterFence] == "\n" {
            return String(normalized[normalized.index(after: afterFence)...])
        }
        return String(normalized[afterFence...])
    }

    private static func mergedYAML(for data: CoverData, existingAt url: URL) throws -> String {
        let encoder = YAMLEncoder()
        let encoded = try encoder.encode(data)
        guard let existingContents = try? String(contentsOf: url, encoding: .utf8),
              let existingYAML = try? yamlPayload(from: existingContents, url: url),
              let existingObject = try? Yams.load(yaml: existingYAML),
              let encodedObject = try? Yams.load(yaml: encoded),
              var existingMap = existingObject as? [String: Any],
              let encodedMap = encodedObject as? [String: Any] else {
            return encoded
        }

        for (key, value) in encodedMap {
            existingMap[key] = value
        }

        return try Yams.dump(object: existingMap, sortKeys: true)
    }
}

enum ProjectManagerError: LocalizedError {
    case missingFrontmatter

    var errorDescription: String? {
        switch self {
        case .missingFrontmatter:
            "Markdown cover files must begin with YAML frontmatter."
        }
    }
}
