import SwiftUI
import AppKit
import Yams

struct YAMLView: View {
    let data: CoverData

    var body: some View {
        let encoder = YAMLEncoder()
        let yamlString = (try? encoder.encode(data)) ?? "Error encoding YAML"

        VStack(alignment: .trailing, spacing: 4) {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(yamlString, forType: .string)
            }
            .controlSize(.small)

            TextEditor(text: .constant(yamlString))
                .font(.system(.body, design: .monospaced))
                .disabled(true)
        }
    }
}
