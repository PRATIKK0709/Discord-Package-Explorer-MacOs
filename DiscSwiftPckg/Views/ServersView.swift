import SwiftUI

struct ServersView: View {
    @EnvironmentObject var viewModel: PackageViewModel
    @State private var searchText = ""
    
    var filteredServers: [(name: String, messageCount: Int)] {
        let list = viewModel.stats.serverList
        if searchText.isEmpty {
            return list
        }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Servers")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.stats.serverList.count) total")
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
                                            .fill(Theme.accent.opacity(0.1))
                                            .frame(width: 48, height: 48)
                                        Text(String(server.name.prefix(1)).uppercased())
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(Theme.accent)
                                    }
                                    Text(server.name)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                        .frame(width: 80)
                                    Text(viewModel.formatNumber(server.messageCount))
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
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                    ForEach(filteredServers, id: \.name) { server in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.bgSecondary)
                                    .frame(width: 44, height: 44)
                                Text(String(server.name.prefix(1)).uppercased())
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(server.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)
                                
                                Text("\(viewModel.formatNumber(server.messageCount)) messages")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        //.background(Theme.bgSecondary) // Using overlay border mostly or plain bg
                        .background(Color.white) // Card look
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Theme.border, lineWidth: 1)
                        )
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
