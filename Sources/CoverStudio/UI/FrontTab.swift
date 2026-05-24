import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FrontTab: View {
    @Binding var data: CoverData
    @State private var isDropTargeted: Bool = false

    var body: some View {
        Form {
            Section("Scale") {
                VStack(spacing: 2) {
                    HStack {
                        Slider(value: Binding(
                            get: { data.resolvedTitleScale() },
                            set: { newValue in
                                setActiveTitleScale(newValue)
                                setActiveAuthorScale(newValue)
                            }
                        ), in: 0.5...2.5, step: 0.05)
                        Text(String(format: "%.2f", data.resolvedTitleScale()))
                            .font(.caption.monospacedDigit())
                            .frame(width: 36)
                    }
                    Text("Applies to both title and author")
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
                        if !data.frontCoverImage.isEmpty, let ns = NSImage(contentsOfFile: data.frontCoverImage) {
                            Image(nsImage: ns).resizable().aspectRatio(contentMode: .fit).frame(height: 80).cornerRadius(6)
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle").font(.system(size: 24))
                                    .foregroundColor(.secondary.opacity(isDropTargeted ? 0.8 : 0.4))
                                Text("Drop image here").font(.caption).foregroundColor(.secondary)
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
                OffsetRow("Offset", ox: activeTitleOffsetX, oy: activeTitleOffsetY)
            }

            Section("Subtitle") {
                TextField(text: $data.subtitle, prompt: Text("Subtitle (optional)")) { Text("Subtitle") }
                OffsetRow("Offset", ox: activeSubtitleOffsetX, oy: activeSubtitleOffsetY)
            }

            Section("Author") {
                TextField(text: $data.authorName, prompt: Text("Author Name")) { Text("Author") }
                OffsetRow("Offset", ox: activeAuthorOffsetX, oy: activeAuthorOffsetY)
            }

            Section("Author Photo") {
                HStack {
                    TextField("Photo path (optional)", text: $data.authorPhoto).truncationMode(.middle)
                    Button("Choose\u{2026}") { chooseAuthorPhoto() }.buttonStyle(.borderless).controlSize(.small)
                }
                OffsetRow("Position", ox: $data.authorPhotoOffsetXInches, oy: $data.authorPhotoOffsetYInches)
                HStack {
                    Text("Size (in)").frame(width: 50, alignment: .leading)
                    TextField("", value: $data.authorPhotoScaleInches, format: .number).frame(width: 80)
                }
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

    private func setActiveTitleScale(_ value: Double) {
        if data.bindingType == .hc { data.hcFrontTitleScale = value }
        else { data.frontTitleScale = value }
    }

    private func setActiveAuthorScale(_ value: Double) {
        if data.bindingType == .hc { data.hcFrontAuthorScale = value }
        else { data.frontAuthorScale = value }
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .heic]
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { data.frontCoverImage = url.path }
    }

    private func chooseAuthorPhoto() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .heic]
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { data.authorPhoto = url.path }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let p = providers.first else { return false }
        p.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            if let d = item as? Data, let url = URL(dataRepresentation: d, relativeTo: nil) {
                let exts = ["png","jpg","jpeg","tiff","tif","bmp","heic","heif"]
                if exts.contains(url.pathExtension.lowercased()) {
                    DispatchQueue.main.async { self.data.frontCoverImage = url.path }
                }
            }
        }
        return true
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
