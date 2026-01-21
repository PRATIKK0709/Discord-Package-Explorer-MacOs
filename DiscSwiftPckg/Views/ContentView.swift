import SwiftUI
import UniformTypeIdentifiers

// MARK: - Theme Colors (Keysly White Theme)

struct Theme {
    static let bgPrimary = Color(hex: 0xFFFFFF)
    static let bgSecondary = Color(hex: 0xF5F5F7)
    static let bgTertiary = Color(hex: 0xE5E5EB)
    static let textPrimary = Color(hex: 0x000000)
    static let textSecondary = Color(hex: 0x6E6E73)
    static let accent = Color(hex: 0xFF9500)
    static let border = Color.black.opacity(0.08)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Navigation

enum NavItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case messages = "Messages"

    case servers = "Servers"
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .messages: return "bubble.left.and.bubble.right"

        case .servers: return "server.rack"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var viewModel: PackageViewModel
    @State private var selectedNav: NavItem = .dashboard
    @State private var isDragOver = false
    
    var body: some View {
        Group {
            if viewModel.hasLoadedData {
                mainView
            } else {
                dropZone
            }
        }

        .frame(width: 1050, height: 750)
        .preferredColorScheme(.light)
    }
    
    // MARK: - Main View
    
    private var mainView: some View {
        HStack(spacing: 0) {
            // Sidebar
            sidebar
                .frame(width: 200)
                .frame(minWidth: 200, maxWidth: 200)
                .layoutPriority(1)
                .background(Theme.bgSecondary)
                .overlay(
                    Rectangle().fill(Theme.border).frame(width: 1),
                    alignment: .trailing
                )
            
            // Content
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bgPrimary)
        }
    }
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent)
                Text("DISCORD DATA")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Navigation Group
            VStack(spacing: 4) {
                ForEach(NavItem.allCases, id: \.self) { item in
                    PluginNavItem(item: item, isSelected: selectedNav == item) {
                        selectedNav = item
                    }
                }
            }
            .padding(.horizontal, 10)
            
            // Divider
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            
            // Reset / Load New Button
            Button {
                viewModel.reset()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14))
                    Text("Load New Package")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            
            Spacer()
        }
    }

    
    @ViewBuilder
    private var mainContent: some View {
        switch selectedNav {
        case .dashboard:
            DashboardView()
        case .messages:
            MessagesView()

        case .servers:
            ServersView()
        }
    }
    
    // MARK: - Drop Zone
    
    private var dropZone: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .foregroundStyle(isDragOver ? Theme.accent : Theme.textSecondary.opacity(0.3))
                    .frame(width: 360, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isDragOver ? Theme.accent.opacity(0.05) : .clear)
                    )
                
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(isDragOver ? Theme.accent : Theme.textSecondary)
                    
                    VStack(spacing: 4) {
                        Text("Drop Discord Data Package")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Drag your 'package' folder here")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    
                    Button("Choose Folder") {
                        selectFolder()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                handleDrop(providers)
            }
            
            // Loading
            if viewModel.isLoading {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.loadingProgress)
                        .frame(width: 300)
                        .tint(Theme.accent)
                    HStack {
                        Text(viewModel.loadingStatus)
                        Spacer()
                        Text("\(Int(viewModel.loadingProgress * 100))%")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 300)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.scanPackage(at: url)
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                viewModel.scanPackage(at: url)
            }
        }
        return true
    }
}

struct PluginNavItem: View {
    let item: NavItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                
                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.bgTertiary : .clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    ContentView()
        .environmentObject(PackageViewModel())
        .frame(width: 1000, height: 700)
}
