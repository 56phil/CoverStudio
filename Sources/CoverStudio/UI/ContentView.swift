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
    @State private var showExportOptions: Bool = false
    @AppStorage("exportPDF") private var exportPDF: Bool = true
    @AppStorage("exportJPG") private var exportJPG: Bool = true
    @AppStorage("exportBaseName") private var exportBaseName: String = "cover"
    @AppStorage("exportPrependBinding") private var exportPrependBinding: Bool = false
    @AppStorage("exportDirectoryPath") private var exportDirectoryPath: String = ""
    @State private var coverWidthInches: Double = 9.25
    @State private var coverHeightInches: Double = 12.125
    @State private var currentGeometry: CoverGeometry?
    @AppStorage("projectRoot") private var savedProjectRoot: String = ""
    @AppStorage("coverFilePath") private var savedCoverFilePath: String = ""
    @AppStorage("selectedTab") private var savedSelectedTab: String = InspectorTab.setup.rawValue

    @Environment(\.undoManager) private var undoManager
    @StateObject private var undoCoordinator = UndoCoordinator()
    @State private var validationIssues: [Validation.Issue] = []
    @State private var previewResetID = UUID()

    /// Project root derived from the opened file
    var projectRoot: String? {
        if let url = currentFileURL {
            return ProjectManager.projectRoot(for: url).path
        }
        return savedProjectRoot.isEmpty ? nil : savedProjectRoot
    }

    private var inspectorIdealWidth: CGFloat {
        max(380, visibleScreenWidth * 0.2)
    }

    private var inspectorMaxWidth: CGFloat {
        max(520, visibleScreenWidth * 0.2)
    }

    private var visibleScreenWidth: CGFloat {
        NSScreen.main?.visibleFrame.width ?? 2400
    }

    var body: some View {
        NavigationSplitView {
            // Left: Inspector sidebar
            InspectorView(data: Binding(
                get: { document.data },
                set: { newValue in
                    let oldValue = document.data
                    document.data = newValue
                    undoCoordinator.register(old: oldValue, new: newValue)
                }
            ), selectedTab: $selectedTab, projectRoot: projectRoot, sourceURL: currentFileURL, onSelectProjectRoot: selectProjectRoot)
                .navigationSplitViewColumnWidth(min: 320, ideal: inspectorIdealWidth, max: inspectorMaxWidth)
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
                    Button("Load", systemImage: "folder") {
                        loadDocument()
                    }
                    Button("Reload", systemImage: "arrow.clockwise") {
                        reloadDocument()
                    }
                    Button("Save", systemImage: "square.and.arrow.down") {
                        saveDocument()
                    }
                    Button("Export\u{2026}", systemImage: "square.and.arrow.up") {
                        openExportOptions()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(white: 0.12))

                PreviewPane(image: previewImage, errorMessage: errorMessage,
                             widthInches: coverWidthInches, heightInches: coverHeightInches)
                    .id(previewResetID)
                StatusLine(data: document.data, projectRoot: projectRoot, validationIssues: validationIssues)
            }
        }
        .onAppear {
            setupUndoCoordinator()
            if let tab = InspectorTab(rawValue: savedSelectedTab) {
                selectedTab = tab
            }
            if currentFileURL == nil {
                autoLoadSavedCover()
            }
            scheduleRender()
        }
        .onChange(of: selectedTab) { _, tab in
            savedSelectedTab = tab.rawValue
        }
        .onChange(of: currentFileURL) { _, url in
            if let url {
                persistCurrentCoverFile(url)
            }
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsSheet(
                exportPDF: $exportPDF,
                exportJPG: $exportJPG,
                baseName: $exportBaseName,
                prependBinding: $exportPrependBinding,
                bindingPrefix: document.data.bindingType.rawValue,
                directoryPath: $exportDirectoryPath,
                onExport: exportSelectedFormats,
                onCancel: { showExportOptions = false }
            )
        }
        .background(KeyboardHandler(
            showGuides: $showGuides,
            saveAction: { saveDocument() },
            exportAction: { openExportOptions() }
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
        validationIssues = Validation.validate(document.data, sourceURL: currentFileURL)
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
        commitPendingFieldEdits()
        DispatchQueue.main.async {
            saveCommittedDocument()
        }
    }

    private func commitPendingFieldEdits() {
        NSApp.keyWindow?.makeFirstResponder(nil)
    }

    private func loadDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = ProjectManager.coverContentTypes
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if let url = currentFileURL {
            panel.directoryURL = url.deletingLastPathComponent()
        } else if !savedProjectRoot.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: savedProjectRoot).appendingPathComponent("cover", isDirectory: true)
        }

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try loadCoverFile(url)
                scheduleRender()
            } catch {
                let alert = NSAlert()
                alert.messageText = "Could not load file"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }

    private func reloadDocument() {
        let reloadURL: URL?
        if let url = currentFileURL {
            reloadURL = url
        } else if !savedCoverFilePath.isEmpty {
            reloadURL = URL(fileURLWithPath: savedCoverFilePath)
        } else {
            reloadURL = nil
        }

        guard let url = reloadURL else {
            autoLoadSavedCover()
            return
        }

        if undoManager?.canUndo == true {
            let alert = NSAlert()
            alert.messageText = "Reload from disk?"
            alert.informativeText = "Any unsaved changes will be lost."
            alert.addButton(withTitle: "Reload")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }

        do {
            try loadCoverFile(url)
            scheduleRender()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not reload file"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func saveCommittedDocument() {
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
            panel.allowedContentTypes = ProjectManager.coverContentTypes
            panel.nameFieldStringValue = "cover.md"
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    do {
                        try ProjectManager.save(document.data, to: url)
                        currentFileURL = url
                        persistCurrentCoverFile(url)
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
            persistCurrentCoverFile(targetURL)
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
            savedCoverFilePath = ""
            currentFileURL = nil
            autoLoadFromProject()
        }
    }

    private func autoLoadSavedCover() {
        if !savedCoverFilePath.isEmpty {
            let url = URL(fileURLWithPath: savedCoverFilePath)
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try loadCoverFile(url)
                    return
                } catch {
                    print("Saved cover load error: \(error)")
                }
            }
        }

        if !savedProjectRoot.isEmpty {
            autoLoadFromProject()
        }
    }

    /// Auto-load the best available cover file from the project (prefers legacy .md, then .yaml)
    private func autoLoadFromProject() {
        guard let root = projectRoot else { return }
        let loadURL = ProjectManager.preferredCoverFile(in: URL(fileURLWithPath: root))
        
        if let url = loadURL {
            do {
                try loadCoverFile(url)
            } catch {
                print("Auto-load error: \(error)")
            }
        }
    }

    private func loadCoverFile(_ url: URL) throws {
        document.data = try ProjectManager.load(from: url)
        currentFileURL = url
        previewResetID = UUID()
        undoCoordinator.undoManager?.removeAllActions()
        persistCurrentCoverFile(url)
    }

    private func setupUndoCoordinator() {
        undoCoordinator.undoManager = undoManager
        let binding = $document
        undoCoordinator.apply = { data in
            binding.wrappedValue.data = data
        }
    }

    private func persistCurrentCoverFile(_ url: URL) {
        savedCoverFilePath = url.path
        savedProjectRoot = ProjectManager.projectRoot(for: url).path
    }

    private func openExportOptions() {
        commitPendingFieldEdits()
        if exportDirectoryPath.isEmpty {
            exportDirectoryPath = defaultExportDirectory().path
        }
        if exportBaseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            exportBaseName = "cover"
        }
        showExportOptions = true
    }

    private func defaultExportDirectory() -> URL {
        if let currentFileURL {
            return currentFileURL.deletingLastPathComponent()
        }
        if let root = projectRoot {
            return URL(fileURLWithPath: root).appendingPathComponent("cover", isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    private func exportSelectedFormats() {
        commitPendingFieldEdits()

        guard exportPDF || exportJPG else {
            showAlert(title: "Choose an export format", message: "Select PDF, JPG, or both.")
            return
        }

        let trimmedBaseName = exportBaseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBaseName.isEmpty else {
            showAlert(title: "Missing filename", message: "Enter a base filename for the exported files.")
            return
        }
        let outputBaseName = exportPrependBinding
            ? "\(document.data.bindingType.rawValue)-\(trimmedBaseName)"
            : trimmedBaseName

        let directory = exportDirectoryPath.isEmpty
            ? defaultExportDirectory()
            : URL(fileURLWithPath: exportDirectoryPath)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let geometry = try computeGeometry(from: document.data)
            let renderer = CoverRenderer(data: document.data, geometry: geometry, sourceURL: currentFileURL)
            guard let fullImage = renderer.renderFullCover(includeGuides: false) else {
                throw CocoaError(.fileWriteUnknown)
            }

            var exported: [URL] = []
            if exportPDF {
                let pdfURL = directory.appendingPathComponent("\(outputBaseName).pdf")
                try CoverExporter.exportPDF(
                    image: fullImage,
                    widthInches: geometry.totalWidthInches,
                    heightInches: geometry.totalHeightInches,
                    to: pdfURL
                )
                exported.append(pdfURL)
            }

            if exportJPG {
                guard let frontImage = renderer.renderFrontCrop() else {
                    throw CocoaError(.fileWriteUnknown)
                }
                let jpgURL = directory.appendingPathComponent("\(outputBaseName).jpg")
                try CoverExporter.exportJPG(image: frontImage, to: jpgURL)
                exported.append(jpgURL)
            }

            showExportOptions = false
            let names = exported.map(\.lastPathComponent).joined(separator: "\n")
            showAlert(title: "Export complete", message: names)
        } catch {
            showAlert(title: "Could not export cover", message: error.localizedDescription)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}

struct StatusLine: View {
    let data: CoverData
    let projectRoot: String?
    let validationIssues: [Validation.Issue]

    private var errorCount: Int   { validationIssues.filter { $0.severity == .error   }.count }
    private var warningCount: Int { validationIssues.filter { $0.severity == .warning }.count }

    var body: some View {
        HStack(spacing: 14) {
            Label(projectRoot ?? "No project loaded", systemImage: "folder")
                .lineLimit(1)
                .truncationMode(.middle)
                .help(projectRoot ?? "No project loaded")
                .layoutPriority(1)

            Divider().frame(height: 14)
            Text(data.bindingType.label)
            Text(data.trimSize.label)
            Text(data.uiUnits.label)

            if errorCount > 0 {
                Divider().frame(height: 14)
                Label("\(errorCount) error\(errorCount == 1 ? "" : "s")",
                      systemImage: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .help(validationIssues.filter { $0.severity == .error }
                        .map { "\($0.field): \($0.message)" }.joined(separator: "\n"))
            }
            if warningCount > 0 {
                Divider().frame(height: 14)
                Label("\(warningCount) warning\(warningCount == 1 ? "" : "s")",
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .help(validationIssues.filter { $0.severity == .warning }
                        .map { "\($0.field): \($0.message)" }.joined(separator: "\n"))
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.09))
    }
}

// ── Keyboard Shortcuts ───────────────────────────────────────────

struct KeyboardHandler: NSViewRepresentable {
    @Binding var showGuides: Bool
    var saveAction: () -> Void
    var exportAction: () -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onKeyDown = { event in
            let hasCmd = event.modifierFlags.contains(.command)
            let hasShift = event.modifierFlags.contains(.shift)
            let key = event.charactersIgnoringModifiers

            if hasCmd && !hasShift && key == "g" {
                showGuides.toggle()
                return true
            } else if hasCmd && !hasShift && key == "s" {
                saveAction()
                return true
            } else if hasCmd && !hasShift && key == "e" {
                exportAction()
                return true
            }
            return false
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {}

    class KeyCaptureView: NSView {
        var onKeyDown: ((NSEvent) -> Bool)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            let handled = onKeyDown?(event) ?? false
            if !handled { super.keyDown(with: event) }
        }
    }
}

// ── Export Options ────────────────────────────────────────────────

struct ExportOptionsSheet: View {
    @Binding var exportPDF: Bool
    @Binding var exportJPG: Bool
    @Binding var baseName: String
    @Binding var prependBinding: Bool
    let bindingPrefix: String
    @Binding var directoryPath: String
    var onExport: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Export Cover")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Toggle("PDF full cover", isOn: $exportPDF)
                Toggle("JPG front cover", isOn: $exportJPG)
            }

            HStack {
                Text("Name").frame(width: 64, alignment: .leading)
                TextField("cover", text: $baseName)
                    .textFieldStyle(.roundedBorder)
            }
            Toggle("Prepend \(bindingPrefix)- to filename", isOn: $prependBinding)

            HStack {
                Text("Folder").frame(width: 64, alignment: .leading)
                TextField("Output folder", text: $directoryPath)
                    .textFieldStyle(.roundedBorder)
                    .truncationMode(.middle)
                Button("Choose\u{2026}") {
                    chooseDirectory()
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Export", action: onExport)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!exportPDF && !exportJPG)
            }
        }
        .padding(18)
        .frame(minWidth: 520)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        if !directoryPath.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: directoryPath)
        }
        if panel.runModal() == .OK, let url = panel.url {
            directoryPath = url.path
        }
    }
}

// ── Undo Coordinator ─────────────────────────────────────────────

final class UndoCoordinator: NSObject, ObservableObject {
    weak var undoManager: UndoManager?
    var apply: ((CoverData) -> Void)?

    func register(old: CoverData, new: CoverData) {
        undoManager?.registerUndo(withTarget: self) { coordinator in
            coordinator.apply?(old)
            coordinator.register(old: new, new: old)
        }
        undoManager?.setActionName("Cover Edit")
    }
}
