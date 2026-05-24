import SwiftUI
import AppKit

struct PreviewPane: View {
    let image: CGImage?
    let errorMessage: String?
    let widthInches: Double
    let heightInches: Double

    @State private var zoom: Double = 0  // 0 = fit-to-window, >0 = scale factor

    // Physical DPI of the current display
    var screenDPI: CGFloat {
        NSScreen.main.map { screen in
            let desc = screen.deviceDescription
            let size = (desc[.size] as? NSValue)?.sizeValue ?? NSSize.zero
            let frame = screen.frame
            // PPI = horizontal pixels / physical width in inches
            guard frame.width > 0, size.width > 0 else { return 72.0 }
            return frame.width / (size.width / 25.4) // mm → inches
        } ?? 72.0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Zoom toolbar
            HStack(spacing: 8) {
                Button("Fit") { zoom = 0 }
                    .buttonStyle(.borderless)
                    .font(.caption.weight(zoom == 0 ? .bold : .regular))
                    .foregroundColor(zoom == 0 ? .accentColor : .secondary)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(zoom == 0 ? Color.accentColor.opacity(0.15) : Color.clear)
                    .cornerRadius(4)

                Button("100%") { zoom = screenDPI / 300.0 }
                    .buttonStyle(.borderless)
                    .font(.caption.weight(zoom == screenDPI / 300.0 ? .bold : .regular))
                    .foregroundColor(zoom == screenDPI / 300.0 ? .accentColor : .secondary)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(zoom == screenDPI / 300.0 ? Color.accentColor.opacity(0.15) : Color.clear)
                    .cornerRadius(4)

                Slider(value: Binding(
                    get: { max(0.05, zoom == 0 ? 0.20 : zoom) },
                    set: { zoom = $0 }
                ), in: 0.05...4.0, step: 0.01)
                    .frame(width: 120)

                Text(zoom == 0 ? "Fit" : String(format: "%.0f%%", zoom / (screenDPI / 300.0) * 100))
                    .font(.caption.monospacedDigit())
                    .frame(width: 48)

                Spacer()

                if let image = image {
                    Text("\(image.width)×\(image.height) px | \(String(format: "%.2f", widthInches))×\(String(format: "%.2f", heightInches)) in")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 4)
            .background(Color(white: 0.08))

            // Preview content
            GeometryReader { geo in
                Group {
                    if let image = image {
                        let fitScale = min(geo.size.width / CGFloat(image.width),
                                           geo.size.height / CGFloat(image.height))
                        let effectiveScale = zoom == 0 ? fitScale : zoom

                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            Image(image, scale: 1, label: Text("Cover preview"))
                                .resizable()
                                .frame(width: CGFloat(image.width) * effectiveScale,
                                       height: CGFloat(image.height) * effectiveScale)
                                .padding(zoom == 0 ? 0 : 8)
                        }
                    } else if let error = errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundColor(.orange)
                            Text("Render error").font(.headline)
                            Text(error).font(.caption).foregroundColor(.secondary)
                        }
                    } else {
                        ProgressView("Rendering\u{2026}")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(white: 0.15))
        }
    }
}
