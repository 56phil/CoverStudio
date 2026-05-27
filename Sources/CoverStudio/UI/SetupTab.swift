import SwiftUI
import AppKit

// ── KDP Hardcover Template Defaults ──────────────────────────────────
// These are the exact output from KDP's cover template calculator.
// Hinge (0.394") and wrap (0.591") are constant across all trim sizes.
// Front cover is trim + 0.197" wide, trim + 0.236" tall.
// Full cover = frontWidth×2 + spine + wrap×2 (hinge is a fold within the total width).
// Spine width comes from the calculator and varies by page count.

struct HCDefaults {
    let frontWidth: Double
    let frontHeight: Double
    let hingeWidth: Double  = 0.394
    let wrapWidth: Double   = 0.591

    /// Spine width computed from page count using KDP's hardcover formula.
    /// Based on known-good values: 6×9 HC B&W at 91 pages → 0.420" spine.
    /// Rate: 0.420 / 91 = 0.004615.
    func spineWidth(for pageCount: Int) -> Double {
        Double(pageCount) * 0.004615
    }

    /// Full cover width = front×2 + spine + wrap×2 (hinge does NOT add width)
    func fullWidth(for pageCount: Int) -> Double {
        frontWidth * 2 + spineWidth(for: pageCount) + wrapWidth * 2
    }

    /// Full cover height = front height + wrap×2
    var fullHeight: Double {
        frontHeight + wrapWidth * 2
    }

    init(trimWidth: Double, trimHeight: Double) {
        frontWidth  = trimWidth  + 0.197
        frontHeight = trimHeight + 0.236
    }
}

struct SetupTab: View {
    @Binding var data: CoverData
    let projectRoot: String?
    let onSelectProjectRoot: () -> Void

    private var hcDefaults: HCDefaults {
        let (w, h): (Double, Double)
        if data.trimSize == .custom {
            w = data.customTrimWidthInches
            h = data.customTrimHeightInches
        } else {
            (w, h) = data.trimSize.dimensions
        }
        return HCDefaults(trimWidth: w, trimHeight: h)
    }

    private var activePageCount: Binding<Int> {
        Binding(
            get: { data.resolvedPageCount() },
            set: { value in
                let pageCount = max(value, 0)
                if data.bindingType == .hc {
                    data.hcPageCount = pageCount
                } else {
                    data.pbPageCount = pageCount
                }
                data.pageCount = pageCount
            }
        )
    }

    var body: some View {
        Form {
            // ── Project Root ──
            Section {
                HStack {
                    Image(systemName: "folder").foregroundColor(.secondary)
                    if let root = projectRoot {
                        Text(root).font(.caption).foregroundColor(.secondary)
                            .lineLimit(1).truncationMode(.middle)
                    } else {
                        Text("No project selected").font(.caption).foregroundColor(.orange)
                    }
                    Spacer()
                    Button("Choose\u{2026}") { onSelectProjectRoot() }
                        .buttonStyle(.borderless).controlSize(.small)
                }
            } header: { Text("Project Root") }

            // ── Binding ──
            Section("Binding") {
                Picker("Type", selection: $data.bindingType) {
                    ForEach(BindingType.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                Picker("Interior", selection: $data.interiorType) {
                    ForEach(InteriorType.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                Picker("Paper", selection: $data.paperType) {
                    ForEach(PaperType.options(for: data.interiorType), id: \.self) { Text($0.label).tag($0) }
                }
            }

            // ── Trim ──
            Section("Trim") {
                Toggle("Use Preset", isOn: $data.platformPreset)
                if data.platformPreset {
                    Picker("Size", selection: $data.trimSize) {
                        let presets = data.bindingType == .pb
                            ? TrimPreset.paperbackPresets()
                            : TrimPreset.hardcoverPresets()
                        ForEach(presets, id: \.self) { preset in Text(preset.label).tag(preset) }
                    }
                }
                if data.trimSize == .custom {
                    HStack {
                        TextField("Width", value: $data.customTrimWidthInches, format: .number)
                        TextField("Height", value: $data.customTrimHeightInches, format: .number)
                    }
                    TextField("Spine", value: $data.customSpineWidthInches, format: .number)
                    TextField("Bleed", value: $data.customBleedInches, format: .number)
                    TextField("Safe margin", value: $data.customSafeMarginInches, format: .number)
                }
            }

            // ── Page ──
            Section("Page") {
                TextField("\(data.bindingType.label) page count", value: activePageCount, format: .number)
                Picker("Direction", selection: $data.readingDirection) {
                    ForEach(ReadingDirection.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                Picker("Units", selection: $data.uiUnits) {
                    ForEach(Units.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                TextField("Guide X shift", value: $data.guideXOffsetInches, format: .number)
            }

            Section("Layout") {
                Button("Reset Default Locations", systemImage: "arrow.counterclockwise") {
                    data.applyDefaultLocations()
                }
            }

            // ── Hardcover Template — always at the bottom ──
            if data.bindingType == .hc {
                Section {
                    Text("Exact values from your printer's template calculator. Defaults shown are KDP estimates — verify with the calculator before submitting.")
                        .font(.caption).foregroundColor(.secondary)
                    Link("Open KDP cover calculator ↗",
                         destination: URL(string: "https://kdp.amazon.com/en_US/cover-calculator")!)
                        .font(.caption)

                    TemplateField("Full cover width",
                        value: Binding(get: { data.templateFullCoverWidth ?? hcDefaults.fullWidth(for: data.resolvedPageCount()) },
                                       set: { data.templateFullCoverWidth = $0 }))

                    TemplateField("Full cover height",
                        value: Binding(get: { data.templateFullCoverHeight ?? hcDefaults.fullHeight },
                                       set: { data.templateFullCoverHeight = $0 }))

                    TemplateField("Front cover width",
                        value: Binding(get: { data.templateFrontCoverWidth ?? hcDefaults.frontWidth },
                                       set: { data.templateFrontCoverWidth = $0 }))

                    TemplateField("Front cover height",
                        value: Binding(get: { data.templateFrontCoverHeight ?? hcDefaults.frontHeight },
                                       set: { data.templateFrontCoverHeight = $0 }))

                    TemplateField("Spine width",
                        value: Binding(get: { data.templateSpineWidth ?? hcDefaults.spineWidth(for: data.resolvedPageCount()) },
                                       set: { data.templateSpineWidth = $0 }))

                    TemplateField("Hinge width",
                        value: Binding(get: { data.templateHingeWidth ?? hcDefaults.hingeWidth },
                                       set: { data.templateHingeWidth = $0 }))

                    TemplateField("Wrap width",
                        value: Binding(get: { data.templateWrapWidth ?? hcDefaults.wrapWidth },
                                       set: { data.templateWrapWidth = $0 }))
                } header: {
                    Label("Hardcover Template", systemImage: "ruler")
                }
            }
        }
    }
}

private struct TemplateField: View {
    let label: String
    @Binding var value: Double

    init(_ label: String, value: Binding<Double>) {
        self.label = label
        self._value = value
    }

    var body: some View {
        HStack {
            Text(label).frame(width: 130, alignment: .leading)
            TextField(label, value: $value, format: .number.precision(.fractionLength(3)))
                .multilineTextAlignment(.trailing)
        }
    }
}
