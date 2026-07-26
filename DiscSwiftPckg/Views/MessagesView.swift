import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var viewModel: PackageViewModel
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 38) {
                pageHeader
                totals
                destinations
                analysis
            }
            .padding(.horizontal, 42)
            .padding(.vertical, 36)
        }
        .background(theme.bgPrimary)
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MESSAGES").font(.system(size: 10, weight: .bold)).tracking(1.5).foregroundStyle(theme.accent)
            Text("Message archive").font(.system(size: 30, weight: .bold)).foregroundStyle(theme.textPrimary)
            Text("A structured look at message volume, destinations, vocabulary, and shared links.")
                .font(.system(size: 13)).foregroundStyle(theme.textSecondary)
        }
        .padding(.bottom, 22)
        .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
    }

    private var totals: some View {
        HStack(alignment: .top, spacing: 34) {
            PlainMetric(value: viewModel.formatNumber(viewModel.stats.messageCount), label: "all messages", tint: theme.accent)
            PlainMetric(value: viewModel.formatNumber(viewModel.stats.dmMessages), label: "direct messages", tint: theme.mint)
            PlainMetric(value: viewModel.formatNumber(viewModel.stats.serverMessages), label: "server messages", tint: theme.peach)
            PlainMetric(value: viewModel.formatNumber(viewModel.stats.characterCount), label: "characters", tint: theme.rose)
            PlainMetric(value: viewModel.formatNumber(viewModel.stats.filesUploaded), label: "attachments", tint: theme.sky)
        }
    }

    private var destinations: some View {
        VStack(alignment: .leading, spacing: 18) {
            heading("Most active destinations")
            HStack(alignment: .top, spacing: 52) {
                entityTable("DIRECT MESSAGES", viewModel.stats.topDMs)
                entityTable("SERVERS", viewModel.stats.topServers)
                entityTable("CHANNELS", viewModel.stats.topChannels)
            }
        }
    }

    private var analysis: some View {
        VStack(alignment: .leading, spacing: 18) {
            heading("Content analysis")
            HStack(alignment: .top, spacing: 52) {
                frequencyTable("FREQUENT WORDS", viewModel.stats.topWords)
                frequencyTable("SHARED LINKS", viewModel.stats.topLinks)
                frequencyTable("DISCORD INVITES", viewModel.stats.topDiscordLinks)
            }
        }
    }

    private func heading(_ text: String) -> some View {
        Text(text).font(.system(size: 20, weight: .bold)).foregroundStyle(theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)
            .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
    }

    private func entityTable(_ title: String, _ items: [DetailedStats]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(theme.textSecondary).padding(.bottom, 7)
            ForEach(Array(items.prefix(10).enumerated()), id: \.element.id) { index, item in
                NavigationLikeRow(rank: index + 1, title: item.name, value: viewModel.formatNumber(item.messageCount))
                Divider()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func frequencyTable(_ title: String, _ items: [(word: String, count: Int)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(theme.textSecondary).padding(.bottom, 7)
            ForEach(Array(items.prefix(10).enumerated()), id: \.offset) { index, item in
                NavigationLikeRow(rank: index + 1, title: item.word, value: viewModel.formatNumber(item.count))
                Divider()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct NavigationLikeRow: View {
    @EnvironmentObject private var theme: ThemeManager
    let rank: Int
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 9) {
            Text(String(format: "%02d", rank)).foregroundStyle(theme.accent).frame(width: 24, alignment: .leading)
            Text(title).lineLimit(1).foregroundStyle(theme.textPrimary)
            Spacer()
            Text(value).foregroundStyle(theme.textSecondary)
        }
        .font(.system(size: 12))
        .padding(.vertical, 9)
    }
}
