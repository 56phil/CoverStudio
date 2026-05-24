import SwiftUI
import Yams

struct YAMLView: View {
    let data: CoverData

    var body: some View {
        let encoder = YAMLEncoder()
        let yamlString = (try? encoder.encode(data)) ?? "Error encoding YAML"

        TextEditor(text: .constant(yamlString))
            .font(.system(.body, design: .monospaced))
            .disabled(true)
    }
}
