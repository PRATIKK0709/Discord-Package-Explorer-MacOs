import SwiftUI
import UniformTypeIdentifiers

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

enum NavItem: String, CaseIterable {
    case overview = "Overview"
    case messages = "Messages"
    case servers = "Servers"
    case dms = "Direct messages"
    case tickets = "Support"

    var icon: String {
        switch self {
        case .overview: return "circle.grid.2x2"
        case .messages: return "text.bubble"
        case .servers: return "person.3"
        case .dms: return "bubble.left.and.bubble.right"
        case .tickets: return "lifepreserver"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: PackageViewModel
    @EnvironmentObject private var theme: ThemeManager
    @State private var selection: NavItem = .overview
    @State private var isDragOver = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasSeenOnboarding)
            } else if viewModel.hasLoadedData {
                application
            } else {
                importer
            }
        }
        .frame(minWidth: 980, idealWidth: 1240, minHeight: 680, idealHeight: 820)
        .preferredColorScheme(.light)
    }

    private var application: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 210)
                .background(Color.white)
                .overlay(Rectangle().fill(theme.border).frame(width: 1), alignment: .trailing)
            destination
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.accent)
                    Text("DSP")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(theme.textPrimary)
                }
                Text("Discord archive")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)
            .padding(.bottom, 30)

            VStack(spacing: 0) {
                ForEach(NavItem.allCases, id: \.self) { item in
                    Button {
                        selection = item
                    } label: {
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(selection == item ? theme.accent : Color.clear)
                                .frame(width: 2, height: 24)
                            Image(systemName: item.icon)
                                .font(.system(size: 13, weight: .medium))
                                .frame(width: 18)
                            Text(item.rawValue)
                                .font(.system(size: 12, weight: selection == item ? .semibold : .regular))
                            Spacer()
                        }
                        .foregroundStyle(selection == item ? theme.textPrimary : theme.textSecondary)
                        .padding(.trailing, 18)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 14) {
                Divider()
                Label("Local and private", systemImage: "lock.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x4D9B78))
                Button {
                    viewModel.reset()
                    selection = .overview
                } label: {
                    Label("Open another package", systemImage: "arrow.up.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                }
                .buttonStyle(.plain)
                Link(destination: URL(string: "https://github.com/PRATIKK0709/Discord-Package-Explorer-MacOs")!) {
                    Label("Project on GitHub", systemImage: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding(22)
        }
    }

    @ViewBuilder
    private var destination: some View {
        switch selection {
        case .overview: DashboardView()
        case .messages: MessagesView()
        case .servers: ServersView()
        case .dms: DMsView()
        case .tickets: TicketsView(tickets: viewModel.stats.tickets)
        }
    }

    private var importer: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 22) {
                Text("DSP")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(theme.accent)
                Text("Open your\nDiscord archive.")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text("Choose the unzipped package folder. Messages, servers, account history, and activity are analyzed entirely on this Mac.")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.textSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: 400, alignment: .leading)

                Button(action: selectFolder) {
                    Label("Choose a package folder", systemImage: "folder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(theme.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Text("You can also drop the folder anywhere in this window.")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(64)

            VStack(spacing: 16) {
                Image(systemName: isDragOver ? "arrow.down.circle.fill" : "folder")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(isDragOver ? theme.accent : theme.textSecondary.opacity(0.55))
                Text(viewModel.isLoading ? viewModel.loadingStatus : "Drop the package folder here")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                if viewModel.isLoading {
                    ProgressView(value: viewModel.loadingProgress)
                        .tint(theme.accent)
                        .frame(width: 240)
                    Text("\(Int(viewModel.loadingProgress * 100))%")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.lavender.opacity(isDragOver ? 0.7 : 0.3))
        }
        .background(Color.white)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver, perform: handleDrop)
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
            DispatchQueue.main.async { viewModel.scanPackage(at: url) }
        }
        return true
    }
}

#Preview {
    ContentView()
        .environmentObject(PackageViewModel())
        .environmentObject(ThemeManager())
}
