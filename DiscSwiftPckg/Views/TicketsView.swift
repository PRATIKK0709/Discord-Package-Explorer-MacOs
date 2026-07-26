import SwiftUI

struct TicketsView: View {
    @EnvironmentObject private var theme: ThemeManager
    let tickets: [DiscordTicket]
    @State private var selectedID: String?

    private var selected: DiscordTicket? {
        tickets.first { $0.id == selectedID } ?? tickets.first
    }

    var body: some View {
        if tickets.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("SUPPORT").pageEyebrow()
                Text("No support history")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text("This export does not contain any Discord support tickets.")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(42)
            .background(theme.bgPrimary)
        } else {
            HStack(spacing: 0) {
                ticketIndex
                    .frame(width: 290)
                    .background(Color.white)
                    .overlay(Rectangle().fill(theme.border).frame(width: 1), alignment: .trailing)
                if let selected {
                    TicketTranscript(ticket: selected)
                }
            }
            .onAppear { selectedID = selectedID ?? tickets.first?.id }
        }
    }

    private var ticketIndex: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("SUPPORT").pageEyebrow()
                Text("Ticket history")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text(ticketCountText)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(26)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(tickets) { ticket in
                        Button {
                            selectedID = ticket.id
                        } label: {
                            HStack(spacing: 12) {
                                Rectangle()
                                    .fill(selected?.id == ticket.id ? theme.accent : Color.clear)
                                    .frame(width: 2, height: 42)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(ticket.subject ?? "Ticket #\(ticket.ticketId)")
                                        .font(.system(size: 12, weight: selected?.id == ticket.id ? .semibold : .regular))
                                        .foregroundStyle(theme.textPrimary)
                                        .lineLimit(1)
                                    HStack {
                                        Text(ticket.status.uppercased())
                                            .font(.system(size: 8, weight: .bold))
                                            .tracking(0.8)
                                        Spacer()
                                        Text(ticket.formattedDate)
                                            .font(.system(size: 9))
                                    }
                                    .foregroundStyle(theme.textSecondary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 34)
                    }
                }
            }
        }
    }

    private var ticketCountText: String {
        tickets.count == 1 ? "1 ticket" : "\(tickets.count.formatted()) tickets"
    }
}

struct TicketTranscript: View {
    @EnvironmentObject private var theme: ThemeManager
    let ticket: DiscordTicket

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TICKET #\(ticket.ticketId)").pageEyebrow()
                    Text(ticket.subject ?? "Support conversation")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    HStack(spacing: 18) {
                        Text(ticket.status.capitalized)
                        Text(ticket.formattedDate)
                        Text(commentCountText)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
                }
                .padding(.bottom, 24)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)

                ForEach(Array(ticket.sortedMessages.enumerated()), id: \.element.id) { index, comment in
                    HStack(alignment: .top, spacing: 18) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.textSecondary)
                            .frame(width: 24, alignment: .leading)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(comment.author)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Text(formatDate(comment.createdAt))
                                    .font(.system(size: 9))
                                    .foregroundStyle(theme.textSecondary)
                            }
                            Text(comment.comment)
                                .font(.system(size: 13))
                                .foregroundStyle(theme.textPrimary.opacity(0.88))
                                .lineSpacing(4)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.vertical, 20)
                    .overlay(Rectangle().fill(theme.border.opacity(0.75)).frame(height: 1), alignment: .bottom)
                }
            }
            .padding(42)
        }
        .background(theme.bgPrimary)
    }

    private func formatDate(_ timestamp: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: timestamp) else { return timestamp }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private var commentCountText: String {
        ticket.comments.count == 1 ? "1 comment" : "\(ticket.comments.count.formatted()) comments"
    }
}

private extension Text {
    func pageEyebrow() -> some View {
        self.font(.system(size: 9, weight: .bold))
            .tracking(1.4)
            .foregroundStyle(Color(hex: 0x6D8EF7))
    }
}
