import SwiftUI

struct BackTab: View {
    @Binding var data: CoverData

    var body: some View {
        Form {
            Section("Blurb") {
                TextField("Blurb", text: $data.blurb, axis: .vertical).lineLimit(4...10)
                OffsetRow("Position", ox: $data.blurbOffsetXInches, oy: $data.blurbOffsetYInches)
            }

            Section("Quote") {
                TextField("Quote", text: $data.quote, axis: .vertical).lineLimit(2...4)
                OffsetRow("Position", ox: $data.quoteOffsetXInches, oy: $data.quoteOffsetYInches)
                TextField("Attribution", text: $data.quoteAttribution)
                OffsetRow("Attr pos", ox: $data.quoteAttributionOffsetXInches, oy: $data.quoteAttributionOffsetYInches)
            }

            Section("Author Bio") {
                TextField("Bio", text: $data.authorBio, axis: .vertical).lineLimit(4...8)
                OffsetRow("Position", ox: $data.authorBioOffsetXInches, oy: $data.authorBioOffsetYInches)
                HStack {
                    Text("Para gap").frame(width: 60, alignment: .leading)
                    TextField("pt", value: $data.authorBioParagraphGapPoints, format: .number).frame(width: 80)
                }
            }
        }
    }
}
