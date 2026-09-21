import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct BackTab: View {
 @Binding var data: CoverData
 let sourceURL: URL?

 var body: some View {
  Form {
   Section("Blurb") {
    TextEditor(text: activeBlurb).frame(minHeight: 80, maxHeight: 200).font(.body)
    Button("Load from .txt\u{2026}") { loadText(into: activeBlurb) }
     .buttonStyle(.borderedProminent)
    OffsetRow("Offset", ox: $data.blurbOffsetXInches, oy: $data.blurbOffsetYInches)
    WidthRow(label: "Line width", width: $data.blurbWidthInches)
    FontSizeRow(
     label: "Font size", points: activeBlurbFontSize,
     defaultPoints: CoverLayoutDefaults.backBlurbFontSizePoints, range: 14...90)
   }

   Section("Quote") {
    TextEditor(text: $data.quote).frame(minHeight: 50, maxHeight: 100).font(.body)
    OffsetRow("Offset", ox: $data.quoteOffsetXInches, oy: $data.quoteOffsetYInches)
    FontSizeRow(
     label: "Font size", points: activeQuoteFontSize,
     defaultPoints: CoverLayoutDefaults.backQuoteFontSizePoints, range: 12...72)
    TextField("Attribution", text: $data.quoteAttribution)
    OffsetRow(
     "Attr offset", ox: $data.quoteAttributionOffsetXInches, oy: $data.quoteAttributionOffsetYInches
    )
   }

   Section("Author Bio") {
    TextEditor(text: activeBio).frame(minHeight: 80, maxHeight: 160).font(.body)
    Button("Load from .txt\u{2026}") { loadText(into: activeBio) }
     .buttonStyle(.borderedProminent)
    OffsetRow("Offset", ox: $data.authorBioOffsetXInches, oy: $data.authorBioOffsetYInches)
    WidthRow(label: "Line width", width: $data.authorBioWidthInches)
    HStack {
     Text("Para gap").frame(width: 60, alignment: .leading)
     TextField("pt", value: $data.authorBioParagraphGapPoints, format: .number).frame(width: 80)
    }
    FontSizeRow(
     label: "Font size", points: activeBioFontSize,
     defaultPoints: CoverLayoutDefaults.backAuthorBioFontSizePoints, range: 14...56)
   }

   Section("Author Photo") {
    HStack {
     TextField("Photo path (optional)", text: $data.authorPhoto).truncationMode(.middle)
     Button("Choose\u{2026}") { chooseAuthorPhoto() }
      .buttonStyle(.borderless)
      .controlSize(.small)
    }
    OffsetRow(
     "Barcode offset", ox: $data.authorPhotoOffsetXInches, oy: $data.authorPhotoOffsetYInches)
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
    if data.authorPhotoShape == .circle || data.authorPhotoShape == .square {
     CropPositionRow(cropX: $data.authorPhotoCropOffsetX, cropY: $data.authorPhotoCropOffsetY)
    }
   }
  }
 }

 /// Routes to the per-binding blurb: editing while HC stores to hc_blurb, while PB stores to blurb.
 private var activeBlurb: Binding<String> {
  Binding(
   get: { data.bindingType == .hc ? data.hcBlurb : data.blurb },
   set: { if data.bindingType == .hc { data.hcBlurb = $0 } else { data.blurb = $0 } }
  )
 }

 /// Routes to the per-binding author bio: editing while HC stores to hc_author_bio, while PB stores to author_bio.
 private var activeBio: Binding<String> {
  Binding(
   get: { data.bindingType == .hc ? data.hcAuthorBio : data.authorBio },
   set: { if data.bindingType == .hc { data.hcAuthorBio = $0 } else { data.authorBio = $0 } }
  )
 }

 /// Routes to the per-binding blurb font size, so the two bindings can differ.
 private var activeBlurbFontSize: Binding<Double> {
  Binding(
   get: { data.bindingType == .hc ? data.hcBlurbFontSizePoints : data.blurbFontSizePoints },
   set: {
    if data.bindingType == .hc { data.hcBlurbFontSizePoints = $0 } else { data.blurbFontSizePoints = $0 }
   }
  )
 }

 private var activeQuoteFontSize: Binding<Double> {
  Binding(
   get: { data.bindingType == .hc ? data.hcQuoteFontSizePoints : data.quoteFontSizePoints },
   set: {
    if data.bindingType == .hc { data.hcQuoteFontSizePoints = $0 } else { data.quoteFontSizePoints = $0 }
   }
  )
 }

 private var activeBioFontSize: Binding<Double> {
  Binding(
   get: { data.bindingType == .hc ? data.hcAuthorBioFontSizePoints : data.authorBioFontSizePoints },
   set: {
    if data.bindingType == .hc {
     data.hcAuthorBioFontSizePoints = $0
    } else {
     data.authorBioFontSizePoints = $0
    }
   }
  )
 }

 // Join hard-wrapped lines within each paragraph; keep blank lines as paragraph breaks.
 private func reflow(_ text: String) -> String {
  // Split on one or more blank lines to get paragraphs.
  var paragraphs: [String] = []
  var current: [String] = []
  for line in text.components(separatedBy: "\n") {
   let trimmed = line.trimmingCharacters(in: CharacterSet.whitespaces)
   if trimmed.isEmpty {
    if !current.isEmpty {
     paragraphs.append(current.joined(separator: " "))
     current = []
    }
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
   let text = try? String(contentsOf: url, encoding: .utf8)
  {
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

struct CropPositionRow: View {
 @Binding var cropX: Double
 @Binding var cropY: Double

 var body: some View {
  VStack(alignment: .leading, spacing: 6) {
   Text("Crop position").font(.caption).foregroundColor(.secondary)
   HStack(spacing: 8) {
    Text("H").frame(width: 14, alignment: .leading).font(.caption.monospacedDigit())
    Slider(value: $cropX, in: -1...1)
    Button("↺") { cropX = 0 }
     .buttonStyle(.borderless).controlSize(.small)
   }
   HStack(spacing: 8) {
    Text("V").frame(width: 14, alignment: .leading).font(.caption.monospacedDigit())
    Slider(value: $cropY, in: -1...1)
    Button("↺") { cropY = 0 }
     .buttonStyle(.borderless).controlSize(.small)
   }
  }
  .padding(.top, 2)
 }
}

struct FontSizeRow: View {
 let label: String
 @Binding var points: Double
 /// The size used when `points` is 0 (unset), shown so the control is never blank.
 let defaultPoints: Double
 let range: ClosedRange<Double>

 /// 0 means "use the default", so one control serves both the default and an
 /// explicit size without a separate toggle.
 private var isDefault: Binding<Bool> {
  Binding(
   get: { points <= 0 },
   set: { useDefault in
    points = useDefault ? 0 : defaultPoints
   }
  )
 }

 private var sliderBinding: Binding<Double> {
  Binding(
   get: { points > 0 ? min(max(points, range.lowerBound), range.upperBound) : defaultPoints },
   set: { points = $0 }
  )
 }

 var body: some View {
  VStack(alignment: .leading, spacing: 6) {
   HStack {
    Text(label).frame(width: 70, alignment: .leading)
    Toggle("Default", isOn: isDefault)
     .toggleStyle(.checkbox)
    Spacer()
    Text(points <= 0 ? "Default (\(Int(defaultPoints)) pt)" : "\(Int(points)) pt")
     .font(.caption.monospacedDigit())
     .foregroundColor(.secondary)
     .frame(width: 110, alignment: .trailing)
   }

   HStack {
    Slider(value: sliderBinding, in: range, step: 1)
     .disabled(points <= 0)
    TextField("pt", value: $points, format: .number.precision(.fractionLength(0)))
     .frame(width: 70)
    Text("pt").foregroundColor(.secondary)
   }
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
