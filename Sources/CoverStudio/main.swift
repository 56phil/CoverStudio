import Foundation

// CoverStudio is a GUI app when launched with no arguments, and a command-line tool
// when given a subcommand. The choice is made here, before any AppKit or SwiftUI
// object exists, so a headless invocation never needs a window server.
//
// The CLI itself is deliberately read-only with respect to the project: it reads
// cover.md and writes only the export the caller names. See CLI.swift.

let cliStatus = CLI.main(arguments: Array(CommandLine.arguments.dropFirst()))
if let cliStatus {
  exit(cliStatus)
}

CoverStudioApp.main()
