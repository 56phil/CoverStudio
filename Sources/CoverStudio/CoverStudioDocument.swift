import SwiftUI
import Yams
import UniformTypeIdentifiers
import Foundation

struct CoverStudioDocument: FileDocument {
    var data: CoverData = CoverData()

    static var readableContentTypes: [UTType] = [.plainText]
    static var writableContentTypes: [UTType] = [.plainText]

    init() {}

    init(configuration: ReadConfiguration) throws {
        guard let yamlData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let yamlString = String(data: yamlData, encoding: String.Encoding.utf8) ?? ""
        let decoder = YAMLDecoder()
        data = try decoder.decode(CoverData.self, from: yamlString)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = YAMLEncoder()
        let yamlString = try encoder.encode(data)
        guard let yamlData = yamlString.data(using: String.Encoding.utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: yamlData)
    }
}
