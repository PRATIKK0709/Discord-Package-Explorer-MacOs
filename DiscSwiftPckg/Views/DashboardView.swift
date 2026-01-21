import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: PackageViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with user
                headerSection
                
                // Avatar History
                if !viewModel.stats.recentAvatars.isEmpty {
                    avatarHistorySection
                }
                
                // Main stats cards
                statsGrid
                
                // Top custom emojis with images
                topEmojisSection
                
                // Activity charts
                chartsSection
                
                // Top lists
                topListsSection
                
                Spacer(minLength: 40)
            }
            .padding(32)
        }
        .background(Theme.bgPrimary)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Avatar - load from history first, then CDN
            if let recentAvatar = viewModel.stats.recentAvatars.first {
                AsyncImage(url: recentAvatar) { image in
                     image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } placeholder: {
                    avatarPlaceholder
                }
            } else if let avatarURL = viewModel.stats.avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    case .failure(_):
                        avatarPlaceholder
                    case .empty:
                        avatarPlaceholder
                    @unknown default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.stats.user?.globalName ?? viewModel.stats.user?.username ?? "Discord User")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                HStack(spacing: 12) {
                    if let user = viewModel.stats.user {
                        Label("@\(user.username)", systemImage: "at")
                        Label("\(user.accountAgeDays) days", systemImage: "calendar")
                    }
                    if viewModel.stats.friendCount > 0 {
                        Label("\(viewModel.stats.friendCount) friends", systemImage: "person.2")
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Theme.bgSecondary)
        .cornerRadius(12)
    }
    
    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
            Text(String(viewModel.stats.user?.username.prefix(1) ?? "D").uppercased())
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
        }
    }
    
    private func connectionIcon(_ type: String) -> some View {
        let icon: String
        switch type.lowercased() {
        case "spotify": icon = "music.note"
        case "steam": icon = "gamecontroller"
        case "github": icon = "chevron.left.forwardslash.chevron.right"
        case "twitter", "x": icon = "bird"
        case "youtube": icon = "play.rectangle"
        case "playstation": icon = "logo.playstation"
        case "xbox": icon = "logo.xbox"
        default: icon = "link"
        }
        return Image(systemName: icon)
            .font(.system(size: 14))
            .foregroundStyle(Theme.textSecondary)
            .frame(width: 28, height: 28)
            .background(Theme.bgTertiary)
            .cornerRadius(6)
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(title: "Messages", value: viewModel.formatNumber(viewModel.stats.messageCount), subtitle: String(format: "%.1f/day", viewModel.stats.messagesPerDay), icon: "bubble.left.fill", color: .blue)
            StatCard(title: "Words", value: viewModel.formatNumber(viewModel.stats.wordCount), subtitle: "typed", icon: "text.cursor", color: .purple)
            StatCard(title: "Characters", value: viewModel.formatNumber(viewModel.stats.characterCount), subtitle: "typed", icon: "character.cursor.ibeam", color: .pink)
            StatCard(title: "Servers", value: "\(viewModel.stats.serverCount)", subtitle: "joined", icon: "server.rack", color: .orange)
            StatCard(title: "DMs", value: "\(viewModel.stats.dmConversations)", subtitle: "conversations", icon: "person.2.fill", color: .indigo)
            StatCard(title: "Files", value: viewModel.formatNumber(viewModel.stats.filesUploaded), subtitle: "uploaded", icon: "doc.fill", color: .green)
            StatCard(title: "Emotes", value: viewModel.formatNumber(viewModel.stats.emoteCount), subtitle: "used", icon: "face.smiling.fill", color: .yellow)
            StatCard(title: "Mentions", value: viewModel.formatNumber(viewModel.stats.mentionCount), subtitle: "@mentions", icon: "at", color: .cyan)
        }
    }
    
    // MARK: - Avatar History
    
    private var avatarHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.stack")
                    .foregroundStyle(Theme.accent)
                Text("Avatar History")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(viewModel.stats.recentAvatars.count) found")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            if viewModel.stats.recentAvatars.isEmpty {
                Text("No historical avatars found")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.stats.recentAvatars, id: \.self) { url in
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.bgTertiary, lineWidth: 1))
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Theme.bgSecondary)
        .cornerRadius(12)
    }
    
    // MARK: - Top Emojis with Images
    
    private var topEmojisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "face.smiling.inverse")
                    .foregroundStyle(Theme.accent)
                Text("Your Top Custom Emojis")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            
            if viewModel.stats.topCustomEmojis.isEmpty {
                Text("No custom emoji data found")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                // Grid of emoji images - Right aligned, bigger
                HStack {
                    Spacer()
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(64), spacing: 12), count: 10), spacing: 16) {
                        ForEach(viewModel.stats.topCustomEmojis.prefix(30), id: \.id) { emoji in
                            EmojiImageView(emoji: emoji)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Theme.bgSecondary)
        .cornerRadius(12)
    }
    
    // MARK: - Charts
    
    private var chartsSection: some View {
        HStack(spacing: 16) {
            // Hourly chart
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Activity by Hour")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("Peak: \(viewModel.stats.mostActiveHour):00")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                HourlyChartView(data: viewModel.stats.messagesByHour)
                    .frame(height: 80)
            }
            .padding(16)
            .background(Theme.bgSecondary)
            .cornerRadius(12)
            
            // Daily chart
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Activity by Day")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("Peak: \(viewModel.stats.mostActiveDay)")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                DailyChartView(data: viewModel.stats.messagesByDay)
                    .frame(height: 80)
            }
            .padding(16)
            .background(Theme.bgSecondary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Top Lists
    
    private var topListsSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Top Words
            TopListCard(title: "Top Words", icon: "text.quote", items: viewModel.stats.topWords.prefix(10).map { ($0.word, "\($0.count)") })
            
            // Top DMs
            TopListCard(title: "Top DMs", icon: "person.2", items: viewModel.stats.topDMs.prefix(10).map { ($0.name, "\($0.messageCount)") })
            
            // Top Servers
            TopListCard(title: "Top Servers", icon: "server.rack", items: viewModel.stats.topServers.prefix(10).map { ($0.name, "\($0.messageCount)") })
        }
    }
}

// MARK: - Emoji Image View

struct EmojiImageView: View {
    let emoji: (name: String, id: String, count: Int, imageURL: String)
    
    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let url = URL(string: emoji.imageURL), url.pathExtension.lowercased() == "gif" {
                    GifImageView(url: url)
                } else {
                    AsyncImage(url: URL(string: emoji.imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure(_):
                            Image(systemName: "face.smiling")
                                .font(.system(size: 32))
                                .foregroundStyle(Theme.textSecondary)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .frame(width: 48, height: 48)
            .background(Theme.bgTertiary)
            .cornerRadius(8)
            
            Text(":\(emoji.name):")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .frame(width: 64)
        }
        .frame(width: 64, height: 72)
        .help(":\(emoji.name): - \(emoji.count) uses")
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .background(Theme.bgSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Charts

// MARK: - Charts

struct HourlyChartView: View {
    let data: [Int]
    
    // Normalize data for the chart
    var normalizedData: [Double] {
        let maxVal = Double(data.max() ?? 1)
        return data.map { maxVal > 0 ? Double($0) / maxVal : 0 }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let points = dataPoints(width: width, height: height)
            
            ZStack {
                // Background grid lines
                VStack {
                    Divider()
                    Spacer()
                    Divider()
                    Spacer()
                    Divider()
                }
                
                // Fill
                SmoothShape(points: points, isClosed: true)
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.4), Theme.accent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Stroke
                SmoothShape(points: points, isClosed: false)
                    .stroke(Theme.accent, lineWidth: 2)
                
                // Labels (simplistic)
                VStack {
                    Spacer()
                    HStack {
                        Text("0")
                        Spacer()
                        Text("6")
                        Spacer()
                        Text("12")
                        Spacer()
                        Text("18")
                        Spacer()
                        Text("23")
                    }
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
    
    private func dataPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        let step = width / CGFloat(max(data.count - 1, 1))
        return normalizedData.enumerated().map { index, value in
            CGPoint(x: CGFloat(index) * step, y: height * (1 - value))
        }
    }
}

struct DailyChartView: View {
    let data: [Int]
    let days = ["M", "T", "W", "T", "F", "S", "S"]
    
    var normalizedData: [Double] {
        let maxVal = Double(data.max() ?? 1)
        return data.map { maxVal > 0 ? Double($0) / maxVal : 0 }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let points = dataPoints(width: width, height: height)
            
            ZStack {
                // Background grid
                VStack {
                    Divider()
                    Spacer()
                    Divider()
                    Spacer()
                    Divider()
                }
                
                // Fill
                SmoothShape(points: points, isClosed: true)
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.4), Theme.accent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Stroke
                SmoothShape(points: points, isClosed: false)
                    .stroke(Theme.accent, lineWidth: 2)
                
                // Labels
                VStack {
                    Spacer()
                    HStack {
                        ForEach(0..<days.count, id: \.self) { i in
                            Text(days[i])
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
    
    private func dataPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        let step = width / CGFloat(max(data.count - 1, 1))
        return normalizedData.enumerated().map { index, value in
            CGPoint(x: CGFloat(index) * step, y: height * (1 - value))
        }
    }
}

// MARK: - Smooth Shape Logic

struct SmoothShape: Shape {
    let points: [CGPoint]
    let isClosed: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        
        path.move(to: points[0])
        
        // Calculate control points for smooth curve
        // This is a simplified Catmull-Rom to Bezier conversion or similar logic
        // For standard "App" look, we can use simple quadratic or cubic interpolation
        
        for i in 1..<points.count {
            let p0 = points[i - 1]
            let p1 = points[i]
            
            // Use midpoints as control points simply? No, that's for quad.
            // Let's use a standard cubic bezier approach for smoothness
            // Or simpler: Quad curve to midpoint
            
            let mid = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
            // Using two quad curves: p0 -> mid, mid -> p1
            // Actually, usually users want "Curve through points".
            // A simple trick: use control points based on previous/next slopes.
            // For now, let's use a simple curve:
            
            // Standard approach:
            path.addCurve(to: p1, control1: CGPoint(x: (p0.x + p1.x) / 2, y: p0.y), control2: CGPoint(x: (p0.x + p1.x) / 2, y: p1.y))
        }
        
        if isClosed {
            path.addLine(to: CGPoint(x: points.last?.x ?? 0, y: rect.height))
            path.addLine(to: CGPoint(x: points.first?.x ?? 0, y: rect.height))
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Top List Card

struct TopListCard: View {
    let title: String
    let icon: String
    let items: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            if items.isEmpty {
                Text("No data")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                        HStack {
                            Text("\(idx + 1)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 16)
                            Text(item.0)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Spacer()
                            Text(item.1)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgSecondary)
        .cornerRadius(12)
    }
}

// MARK: - GIF Image View

struct GifImageView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.animates = true
        return view
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        if let image = NSImage(contentsOf: url) {
            nsView.image = image
            nsView.animates = true
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(PackageViewModel())
        .frame(width: 900, height: 700)
}
