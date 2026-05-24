import SwiftUI

enum InspectorTab: String, CaseIterable {
    case setup  = "Setup"
    case front  = "Front"
    case fonts  = "Fonts"
    case spine  = "Spine"
    case back   = "Back"
    case yaml   = "YAML"
}

struct InspectorView: View {
    @Binding var data: CoverData
    @Binding var selectedTab: InspectorTab
    let projectRoot: String?
    let onSelectProjectRoot: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(InspectorTab.allCases, id: \.self) { tab in
                    Button(tab.rawValue) { selectedTab = tab }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Divider()

            ScrollView {
                Group {
                    switch selectedTab {
                    case .setup:
                        SetupTab(data: $data, projectRoot: projectRoot, onSelectProjectRoot: onSelectProjectRoot)
                    case .front: FrontTab(data: $data)
                    case .fonts: FontsTab(data: $data)
                    case .spine: SpineTab(data: $data)
                    case .back: BackTab(data: $data)
                    case .yaml: YAMLView(data: data)
                    }
                }
                .padding()
            }
        }
    }
}
