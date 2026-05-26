import SwiftUI
import AppKit

struct SpineTab: View {
    @Binding var data: CoverData

    private var isAutoSpineColor: Binding<Bool> {
        Binding(
            get: {
                let v = data.spineColor.trimmingCharacters(in: .whitespaces)
                return v.isEmpty || v.lowercased() == "auto"
            },
            set: { auto in
                data.spineColor = auto ? "auto" : "#122b22"
            }
        )
    }

    var body: some View {
        Form {
            Section("Spine Content") {
                Toggle("Show spine text", isOn: $data.spineText)
                Toggle("Auto color", isOn: isAutoSpineColor)
                if !isAutoSpineColor.wrappedValue {
                    HexColorRow(label: "Color", hex: $data.spineColor)
                }
                TextField("Text offset (in)", value: $data.spineTextOffsetInches, format: .number)
                TextField("Color extension (in)", value: $data.spineColorExtensionInches, format: .number)
            }
            if data.spineText {
                Section("Spine Title") {
                    TextField("Title X offset", value: $data.spineTitleOffsetXInches, format: .number)
                    TextField("Title Y offset", value: $data.spineTitleOffsetYInches, format: .number)
                }
                Section("Spine Author") {
                    TextField("Author X offset", value: $data.spineAuthorOffsetXInches, format: .number)
                    TextField("Author Y offset", value: $data.spineAuthorOffsetYInches, format: .number)
                }
            }
        }
    }
}
