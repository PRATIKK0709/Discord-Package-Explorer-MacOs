import SwiftUI

struct ServersView: View {
    @EnvironmentObject var viewModel: PackageViewModel
    @State private var searchText = ""
    
    var filteredServers: [String] {
        if searchText.isEmpty {
            return viewModel.stats.serverNames
        }
        return viewModel.stats.serverNames.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Servers")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.stats.serverCount) total")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 16)
            
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textSecondary)
                TextField("Search servers...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Theme.bgSecondary)
            .cornerRadius(8)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
            
            // Stats row
            HStack(spacing: 16) {
                ServerStatPill(title: "Joined", value: "\(viewModel.stats.serverCount)", icon: "plus.circle.fill", color: .green)
                ServerStatPill(title: "Muted", value: "\(viewModel.stats.mutedServerCount)", icon: "speaker.slash.fill", color: .red)
                ServerStatPill(title: "Channels", value: "\(viewModel.stats.serverChannelCount)", icon: "number", color: .blue)
                ServerStatPill(title: "Messages", value: viewModel.formatNumber(viewModel.stats.serverMessages), icon: "bubble.left.fill", color: .purple)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
            
            // Top Servers
            if !viewModel.stats.topServers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Most Active")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 32)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.stats.topServers.prefix(5), id: \.name) { server in
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Theme.accent.opacity(0.2))
                                            .frame(width: 48, height: 48)
                                        Text(String(server.name.prefix(1)).uppercased())
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(Theme.accent)
                                    }
                                    Text(server.name)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                        .frame(width: 80)
                                    Text("\(server.messageCount)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 16)
            }
            
            // Server list
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                    ForEach(filteredServers, id: \.self) { name in
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.accent.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Text(String(name.prefix(1)).uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                            }
                            
                            Text(name)
                                .font(.system(size: 13))
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .padding(10)
                        .background(Theme.bgSecondary)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .background(Theme.bgPrimary)
    }
}

struct ServerStatPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.bgSecondary)
        .cornerRadius(8)
    }
}

#Preview {
    ServersView()
        .environmentObject(PackageViewModel())
}
