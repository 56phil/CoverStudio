import SwiftUI
import AppKit

enum FontRole {
    case title, bold, body, italic

    var label: String {
        switch self {
        case .title: "Title font"
        case .bold:  "Bold font"
        case .body:  "Body font"
        case .italic: "Italic font"
        }
    }

    /// Whether a font name matches this role
    func matches(_ fontName: String) -> Bool {
        let lower = fontName.lowercased()
        switch self {
        case .title, .body:
            return true // show all fonts
        case .bold:
            return lower.contains("bold") || lower.contains("black") || lower.contains("heavy")
        case .italic:
            return lower.contains("italic") || lower.contains("oblique")
        }
    }
}

struct FontsTab: View {
    @Binding var data: CoverData

    var body: some View {
        Form {
            Section("Fonts") {
                FontPicker(label: "Title font", fontName: $data.fontTitle, role: .title)
                FontPicker(label: "Bold font",  fontName: $data.fontBold,  role: .bold)
                FontPicker(label: "Body font",  fontName: $data.fontRegular, role: .body)
                FontPicker(label: "Italic font", fontName: $data.fontItalic, role: .italic)
            }

            Section("Colors") {
                HexColorRow(label: "Title",  hex: $data.colorTitle)
                HexColorRow(label: "Accent", hex: $data.colorAccent)
                HexColorRow(label: "Body",   hex: $data.colorBody)
                HexColorRow(label: "Soft",   hex: $data.colorSoft)
            }
        }
    }
}

// ── Font Picker (sheet-based, not popover) ─────────────────────

struct FontPicker: View {
    let label: String
    @Binding var fontName: String
    let role: FontRole

    @State private var showSheet: Bool = false
    @State private var searchText: String = ""

    static let roleFonts: [FontRole: [String]] = {
        let all = NSFontManager.shared.availableFonts
        var result: [FontRole: [String]] = [:]
        for role in [FontRole.title, .bold, .body, .italic] {
            result[role] = all.filter { role.matches($0) }.sorted()
        }
        return result
    }()

    var availableFonts: [String] {
        guard let fonts = Self.roleFonts[role] else { return [] }
        if searchText.isEmpty { return fonts }
        return fonts.filter { $0.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 60, alignment: .leading)

            Button(action: { showSheet = true }) {
                HStack {
                    Text(fontName.isEmpty ? "Choose font\u{2026}" : fontName)
                        .lineLimit(1).truncationMode(.tail)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.horizontal, 6).padding(.vertical, 3)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .background(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
            .sheet(isPresented: $showSheet) {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(label).font(.headline)
                        Spacer()
                        Text("\(availableFonts.count) fonts").font(.caption).foregroundColor(.secondary)
                        Button("Done") { showSheet = false }
                            .keyboardShortcut(.escape, modifiers: [])
                    }
                    .padding()

                    // Search
                    TextField("Search fonts\u{2026}", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    // Font list
                    List(Array(availableFonts.prefix(300)), id: \.self) { font in
                        Button(action: {
                            fontName = font
                            showSheet = false
                            searchText = ""
                        }) {
                            HStack {
                                Text(font)
                                    .font(.custom(font, size: 14))
                                    .lineLimit(1)
                                Spacer()
                                if font == fontName {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 420, height: 520)
            }

            if !fontName.isEmpty {
                Button(action: { fontName = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.borderless).help("Clear font selection")
            }
        }
    }
}

// ── Color Picker Row ──────────────────────────────────────────────

struct HexColorRow: View {
    let label: String
    @Binding var hex: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 50, alignment: .leading)

            ColorPicker("", selection: Binding(
                get: { Color(nsColor: NSColor(hex: hex)) },
                set: { newColor in
                    hex = NSColor(newColor).hexString
                }
            ))
            .labelsHidden()

            TextField("#RRGGBB", text: $hex)
                .font(.system(.body, design: .monospaced))
                .frame(width: 90)
                .onChange(of: hex) { _, newValue in
                    var cleaned = newValue.trimmingCharacters(in: .whitespaces).uppercased()
                    if cleaned.hasPrefix("#") { cleaned.removeFirst() }
                    if cleaned.count > 6 { cleaned = String(cleaned.prefix(6)) }
                    if cleaned.count == 6 && hex != "#\(cleaned)" {
                        hex = "#\(cleaned)"
                    }
                }
        }
    }
}
