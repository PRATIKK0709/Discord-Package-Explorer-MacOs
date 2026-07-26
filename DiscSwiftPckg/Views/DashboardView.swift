import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var viewModel: PackageViewModel
    @EnvironmentObject private var theme: ThemeManager

    private let metricColumns = Array(repeating: GridItem(.flexible(), spacing: 28), count: 4)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 42) {
                identity
                headlineMetrics
                communication
                activity
                accountArchive
                vocabulary
                applications
            }
            .padding(.horizontal, 42)
            .padding(.vertical, 36)
        }
        .background(theme.bgPrimary)
    }

    private var identity: some View {
        HStack(alignment: .center, spacing: 18) {
            avatar.frame(width: 68, height: 68).clipShape(Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text("PACKAGE OVERVIEW")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(theme.accent)
                Text(viewModel.stats.user?.globalName ?? viewModel.stats.user?.username ?? "Discord account")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                HStack(spacing: 18) {
                    if let user = viewModel.stats.user {
                        Text("@\(user.username)")
                        Text(accountAgeText(user.accountAgeDays))
                        Text(user.nitroStatus == "None" ? "No active Nitro" : user.nitroStatus)
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Label("Processed locally", systemImage: "lock.fill")
                    .foregroundStyle(Color(hex: 0x4D9B78))
                Text(viewModel.packageRoot?.lastPathComponent ?? "Discord export")
                    .foregroundStyle(theme.textSecondary)
            }
            .font(.system(size: 11, weight: .semibold))
        }
        .padding(.bottom, 26)
        .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
    }

    private var avatar: some View {
        Group {
            if let url = viewModel.stats.recentAvatars.first {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { avatarFallback }
            } else if let url = viewModel.stats.avatarURL {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { avatarFallback }
            } else {
                avatarFallback
            }
        }
    }

    private var avatarFallback: some View {
        ZStack {
            theme.lavender
            Text(String(viewModel.stats.user?.username.prefix(1) ?? "D").uppercased())
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(theme.accent)
        }
    }

    private var headlineMetrics: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("At a glance", subtitle: "The scale of your archive")
            LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 26) {
                PlainMetric(value: viewModel.formatNumber(viewModel.stats.messageCount), label: "messages", tint: theme.accent)
                PlainMetric(value: viewModel.formatNumber(viewModel.stats.wordCount), label: "words written", tint: Color(hex: 0x8B7CF6))
                PlainMetric(value: "\(viewModel.stats.serverCount)", label: "servers", tint: Color(hex: 0xE8A36B))
                PlainMetric(value: "\(viewModel.stats.dmConversations)", label: "direct conversations", tint: Color(hex: 0x63A98A))
                PlainMetric(value: viewModel.formatNumber(viewModel.stats.filesUploaded), label: "files uploaded", tint: Color(hex: 0xE383A5))
                PlainMetric(value: viewModel.formatNumber(viewModel.stats.mentionCount), label: "mentions", tint: Color(hex: 0x67A8D8))
                PlainMetric(value: viewModel.formatNumber(viewModel.stats.emoteCount), label: "custom emoji uses", tint: Color(hex: 0xD5A942))
                PlainMetric(value: String(format: "%.1f", viewModel.stats.messagesPerDay), label: "messages per day", tint: Color(hex: 0x8C9BAA))
            }
            profilePictureHistory
        }
    }

    @ViewBuilder
    private var profilePictureHistory: some View {
        if !viewModel.stats.recentAvatars.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("PROFILE PICTURE HISTORY").sectionLabel()
                HStack(spacing: 14) {
                    ForEach(Array(viewModel.stats.recentAvatars.enumerated()), id: \.element) { index, url in
                        VStack(spacing: 7) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                theme.bgTertiary
                            }
                            .frame(width: 58, height: 58)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(
                                    index == 0 ? theme.accent.opacity(0.7) : theme.border,
                                    lineWidth: index == 0 ? 2 : 1
                                )
                            )
                            Text(index == 0 ? "Current" : "Previous")
                                .font(.system(size: 9))
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                    Spacer()
                }
            }
            .padding(.top, 6)
        }
    }

    private var communication: some View {
        VStack(alignment: .leading, spacing: 22) {
            sectionTitle("Conversation destinations", subtitle: "Your most active communities and private conversations")
            HStack(alignment: .top, spacing: 54) {
                rankedList("Top servers", items: viewModel.stats.topServers.map { ($0.name, $0.messageCount) })
                rankedList("Top direct messages", items: viewModel.stats.topDMs.map { ($0.name, $0.messageCount) })
                VStack(alignment: .leading, spacing: 14) {
                    Text("ARCHIVE BREAKDOWN").sectionLabel()
                    DataLine("Server messages", viewModel.formatNumber(viewModel.stats.serverMessages))
                    DataLine("Direct messages", viewModel.formatNumber(viewModel.stats.dmMessages))
                    DataLine("Group conversations", "\(viewModel.stats.groupDMCount)")
                    DataLine("Server channels", "\(viewModel.stats.serverChannelCount)")
                    DataLine("Friends", "\(viewModel.stats.friendCount)")
                    DataLine("Blocked users", "\(viewModel.stats.blockedCount)")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var activity: some View {
        VStack(alignment: .leading, spacing: 22) {
            sectionTitle("Activity patterns", subtitle: "When you sent the most messages")
            ActivityAreaChart(
                values: viewModel.stats.messagesByHour,
                peakHour: viewModel.stats.mostActiveHour
            )
            .frame(height: 220)

            HStack(spacing: 0) {
                ActivitySummary(
                    eyebrow: "PEAK HOUR",
                    value: String(format: "%02d:00", viewModel.stats.mostActiveHour),
                    detail: "Highest message volume",
                    alignment: .leading
                )
                ActivitySummary(
                    eyebrow: "BUSIEST DAY",
                    value: viewModel.stats.mostActiveDay,
                    detail: "Across the full archive",
                    alignment: .center
                )
                ActivitySummary(
                    eyebrow: "BUSIEST YEAR",
                    value: viewModel.stats.mostActiveYear.formatted(.number.grouping(.never)),
                    detail: "Most messages sent",
                    alignment: .trailing
                )
            }
            .padding(.top, 4)
        }
    }

    private var accountArchive: some View {
        VStack(alignment: .leading, spacing: 22) {
            sectionTitle("Account archive", subtitle: "Additional records found in the Account, Ads, and billing exports")
            LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 22) {
                ArchiveDatum("Developer applications", viewModel.stats.bots.count)
                ArchiveDatum("Saved avatars", viewModel.stats.recentAvatars.count)
                ArchiveDatum("Account sessions", viewModel.stats.sessionCount)
                ArchiveDatum("Personal notes", viewModel.stats.noteCount)
                ArchiveDatum("Quest records", viewModel.stats.questCount)
                ArchiveDatum("Quests completed", viewModel.stats.completedQuestCount)
                ArchiveDatum("Rewards claimed", viewModel.stats.claimedQuestCount)
                ArchiveDatum("Orbs claimed", viewModel.stats.claimedOrbs)
                ArchiveDatum("Current Orbs", viewModel.stats.currentOrbsBalance)
                ArchiveDatum("Entitlements", viewModel.stats.entitlementCount)
                ArchiveDatum("Payment sources", viewModel.stats.paymentSourceCount)
                ArchiveDatum("Support tickets", viewModel.stats.tickets.count)
            }
        }
    }

    private var vocabulary: some View {
        VStack(alignment: .leading, spacing: 22) {
            sectionTitle("Language and sharing", subtitle: "Frequently used words, shared links, and custom emojis")
            VStack(spacing: 0) {
                HStack(spacing: 48) {
                    languageHeading("Frequent words")
                    languageHeading("Shared links")
                    languageHeading("Custom emojis")
                }
                .padding(.bottom, 6)

                ForEach(0..<8, id: \.self) { index in
                    HStack(spacing: 48) {
                        wordCell(at: index)
                        linkCell(at: index)
                        emojiCell(at: index)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var applications: some View {
        if !viewModel.stats.bots.isEmpty {
            VStack(alignment: .leading, spacing: 22) {
                sectionTitle("Developer applications", subtitle: "Applications associated with this Discord account")
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.stats.bots) { bot in
                        HStack(spacing: 20) {
                            Text(bot.name)
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: 190, alignment: .leading)
                            Text(bot.description.isEmpty ? "No description provided" : bot.description)
                                .font(.system(size: 11))
                                .foregroundStyle(theme.textSecondary)
                                .lineLimit(1)
                            Spacer()
                            Text("APPLICATION")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(theme.accent)
                                .frame(width: 90, alignment: .trailing)
                        }
                        .padding(.vertical, 12)
                        Divider()
                    }
                }
            }
        }
    }

    private func accountAgeText(_ days: Int) -> String {
        days == 1 ? "Member for 1 day" : "Member for \(days.formatted()) days"
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 21, weight: .bold)).foregroundStyle(theme.textPrimary)
            Text(subtitle).font(.system(size: 12)).foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 12)
        .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
    }

    private func rankedList(_ title: String, items: [(String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased()).sectionLabel().padding(.bottom, 6)
            ForEach(Array(items.prefix(7).enumerated()), id: \.offset) { index, item in
                HStack {
                    Text(String(format: "%02d", index + 1)).foregroundStyle(theme.accent).frame(width: 26, alignment: .leading)
                    Text(item.0).lineLimit(1)
                    Spacer()
                    Text(viewModel.formatNumber(item.1)).foregroundStyle(theme.textSecondary)
                }
                .font(.system(size: 12))
                .padding(.vertical, 8)
                Divider()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func languageHeading(_ title: String) -> some View {
        Text(title.uppercased())
            .sectionLabel()
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func wordCell(at index: Int) -> some View {
        HStack(spacing: 10) {
            if viewModel.stats.topWords.indices.contains(index) {
                let item = viewModel.stats.topWords[index]
                Text(item.word)
                    .lineLimit(1)
                Spacer(minLength: 10)
                Text(viewModel.formatNumber(item.count))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 54, alignment: .trailing)
            } else {
                Spacer()
            }
        }
        .font(.system(size: 12))
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
    }

    private func linkCell(at index: Int) -> some View {
        HStack(spacing: 10) {
            if viewModel.stats.topLinks.indices.contains(index) {
                let item = viewModel.stats.topLinks[index]
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.accent)
                    .frame(width: 16)
                Text(displayLink(item.word))
                    .font(.system(size: 12, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(item.word)
                Spacer(minLength: 10)
                Text(viewModel.formatNumber(item.count))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 54, alignment: .trailing)
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
    }

    private func emojiCell(at index: Int) -> some View {
        HStack(spacing: 10) {
            if viewModel.stats.topCustomEmojis.indices.contains(index) {
                let emoji = viewModel.stats.topCustomEmojis[index]
                AsyncImage(url: URL(string: emoji.imageURL)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Color.clear
                }
                .frame(width: 28, height: 28)
                Text(emoji.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                Spacer(minLength: 10)
                Text(viewModel.formatNumber(emoji.count))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 54, alignment: .trailing)
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
    }

    private func displayLink(_ rawValue: String) -> String {
        guard let url = URL(string: rawValue), let host = url.host else { return rawValue }
        let path = url.path == "/" ? "" : url.path
        return host.replacingOccurrences(of: "www.", with: "") + path
    }
}

private struct ActivityAreaChart: View {
    @EnvironmentObject private var theme: ThemeManager
    let values: [Int]
    let peakHour: Int

    private var maximum: Int { max(1, values.max() ?? 1) }

    var body: some View {
        GeometryReader { proxy in
            let plotHeight = proxy.size.height - 28
            let plotWidth = proxy.size.width - 52
            let points = chartPoints(size: CGSize(width: plotWidth, height: plotHeight))

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { index in
                        Rectangle()
                            .fill(theme.border.opacity(index == 3 ? 0.9 : 0.55))
                            .frame(height: 1)
                        if index < 3 { Spacer() }
                    }
                }
                .frame(width: plotWidth, height: plotHeight)

                if points.count > 1 {
                    ChartAreaShape(points: points)
                        .fill(
                            LinearGradient(
                                colors: [theme.accent.opacity(0.24), theme.accent.opacity(0.015)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: plotWidth, height: plotHeight)

                    ChartLineShape(points: points)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: 0x8B7CF6), theme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: plotWidth, height: plotHeight)

                    if points.indices.contains(peakHour) {
                        let peak = points[peakHour]
                        Path { path in
                            path.move(to: CGPoint(x: peak.x, y: 0))
                            path.addLine(to: CGPoint(x: peak.x, y: plotHeight))
                        }
                        .stroke(theme.accent.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 5]))

                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(theme.accent, lineWidth: 3))
                            .position(peak)
                    }
                }

                HStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(hour % 3 == 0 ? String(format: "%02d", hour) : "")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: plotWidth)
                .offset(y: plotHeight + 12)

                VStack {
                    Text(compact(maximum))
                    Spacer()
                    Text(compact(maximum / 2))
                    Spacer()
                    Text("0")
                }
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .frame(height: plotHeight)
                .offset(x: plotWidth + 10)
            }
        }
    }

    private func chartPoints(size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let step = size.width / CGFloat(values.count)
        return values.enumerated().map { index, value in
            CGPoint(
                x: (CGFloat(index) + 0.5) * step,
                y: size.height - (CGFloat(value) / CGFloat(maximum) * (size.height - 14))
            )
        }
    }

    private func compact(_ value: Int) -> String {
        if value >= 1_000_000 { return String(format: "%.1fM", Double(value) / 1_000_000) }
        if value >= 1_000 { return String(format: "%.0fK", Double(value) / 1_000) }
        return value.formatted()
    }
}

private struct ChartLineShape: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = (previous.x + current.x) / 2
            path.addCurve(
                to: current,
                control1: CGPoint(x: midpoint, y: previous.y),
                control2: CGPoint(x: midpoint, y: current.y)
            )
        }
        return path
    }
}

private struct ChartAreaShape: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = ChartLineShape(points: points).path(in: rect)
        guard let first = points.first, let last = points.last else { return path }
        path.addLine(to: CGPoint(x: last.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: first.x, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ActivitySummary: View {
    @EnvironmentObject private var theme: ThemeManager
    let eyebrow: String
    let value: String
    let detail: String
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(eyebrow)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(theme.textSecondary)
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Text(detail)
                .font(.system(size: 10))
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }
}

struct PlainMetric: View {
    @EnvironmentObject private var theme: ThemeManager
    let value: String
    let label: String
    let tint: Color

    init(value: String, label: String, tint: Color) {
        self.value = value
        self.label = label
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(.system(size: 28, weight: .bold)).foregroundStyle(theme.textPrimary)
            Text(label.uppercased()).font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(theme.textSecondary)
            Rectangle().fill(tint).frame(height: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ArchiveDatum: View {
    @EnvironmentObject private var theme: ThemeManager
    let label: String
    let value: Int
    init(_ label: String, _ value: Int) { self.label = label; self.value = value }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.system(size: 12)).foregroundStyle(theme.textSecondary)
            Spacer()
            Text(value.formatted()).font(.system(size: 18, weight: .semibold)).foregroundStyle(theme.textPrimary)
        }
        .padding(.vertical, 10)
        .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
    }
}

struct DataLine: View {
    @EnvironmentObject private var theme: ThemeManager
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }
    var body: some View {
        HStack {
            Text(label).lineLimit(1)
            Spacer()
            Text(value).foregroundStyle(theme.textSecondary)
        }
        .font(.system(size: 12))
        .padding(.vertical, 8)
    }
}

private extension View where Self == Text {
    func sectionLabel() -> some View {
        self.font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(Color(hex: 0x718096))
    }
}
