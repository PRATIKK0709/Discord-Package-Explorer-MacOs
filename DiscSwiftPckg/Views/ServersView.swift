import SwiftUI

struct ServersView: View {
    @EnvironmentObject private var viewModel: PackageViewModel
    @EnvironmentObject private var theme: ThemeManager
    @State private var searchText = ""

    private var servers: [(name: String, messageCount: Int)] {
        searchText.isEmpty
            ? viewModel.stats.serverList
            : viewModel.stats.serverList.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            DirectoryHeader(
                eyebrow: "COMMUNITIES",
                title: "Servers",
                subtitle: serverSummary,
                searchPrompt: "Search servers",
                searchText: $searchText
            )

            DirectoryColumnLabels(primary: "SERVER", secondary: "MESSAGES")

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(servers.enumerated()), id: \.element.name) { index, server in
                        ArchiveDirectoryRow(
                            rank: index + 1,
                            name: server.name,
                            count: server.messageCount,
                            maximum: viewModel.stats.serverList.first?.messageCount ?? 1,
                            tint: index < 3 ? theme.accent : Color(hex: 0xAAB7C8)
                        )
                    }
                }
                .padding(.horizontal, 42)
                .padding(.bottom, 38)
            }
        }
        .background(theme.bgPrimary)
    }

    private var serverSummary: String {
        let count = viewModel.stats.serverList.count
        let noun = count == 1 ? "server" : "servers"
        return "\(count.formatted()) \(noun) · \(viewModel.formatNumber(viewModel.stats.serverMessages)) messages"
    }
}

struct DirectoryHeader: View {
    @EnvironmentObject private var theme: ThemeManager
    let eyebrow: String
    let title: String
    let subtitle: String
    let searchPrompt: String
    @Binding var searchText: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 30) {
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(theme.accent)
                Text(title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
                TextField(searchPrompt, text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .frame(width: 250)
            .padding(.vertical, 8)
            .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        }
        .padding(.horizontal, 42)
        .padding(.top, 36)
        .padding(.bottom, 24)
    }
}

struct DirectoryColumnLabels: View {
    @EnvironmentObject private var theme: ThemeManager
    let primary: String
    let secondary: String
    var body: some View {
        HStack {
            Text("#").frame(width: 36, alignment: .leading)
            Text(primary)
            Spacer()
            Text(secondary).frame(width: 100, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .bold))
        .tracking(1)
        .foregroundStyle(theme.textSecondary)
        .padding(.horizontal, 42)
        .padding(.vertical, 10)
        .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
    }
}

struct ArchiveDirectoryRow: View {
    @EnvironmentObject private var theme: ThemeManager
    let rank: Int
    let name: String
    let count: Int
    let maximum: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 0) {
            Text(String(format: "%02d", rank))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(rank <= 3 ? theme.accent : theme.textSecondary)
                .frame(width: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 7) {
                Text(name)
                    .font(.system(size: 13, weight: rank <= 3 ? .semibold : .regular))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                GeometryReader { proxy in
                    Rectangle()
                        .fill(tint.opacity(0.55))
                        .frame(width: proxy.size.width * CGFloat(count) / CGFloat(max(1, maximum)), height: 2)
                }
                .frame(height: 2)
            }

            Text(count.formatted())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 13)
        .overlay(Rectangle().fill(theme.border.opacity(0.75)).frame(height: 1), alignment: .bottom)
    }
}
