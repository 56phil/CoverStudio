import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct CoverStudioApp: App {
    @State private var document = CoverStudioDocument()
    @State private var fileURL: URL?

    var body: some Scene {
        WindowGroup("Cover Studio") {
            ContentView(document: $document, currentFileURL: $fileURL)
                .frame(minWidth: 900, minHeight: 680)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open\u{2026}") {
                    openDocument()
                }
                .keyboardShortcut("o", modifiers: .command)
                Divider()
                Button("New from Template\u{2026}") {
                    document = CoverStudioDocument()
                    fileURL = nil
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = ProjectManager.coverContentTypes
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                document.data = try ProjectManager.load(from: url)
                fileURL = url
            } catch {
                let alert = NSAlert()
                alert.messageText = "Could not open file"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }
}
