import SwiftUI

struct BotsGridView: View {
    @EnvironmentObject var theme: ThemeManager
    let bots: [DiscordBot]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "applescript")
                    .foregroundStyle(theme.accent)
                Text("My Bots")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text("\(bots.count) apps")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
            }
            
            // Grid Section
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 8)], spacing: 8) {
                ForEach(bots) { bot in
                    BotCard(bot: bot)
                }
            }
        }
        .padding(16)
        .background(theme.bgSecondary)
        .cornerRadius(12)
    }
}

struct BotCard: View {
    @EnvironmentObject var theme: ThemeManager
    let bot: DiscordBot
    private let cardSize: CGFloat = 50
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background Image
            Group {
                if let localURL = bot.localIconURL,
                   let imageData = try? Data(contentsOf: localURL),
                   let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                } else if let iconHash = bot.icon {
                     AsyncImage(url: URL(string: "https://cdn.discordapp.com/app-icons/\(bot.id)/\(iconHash).png?size=128")) { image in
                         image.resizable().scaledToFill()
                     } placeholder: {
                         Rectangle().fill(theme.bgTertiary)
                     }
                } else {
                    Rectangle()
                        .fill(theme.bgTertiary)
                        .overlay(
                            Image(systemName: "applescript")
                                .font(.system(size: 16))
                                .foregroundStyle(theme.textSecondary)
                        )
                }
            }
            .frame(width: cardSize, height: cardSize)
            .clipped()
            
            // Name Overlay
            LinearGradient(
                colors: [.black.opacity(0.8), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 18)
            
            Text(bot.name)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 2)
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity)
        }
        .frame(width: cardSize, height: cardSize)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.bgTertiary, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        .help(bot.name)
    }
}
