import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BackTab: View {
    @Binding var data: CoverData
    let sourceURL: URL?

    var body: some View {
        Form {
            Section("Blurb") {
                TextField("Blurb", text: $data.blurb, axis: .vertical).lineLimit(4...10)
                OffsetRow("Offset", ox: $data.blurbOffsetXInches, oy: $data.blurbOffsetYInches)
                WidthRow(label: "Line width", width: $data.blurbWidthInches)
            }

            Section("Quote") {
                TextField("Quote", text: $data.quote, axis: .vertical).lineLimit(2...4)
                OffsetRow("Offset", ox: $data.quoteOffsetXInches, oy: $data.quoteOffsetYInches)
                TextField("Attribution", text: $data.quoteAttribution)
                OffsetRow("Attr offset", ox: $data.quoteAttributionOffsetXInches, oy: $data.quoteAttributionOffsetYInches)
            }

            Section("Author Bio") {
                TextField("Bio", text: $data.authorBio, axis: .vertical).lineLimit(4...8)
                OffsetRow("Offset", ox: $data.authorBioOffsetXInches, oy: $data.authorBioOffsetYInches)
                WidthRow(label: "Line width", width: $data.authorBioWidthInches)
                HStack {
                    Text("Para gap").frame(width: 60, alignment: .leading)
                    TextField("pt", value: $data.authorBioParagraphGapPoints, format: .number).frame(width: 80)
                }
            }

            Section("Author Photo") {
                HStack {
                    TextField("Photo path (optional)", text: $data.authorPhoto).truncationMode(.middle)
                    Button("Choose\u{2026}") { chooseAuthorPhoto() }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                }
                OffsetRow("Barcode offset", ox: $data.authorPhotoOffsetXInches, oy: $data.authorPhotoOffsetYInches)
                HStack {
                    Text("Size (in)").frame(width: 60, alignment: .leading)
                    TextField("", value: $data.authorPhotoScaleInches, format: .number).frame(width: 80)
                }
                Picker("Shape", selection: $data.authorPhotoShape) {
                    ForEach(AuthorPhotoShape.allCases, id: \.self) { shape in
                        Text(shape.label).tag(shape)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private func chooseAuthorPhoto() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .heic]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            data.authorPhoto = ProjectManager.makeRelativePath(url, relativeTo: sourceURL)
        }
    }
}

struct WidthRow: View {
    let label: String
    @Binding var width: Double
    @State private var manualWidth: Double = 4.0

    private var isAuto: Binding<Bool> {
        Binding(
            get: { width <= 0 },
            set: { newValue in
                if newValue {
                    width = 0
                } else {
                    width = manualWidth
                }
            }
        )
    }

    private var manualBinding: Binding<Double> {
        Binding(
            get: { width > 0 ? width : manualWidth },
            set: { newValue in
                let cleanValue = max(newValue, 0)
                manualWidth = cleanValue
                width = cleanValue
            }
        )
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { min(max(width > 0 ? width : manualWidth, 1.0), 8.0) },
            set: { newValue in
                manualWidth = newValue
                width = newValue
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).frame(width: 70, alignment: .leading)
                Toggle("Auto", isOn: isAuto)
                    .toggleStyle(.checkbox)
                Spacer()
                Text(width <= 0 ? "Auto" : String(format: "%.2f in", width))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }

            HStack {
                Slider(value: sliderBinding, in: 1.0...8.0, step: 0.05)
                    .disabled(width <= 0)
                TextField("Width", value: manualBinding, format: .number.precision(.fractionLength(2)))
                    .frame(width: 86)
                    .disabled(width <= 0)
                Text("in").foregroundColor(.secondary)
            }
        }
        .onAppear {
            if width > 0 {
                manualWidth = width
            }
        }
    }
}
