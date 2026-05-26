import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FrontTab: View {
    @Binding var data: CoverData
    let sourceURL: URL?
    @State private var isDropTargeted: Bool = false

    var body: some View {
        Form {
            Section("Title & Author Scale") {
                VStack(spacing: 2) {
                    HStack {
                        Slider(value: Binding(
                            get: { data.resolvedTitleScale() },
                            set: { newValue in
                                setActiveTitleScale(newValue)
                                setActiveAuthorScale(newValue)
                            }
                        ), in: 0.25...2.0, step: 0.05)
                        Text(String(format: "%.2f×", data.resolvedTitleScale()))
                            .font(.caption.monospacedDigit())
                            .frame(width: 46)
                    }
                    Text("Sets title and author scale together. Use the individual controls below to adjust separately.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Section("Background Image") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        TextField("Image path (optional)", text: $data.frontCoverImage)
                            .truncationMode(.middle)
                        Button("Choose\u{2026}") { chooseImage() }
                            .buttonStyle(.borderless).controlSize(.small)
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundColor(isDropTargeted ? .accentColor : .secondary.opacity(0.4))
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : Color.clear))
                        if let ns = resolvedThumbnail() {
                            Image(nsImage: ns).resizable().aspectRatio(contentMode: .fit).frame(height: 80).cornerRadius(6)
                        } else if data.frontCoverImage.isEmpty {
                            VStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle").font(.system(size: 24))
                                    .foregroundColor(.secondary.opacity(isDropTargeted ? 0.8 : 0.4))
                                Text("Drop image here").font(.caption).foregroundColor(.secondary)
                            }
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle").font(.system(size: 24))
                                    .foregroundColor(.orange.opacity(0.8))
                                Text("Image not found").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 90)
                    .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { handleDrop(providers: $0) }
                }
                Toggle("Center image", isOn: $data.frontCoverImageCentered)
                OffsetRow("Offset", ox: activeImageOffsetX, oy: activeImageOffsetY)
            }

            Section("Text") {
                Toggle("Draw front text", isOn: $data.frontText)
            }

            Section("Title") {
                TextField(text: $data.title, prompt: Text("Book Title")) { Text("Title") }
                CenterAxisRow(centerX: activeTitleCenterX, centerY: activeTitleCenterY)
                ScaleRow("Scale", scale: activeTitleScale)
                OffsetRow("Offset", ox: activeTitleOffsetX, oy: activeTitleOffsetY)
            }

            Section("Subtitle") {
                TextField(text: $data.subtitle, prompt: Text("Subtitle (optional)")) { Text("Subtitle") }
                CenterAxisRow(centerX: activeSubtitleCenterX, centerY: activeSubtitleCenterY)
                HStack {
                    Text("Size").frame(width: 50, alignment: .leading)
                    Slider(value: activeSubtitleScale, in: 0.25...3.0, step: 0.05)
                    TextField("Scale", value: activeSubtitleScale, format: .number)
                        .frame(width: 56)
                    Text("x")
                        .foregroundColor(.secondary)
                }
                OffsetRow("Offset", ox: activeSubtitleOffsetX, oy: activeSubtitleOffsetY)
            }

            Section("Author") {
                TextField(text: $data.authorName, prompt: Text("Author Name")) { Text("Author") }
                CenterAxisRow(centerX: activeAuthorCenterX, centerY: activeAuthorCenterY)
                ScaleRow("Scale", scale: activeAuthorScale)
                OffsetRow("Offset", ox: activeAuthorOffsetX, oy: activeAuthorOffsetY)
            }

        }
    }

    private var activeImageOffsetX: Binding<Double> {
        Binding(
            get: { data.resolvedImageOffsetX() },
            set: {
                if data.bindingType == .hc { data.hcFrontImageOffsetXInches = $0 }
                else { data.frontCoverImageOffsetXInches = $0 }
            }
        )
    }

    private var activeImageOffsetY: Binding<Double> {
        Binding(
            get: { data.resolvedImageOffsetY() },
            set: {
                if data.bindingType == .hc { data.hcFrontImageOffsetYInches = $0 }
                else { data.frontCoverImageOffsetYInches = $0 }
            }
        )
    }

    private var activeTitleOffsetX: Binding<Double> {
        Binding(
            get: { data.resolvedOffsetX() },
            set: {
                if data.bindingType == .hc { data.hcFrontTitleOffsetXInches = $0 }
                else { data.frontTitleOffsetXInches = $0 }
            }
        )
    }

    private var activeTitleOffsetY: Binding<Double> {
        Binding(
            get: { data.resolvedOffsetY() },
            set: {
                if data.bindingType == .hc { data.hcFrontTitleOffsetYInches = $0 }
                else { data.frontTitleOffsetYInches = $0 }
            }
        )
    }

    private var activeTitleCenterX: Binding<Bool> {
        Binding(
            get: { data.resolvedTitleCenterX() },
            set: {
                if data.bindingType == .hc { data.hcFrontTitleCenterX = $0 }
                else { data.frontTitleCenterX = $0 }
            }
        )
    }

    private var activeTitleCenterY: Binding<Bool> {
        Binding(
            get: { data.resolvedTitleCenterY() },
            set: {
                if data.bindingType == .hc { data.hcFrontTitleCenterY = $0 }
                else { data.frontTitleCenterY = $0 }
            }
        )
    }

    private var activeSubtitleOffsetX: Binding<Double> {
        Binding(
            get: { data.resolvedSubtitleOffsetX() },
            set: {
                if data.bindingType == .hc { data.hcFrontSubtitleOffsetXInches = $0 }
                else { data.frontSubtitleOffsetXInches = $0 }
            }
        )
    }

    private var activeSubtitleOffsetY: Binding<Double> {
        Binding(
            get: { data.resolvedSubtitleOffsetY() },
            set: {
                if data.bindingType == .hc { data.hcFrontSubtitleOffsetYInches = $0 }
                else { data.frontSubtitleOffsetYInches = $0 }
            }
        )
    }

    private var activeSubtitleCenterX: Binding<Bool> {
        Binding(
            get: { data.resolvedSubtitleCenterX() },
            set: {
                if data.bindingType == .hc { data.hcFrontSubtitleCenterX = $0 }
                else { data.frontSubtitleCenterX = $0 }
            }
        )
    }

    private var activeSubtitleCenterY: Binding<Bool> {
        Binding(
            get: { data.resolvedSubtitleCenterY() },
            set: {
                if data.bindingType == .hc { data.hcFrontSubtitleCenterY = $0 }
                else { data.frontSubtitleCenterY = $0 }
            }
        )
    }

    private var activeSubtitleScale: Binding<Double> {
        Binding(
            get: { data.resolvedSubtitleScale() },
            set: {
                let value = max($0, 0.1)
                if data.bindingType == .hc { data.hcFrontSubtitleScale = value }
                else { data.frontSubtitleScale = value }
            }
        )
    }

    private var activeAuthorCenterX: Binding<Bool> {
        Binding(
            get: { data.resolvedAuthorCenterX() },
            set: {
                if data.bindingType == .hc { data.hcFrontAuthorCenterX = $0 }
                else { data.frontAuthorCenterX = $0 }
            }
        )
    }

    private var activeAuthorCenterY: Binding<Bool> {
        Binding(
            get: { data.resolvedAuthorCenterY() },
            set: {
                if data.bindingType == .hc { data.hcFrontAuthorCenterY = $0 }
                else { data.frontAuthorCenterY = $0 }
            }
        )
    }

    private var activeAuthorOffsetX: Binding<Double> {
        Binding(
            get: { data.resolvedAuthorOffsetX() },
            set: {
                if data.bindingType == .hc { data.hcFrontAuthorOffsetXInches = $0 }
                else { data.frontAuthorOffsetXInches = $0 }
            }
        )
    }

    private var activeAuthorOffsetY: Binding<Double> {
        Binding(
            get: { data.resolvedAuthorOffsetY() },
            set: {
                if data.bindingType == .hc { data.hcFrontAuthorOffsetYInches = $0 }
                else { data.frontAuthorOffsetYInches = $0 }
            }
        )
    }

    private var activeTitleScale: Binding<Double> {
        Binding(
            get: { data.resolvedTitleScale() },
            set: { setActiveTitleScale(max($0, 0.1)) }
        )
    }

    private var activeAuthorScale: Binding<Double> {
        Binding(
            get: { data.resolvedAuthorScale() },
            set: { setActiveAuthorScale(max($0, 0.1)) }
        )
    }

    private func setActiveTitleScale(_ value: Double) {
        if data.bindingType == .hc { data.hcFrontTitleScale = value }
        else { data.frontTitleScale = value }
    }

    private func setActiveAuthorScale(_ value: Double) {
        if data.bindingType == .hc { data.hcFrontAuthorScale = value }
        else { data.frontAuthorScale = value }
    }

    private func resolvedThumbnail() -> NSImage? {
        guard !data.frontCoverImage.isEmpty else { return nil }
        let resolved = ProjectManager.resolveImagePath(data.frontCoverImage, relativeTo: sourceURL)
        return NSImage(contentsOfFile: resolved)
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .heic]
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            data.frontCoverImage = ProjectManager.makeRelativePath(url, relativeTo: sourceURL)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let p = providers.first else { return false }
        p.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            if let d = item as? Data, let url = URL(dataRepresentation: d, relativeTo: nil) {
                let exts = ["png","jpg","jpeg","tiff","tif","bmp","heic","heif"]
                if exts.contains(url.pathExtension.lowercased()) {
                    DispatchQueue.main.async {
                        self.data.frontCoverImage = ProjectManager.makeRelativePath(url, relativeTo: self.sourceURL)
                    }
                }
            }
        }
        return true
    }
}

struct ScaleRow: View {
    let label: String
    @Binding var scale: Double

    init(_ label: String, scale: Binding<Double>) {
        self.label = label
        self._scale = scale
    }

    var body: some View {
        HStack {
            Text(label).frame(width: 50, alignment: .leading)
            Slider(value: $scale, in: 0.25...2.0, step: 0.05)
            TextField("×", value: $scale, format: .number)
                .frame(width: 56)
            Text("×").foregroundColor(.secondary)
        }
    }
}

struct CenterAxisRow: View {
    @Binding var centerX: Bool
    @Binding var centerY: Bool

    var body: some View {
        HStack {
            Text("Center").frame(width: 50, alignment: .leading)
            Toggle("X", isOn: $centerX)
            Toggle("Y", isOn: $centerY)
        }
    }
}

/// Reusable offset row: label + X + Y text fields
struct OffsetRow: View {
    let label: String
    @Binding var ox: Double
    @Binding var oy: Double

    init(_ label: String, ox: Binding<Double>, oy: Binding<Double>) {
        self.label = label; self._ox = ox; self._oy = oy
    }

    var body: some View {
        HStack {
            Text(label).frame(width: 50, alignment: .leading)
            TextField("X (in)", value: $ox, format: .number)
                .frame(width: 100)
            TextField("Y (in)", value: $oy, format: .number)
                .frame(width: 100)
        }
    }
}
