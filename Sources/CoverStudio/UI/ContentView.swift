import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Binding var document: CoverStudioDocument
    @Binding var currentFileURL: URL?

    @State private var selectedTab: InspectorTab = .setup
    @AppStorage("showGuides") private var showGuides: Bool = true
    @State private var showExportOptions: Bool = false
    @AppStorage("exportPDF") private var exportPDF: Bool = true
    @AppStorage("exportPNG") private var exportPNG: Bool = false
    @AppStorage("exportJPG") private var exportJPG: Bool = true
    @AppStorage("exportBaseName") private var exportBaseName: String = "cover"
    @AppStorage("exportPrependBinding") private var exportPrependBinding: Bool = false
    @AppStorage("exportDirectoryPath") private var exportDirectoryPath: String = ""
    @AppStorage("projectRoot") private var savedProjectRoot: String = ""
    @AppStorage("coverFilePath") private var savedCoverFilePath: String = ""
    @AppStorage("selectedTab") private var savedSelectedTab: String = InspectorTab.setup.rawValue

    @Environment(\.undoManager) private var undoManager
    @StateObject private var undoCoordinator = UndoCoordinator()
    @State private var previewResetID = UUID()
    @State private var savedData: CoverData?

    private var isDirty: Bool {
        guard let savedData else { return false }
        return savedData != document.data
    }

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
        } detail: {
            // Right: Live preview — isolated so render-state changes don't re-render InspectorView
            PreviewDetailView(
                data: document.data,
                showGuides: $showGuides,
                sourceURL: currentFileURL,
                projectRoot: projectRoot,
                resetID: previewResetID,
                onLoad: loadDocument,
                onReload: reloadDocument,
                onSave: saveDocument,
                onExport: openExportOptions
            )
        }
        .onAppear {
            setupUndoCoordinator()
            if let tab = InspectorTab(rawValue: savedSelectedTab) {
                selectedTab = tab
            }
            if currentFileURL == nil {
                autoLoadSavedCover()
            }
        }
        .onChange(of: selectedTab) { _, tab in
            savedSelectedTab = tab.rawValue
        }
        .onChange(of: isDirty) { _, dirty in
            NSApp.keyWindow?.isDocumentEdited = dirty
        }
        .onChange(of: currentFileURL) { _, url in
            if let url {
                persistCurrentCoverFile(url)
            }
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsSheet(
                exportPDF: $exportPDF,
                exportPNG: $exportPNG,
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
            selectedTab: $selectedTab,
            saveAction: { saveDocument() },
            exportAction: { openExportOptions() }
        ))
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
                        savedData = document.data
                        NSApp.keyWindow?.isDocumentEdited = false
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
            savedData = document.data
            NSApp.keyWindow?.isDocumentEdited = false
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
        savedData = document.data
        NSApp.keyWindow?.isDocumentEdited = false
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

        guard exportPDF || exportPNG || exportJPG else {
            showAlert(title: "Choose an export format", message: "Select at least one format.")
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

            var exported: [URL] = []
            if exportPDF || exportPNG {
                guard let fullImage = renderer.renderFullCover(includeGuides: false) else {
                    throw CocoaError(.fileWriteUnknown)
                }
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
                if exportPNG {
                    let pngURL = directory.appendingPathComponent("\(outputBaseName).png")
                    try CoverExporter.exportPNG(image: fullImage, to: pngURL)
                    exported.append(pngURL)
                }
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

// ── PreviewDetailView ────────────────────────────────────────────────────────
// Isolated child view that owns all render state so that completing a render
// does not re-run ContentView.body and does not disrupt focused TextFields in
// InspectorView.
private struct PreviewDetailView: View {
    let data: CoverData
    @Binding var showGuides: Bool
    let sourceURL: URL?
    let projectRoot: String?
    let resetID: UUID
    var onLoad: () -> Void
    var onReload: () -> Void
    var onSave: () -> Void
    var onExport: () -> Void

    @State private var previewImage: CGImage?
    @State private var renderTask: Task<Void, Never>?
    @State private var coverWidthInches: Double = 9.25
    @State private var coverHeightInches: Double = 12.125
    @State private var errorMessage: String?
    @State private var validationIssues: [Validation.Issue] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle("Guides", isOn: $showGuides)
                Spacer()
                Button("Load", systemImage: "folder") { onLoad() }
                Button("Reload", systemImage: "arrow.clockwise") { onReload() }
                Button("Save", systemImage: "square.and.arrow.down") { onSave() }
                Button("Export\u{2026}", systemImage: "square.and.arrow.up") { onExport() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(white: 0.12))

            PreviewPane(image: previewImage, errorMessage: errorMessage,
                        widthInches: coverWidthInches, heightInches: coverHeightInches)
                .id(resetID)
            StatusLine(data: data, projectRoot: projectRoot, validationIssues: validationIssues)
        }
        .onChange(of: data) { _, _ in scheduleRender() }
        .onChange(of: showGuides) { _, _ in scheduleRender() }
        .onAppear { scheduleRender() }
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
        let capturedData = data
        let capturedSourceURL = sourceURL
        let guides = showGuides

        validationIssues = Validation.validate(capturedData, sourceURL: capturedSourceURL)
        do {
            let geometry = try computeGeometry(from: capturedData)
            let renderer = CoverRenderer(data: capturedData, geometry: geometry, sourceURL: capturedSourceURL)

            let image: CGImage? = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    continuation.resume(returning: renderer.renderFullCover(includeGuides: guides))
                }
            }

            guard !Task.isCancelled else { return }
            previewImage = image
            coverWidthInches = geometry.totalWidthInches
            coverHeightInches = geometry.totalHeightInches
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
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
    @Binding var selectedTab: InspectorTab
    var saveAction: () -> Void
    var exportAction: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            context.coordinator.handle(event)
        }
        return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.showGuides   = { showGuides }
        context.coordinator.setGuides    = { showGuides = $0 }
        context.coordinator.getTab       = { selectedTab }
        context.coordinator.setTab       = { selectedTab = $0 }
        context.coordinator.saveAction   = saveAction
        context.coordinator.exportAction = exportAction
    }

    final class Coordinator {
        var monitor: Any?
        var showGuides:   () -> Bool             = { false }
        var setGuides:    (Bool) -> Void         = { _ in }
        var getTab:       () -> InspectorTab     = { .setup }
        var setTab:       (InspectorTab) -> Void = { _ in }
        var saveAction:   () -> Void             = {}
        var exportAction: () -> Void             = {}

        func handle(_ event: NSEvent) -> NSEvent? {
            let flags   = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let key     = event.charactersIgnoringModifiers
            let cmdOnly = flags == .command

            if cmdOnly && key == "g" {
                setGuides(!showGuides()); return nil
            } else if cmdOnly && key == "s" {
                saveAction(); return nil
            } else if cmdOnly && key == "e" {
                exportAction(); return nil
            } else if cmdOnly && key == "[" {
                setTab(getTab().previous()); return nil
            } else if cmdOnly && key == "]" {
                setTab(getTab().next()); return nil
            } else if cmdOnly, let key, let digit = Int(key),
                      digit >= 1 && digit <= InspectorTab.allCases.count {
                setTab(InspectorTab.allCases[digit - 1]); return nil
            }
            return event
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}

// ── Export Options ────────────────────────────────────────────────

struct ExportOptionsSheet: View {
    @Binding var exportPDF: Bool
    @Binding var exportPNG: Bool
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
                Toggle("PNG full cover", isOn: $exportPNG)
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
                    .disabled(!exportPDF && !exportPNG && !exportJPG)
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
