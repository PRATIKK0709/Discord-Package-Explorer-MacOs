import SwiftUI
import UniformTypeIdentifiers

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
    case dms = "DMs"
    case tickets = "Tickets"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .messages: return "bubble.left.and.bubble.right"
        case .servers: return "server.rack"
        case .dms: return "person.2.fill"
        case .tickets: return "ticket"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var viewModel: PackageViewModel
    @EnvironmentObject var theme: ThemeManager
    @State private var selectedNav: NavItem = .dashboard
    @State private var isDragOver = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasSeenOnboarding)
            } else if viewModel.hasLoadedData {
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
                .background(theme.bgSecondary)
                .overlay(
                    Rectangle().fill(theme.border).frame(width: 1),
                    alignment: .trailing
                )
            
            // Content
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.bgPrimary)
        }
    }
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accent)
                Text("DISCORD DATA")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.textSecondary)
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
                .fill(theme.border)
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
                .foregroundStyle(theme.textSecondary)
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
        case .dms:
            DMsView()
        case .tickets:
            TicketsView(tickets: viewModel.stats.tickets)
        case .settings:
            SettingsView()
        }
    }
    
    // MARK: - Drop Zone (Onboarding)
    
    private var dropZone: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Main Onboarding Card
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(theme.accent)
                }
                
                VStack(spacing: 12) {
                    Text("Welcome to Package Explorer")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    
                    Text("Visualize and analyze your Discord Data Package.\nDrag and drop your 'package' folder to get started.")
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: 400)
                }
                
                // Drop Area
                Button {
                    selectFolder()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .foregroundStyle(isDragOver ? theme.accent : theme.border)
                            .background(isDragOver ? theme.accent.opacity(0.05) : Color.clear)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 18))
                            Text("Select Package Folder")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(isDragOver ? theme.accent : theme.textPrimary)
                    }
                    .frame(width: 280, height: 64)
                }
                .buttonStyle(.plain)
                .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                    handleDrop(providers)
                }
            }
            .padding(40)
            .background(theme.bgSecondary)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
            
            // Loading State
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView(value: viewModel.loadingProgress)
                        .frame(width: 200)
                        .tint(theme.accent)
                    
                    Text(viewModel.loadingStatus)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.textSecondary)
                }
                .transition(.opacity)
            }
            
            Spacer()
            
            // Footer
            HStack(spacing: 6) {
                Text("Open Source Project")
                Link("View on GitHub", destination: URL(string: "https://github.com/PRATIKK0709/Discord-Package-Explorer-MacOs")!)
                    .underline()
            }
            .font(.system(size: 12))
            .foregroundStyle(theme.textSecondary)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bgPrimary)
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
    @EnvironmentObject var theme: ThemeManager
    let item: NavItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? theme.accent : theme.textSecondary)
                
                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? theme.bgTertiary : .clear)
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
