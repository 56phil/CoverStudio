import SwiftUI

struct SpineTab: View {
    @Binding var data: CoverData

    var body: some View {
        Form {
            Section("Spine Content") {
                Toggle("Show spine text", isOn: $data.spineText)
                TextField("Spine color (auto or #RRGGBB)", text: $data.spineColor)
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
