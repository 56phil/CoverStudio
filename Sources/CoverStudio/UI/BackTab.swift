import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BackTab: View {
    @Binding var data: CoverData
    let sourceURL: URL?

    var body: some View {
        Form {
            Section("Blurb") {
                TextEditor(text: $data.blurb).frame(minHeight: 80, maxHeight: 200).font(.body)
                Button("Load from .txt\u{2026}") { loadText(into: $data.blurb) }
                    .buttonStyle(.borderedProminent)
                OffsetRow("Offset", ox: $data.blurbOffsetXInches, oy: $data.blurbOffsetYInches)
                WidthRow(label: "Line width", width: $data.blurbWidthInches)
            }

            Section("Quote") {
                TextEditor(text: $data.quote).frame(minHeight: 50, maxHeight: 100).font(.body)
                OffsetRow("Offset", ox: $data.quoteOffsetXInches, oy: $data.quoteOffsetYInches)
                TextField("Attribution", text: $data.quoteAttribution)
                OffsetRow("Attr offset", ox: $data.quoteAttributionOffsetXInches, oy: $data.quoteAttributionOffsetYInches)
            }

            Section("Author Bio") {
                TextEditor(text: $data.authorBio).frame(minHeight: 80, maxHeight: 160).font(.body)
                Button("Load from .txt\u{2026}") { loadText(into: $data.authorBio) }
                    .buttonStyle(.borderedProminent)
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

    // Join hard-wrapped lines within each paragraph; keep blank lines as paragraph breaks.
    private func reflow(_ text: String) -> String {
        // Split on one or more blank lines to get paragraphs.
        var paragraphs: [String] = []
        var current: [String] = []
        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespaces)
            if trimmed.isEmpty {
                if !current.isEmpty { paragraphs.append(current.joined(separator: " ")); current = [] }
            } else {
                current.append(trimmed)
            }
        }
        if !current.isEmpty { paragraphs.append(current.joined(separator: " ")) }
        return paragraphs.joined(separator: "\n\n")
    }

    private func loadText(into binding: Binding<String>) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url,
           let text = try? String(contentsOf: url, encoding: .utf8) {
            binding.wrappedValue = reflow(text)
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
    @State private var manualWidth: Double

    init(label: String, width: Binding<Double>) {
        self.label = label
        self._width = width
        self._manualWidth = State(initialValue: width.wrappedValue > 0 ? width.wrappedValue : 4.0)
    }

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
    }
}
