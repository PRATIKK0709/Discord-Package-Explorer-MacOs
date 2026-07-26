import SwiftUI

struct DMsView: View {
    @EnvironmentObject private var viewModel: PackageViewModel
    @EnvironmentObject private var theme: ThemeManager
    @State private var searchText = ""

    private var conversations: [(name: String, messageCount: Int)] {
        searchText.isEmpty
            ? viewModel.stats.dmList
            : viewModel.stats.dmList.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var messageTotal: Int {
        viewModel.stats.dmList.reduce(0) { $0 + $1.messageCount }
    }

    var body: some View {
        VStack(spacing: 0) {
            DirectoryHeader(
                eyebrow: "CONVERSATIONS",
                title: "Direct messages",
                subtitle: conversationSummary,
                searchPrompt: "Search people",
                searchText: $searchText
            )

            DirectoryColumnLabels(primary: "PERSON OR GROUP", secondary: "MESSAGES")

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(conversations.enumerated()), id: \.offset) { index, conversation in
                        ArchiveDirectoryRow(
                            rank: index + 1,
                            name: conversation.name,
                            count: conversation.messageCount,
                            maximum: viewModel.stats.dmList.first?.messageCount ?? 1,
                            tint: index < 3 ? Color(hex: 0x8B7CF6) : Color(hex: 0xA9C8DE)
                        )
                    }
                }
                .padding(.horizontal, 42)
                .padding(.bottom, 38)
            }
        }
        .background(theme.bgPrimary)
    }

    private var conversationSummary: String {
        let count = viewModel.stats.dmConversations
        let noun = count == 1 ? "conversation" : "conversations"
        return "\(count.formatted()) \(noun) · \(viewModel.formatNumber(messageTotal)) messages"
    }
}
