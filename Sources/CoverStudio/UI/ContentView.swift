import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Binding var document: CoverStudioDocument
    @Binding var currentFileURL: URL?

    @State private var previewImage: CGImage?
    @State private var frontCropImage: CGImage?
    @State private var selectedTab: InspectorTab = .setup
    @State private var errorMessage: String?
    @State private var renderTask: Task<Void, Never>?
    @AppStorage("showGuides") private var showGuides: Bool = true
    @State private var showExportPanel: Bool = false
    @State private var coverWidthInches: Double = 9.25
    @State private var coverHeightInches: Double = 12.125
    @State private var currentGeometry: CoverGeometry?
    @AppStorage("projectRoot") private var savedProjectRoot: String = ""
    @AppStorage("selectedTab") private var savedSelectedTab: String = InspectorTab.setup.rawValue

    @State private var undoStack: [CoverData] = []
    @State private var redoStack: [CoverData] = []

    /// Project root derived from the opened file
    var projectRoot: String? {
        if let url = currentFileURL {
            return ProjectManager.projectRoot(for: url).path
        }
        return savedProjectRoot.isEmpty ? nil : savedProjectRoot
    }

    var body: some View {
        NavigationSplitView {
            // Left: Inspector sidebar
            InspectorView(data: Binding(
                get: { document.data },
                set: { newValue in
                    let oldValue = document.data
                    undoStack.append(oldValue)
                    redoStack.removeAll()
                    document.data = newValue
                }
            ), selectedTab: $selectedTab, projectRoot: projectRoot, onSelectProjectRoot: selectProjectRoot)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 480)
                .onChange(of: document.data) { _, _ in
                    scheduleRender()
                }
        } detail: {
            // Right: Live preview
            VStack(spacing: 0) {
                HStack {
                    Toggle("Guides", isOn: $showGuides)
                        .onChange(of: showGuides) { _, _ in scheduleRender() }
                    Spacer()
                    Button("Save", systemImage: "square.and.arrow.down") {
                        saveDocument()
                    }
                    .keyboardShortcut("s", modifiers: .command)
                    Button("Export\u{2026}", systemImage: "square.and.arrow.up") {
                        showExportPanel = true
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(white: 0.12))

                PreviewPane(image: previewImage, errorMessage: errorMessage,
                             widthInches: coverWidthInches, heightInches: coverHeightInches)
            }
        }
        .onAppear {
            if let tab = InspectorTab(rawValue: savedSelectedTab) {
                selectedTab = tab
            }
            // Auto-load cover.yaml from previously persisted project root
            if currentFileURL == nil && !savedProjectRoot.isEmpty {
                autoLoadFromProject()
            }
            scheduleRender()
        }
        .onChange(of: selectedTab) { _, tab in
            savedSelectedTab = tab.rawValue
        }
        .onChange(of: currentFileURL) { _, url in
            if let url {
                savedProjectRoot = ProjectManager.projectRoot(for: url).path
            }
        }
        .fileExporter(
            isPresented: $showExportPanel,
            document: ExportDocument(previewImage: previewImage, frontCropImage: frontCropImage, geometry: currentGeometry),
            contentTypes: [.png, .pdf, .jpeg],
            defaultFilename: "cover"
        ) { _ in }
        .background(KeyboardHandler(
            showGuides: $showGuides,
            showExportPanel: $showExportPanel,
            undoStack: $undoStack,
            redoStack: $redoStack,
            document: $document,
            saveAction: { saveDocument() }
        ))
    }

    private func scheduleRender() {
        renderTask?.cancel()
        renderTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await renderCover()
        }
    }

    private func renderCover() async {
        do {
            let geometry = try computeGeometry(from: document.data)
            let renderer = CoverRenderer(data: document.data, geometry: geometry, sourceURL: currentFileURL)
            previewImage = renderer.renderFullCover(includeGuides: showGuides)
            frontCropImage = renderer.renderFrontCrop()
            coverWidthInches = geometry.totalWidthInches
            coverHeightInches = geometry.totalHeightInches
            currentGeometry = geometry
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            currentGeometry = nil
        }
    }

    private func saveDocument() {
        let targetURL: URL
        
        if let url = currentFileURL {
            targetURL = url
        } else if let root = projectRoot {
            // Derive cover/ folder from project root
            targetURL = ProjectManager.defaultCoverFile(in: URL(fileURLWithPath: root))
            currentFileURL = targetURL
        } else {
            // No file open and no project root — prompt for save location
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.yaml, .json]
            panel.nameFieldStringValue = "cover.yaml"
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    do {
                        try ProjectManager.save(document.data, to: url)
                        currentFileURL = url
                        savedProjectRoot = ProjectManager.projectRoot(for: url).path
                    } catch {
                        let alert = NSAlert()
                        alert.messageText = "Could not save file"
                        alert.informativeText = error.localizedDescription
                        alert.runModal()
                    }
                }
            }
            return
        }
        
        do {
            try ProjectManager.save(document.data, to: targetURL)
            savedProjectRoot = ProjectManager.projectRoot(for: targetURL).path
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not save file"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func selectProjectRoot() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select your book project folder"
        panel.prompt = "Select"
        if panel.runModal() == .OK, let url = panel.url {
            savedProjectRoot = url.path
            // Auto-load cover.yaml / cover.md from the selected project
            autoLoadFromProject()
        }
    }
    /// Auto-load the best available cover file from the project (prefers legacy .md, then .yaml)
    private func autoLoadFromProject() {
        guard let root = projectRoot else { return }
        let loadURL = ProjectManager.preferredCoverFile(in: URL(fileURLWithPath: root))
        
        if let url = loadURL {
            do {
                document.data = try ProjectManager.load(from: url)
                currentFileURL = url
                savedProjectRoot = ProjectManager.projectRoot(for: url).path
            } catch {
                print("Auto-load error: \(error)")
            }
        }
    }
}

// ── Keyboard Shortcuts ───────────────────────────────────────────

struct KeyboardHandler: NSViewRepresentable {
    @Binding var showGuides: Bool
    @Binding var showExportPanel: Bool
    @Binding var undoStack: [CoverData]
    @Binding var redoStack: [CoverData]
    @Binding var document: CoverStudioDocument
    var saveAction: () -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onKeyDown = { event in
            let hasCmd = event.modifierFlags.contains(.command)
            let hasShift = event.modifierFlags.contains(.shift)
            let key = event.charactersIgnoringModifiers

            if hasCmd && !hasShift && key == "g" {
                showGuides.toggle()
            } else if hasCmd && !hasShift && key == "s" {
                saveAction()
            } else if hasCmd && !hasShift && key == "e" {
                showExportPanel = true
            } else if hasCmd && !hasShift && key == "z" {
                if let last = undoStack.popLast() {
                    redoStack.append(document.data)
                    document.data = last
                }
            } else if hasCmd && hasShift && key == "z" {
                if let next = redoStack.popLast() {
                    undoStack.append(document.data)
                    document.data = next
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {}

    class KeyCaptureView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            onKeyDown?(event)
        }
    }
}

// ── Export Wrapper ────────────────────────────────────────────────

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.png, .pdf, .jpeg]

    let previewImage: CGImage?
    let frontCropImage: CGImage?
    let geometry: CoverGeometry?

    init(previewImage: CGImage?, frontCropImage: CGImage?, geometry: CoverGeometry?) {
        self.previewImage = previewImage
        self.frontCropImage = frontCropImage
        self.geometry = geometry
    }

    init(configuration: ReadConfiguration) throws {
        previewImage = nil
        frontCropImage = nil
        geometry = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let contentType = configuration.contentType
        let image: CGImage?
        switch contentType {
        case .jpeg: image = frontCropImage ?? previewImage
        default:    image = previewImage
        }
        guard let image = image else { throw CocoaError(.fileWriteUnknown) }

        let ext = contentType.preferredFilenameExtension ?? ""
        if ext == "pdf" {
            guard let geometry else { throw CocoaError(.fileWriteUnknown) }
            return FileWrapper(regularFileWithContents: try pdfData(
                from: image,
                widthInches: geometry.totalWidthInches,
                heightInches: geometry.totalHeightInches
            ))
        }

        let utiCFString: CFString = (ext == "jpg" || ext == "jpeg")
            ? UTType.jpeg.identifier as CFString
            : UTType.png.identifier as CFString

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, utiCFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(dest, image, [kCGImagePropertyDPIWidth: 300, kCGImagePropertyDPIHeight: 300] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data as Data)
    }

    private func pdfData(from image: CGImage, widthInches: Double, heightInches: Double) throws -> Data {
        let data = NSMutableData()
        var pageRect = CGRect(x: 0, y: 0, width: widthInches * 72.0, height: heightInches * 72.0)

        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &pageRect, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }

        ctx.beginPDFPage(nil)
        ctx.draw(image, in: pageRect)
        ctx.endPDFPage()
        ctx.closePDF()

        return data as Data
    }
}
