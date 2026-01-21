import SwiftUI

struct BotsGridView: View {
    let bots: [DiscordBot]
    
    var body: some View {
        HStack(spacing: 0) {
            // Stylized Side Header (Simplified)
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "applescript")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.accent)
                    .padding(.bottom, 8)
                
                Text("My Bots")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("\(bots.count) apps")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
            }
            .padding(16)
            .background(Color(red: 0.12, green: 0.12, blue: 0.14)) // Darker side panel
            .frame(width: 90)
            
            // Grid Section - Dynamic
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 8)], spacing: 8) {
                ForEach(bots) { bot in
                    BotCard(bot: bot)
                }
            }
            .padding(16)
        }
        .background(Theme.bgSecondary)
        .cornerRadius(16)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct BotCard: View {
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
                         Rectangle().fill(Theme.bgTertiary)
                     }
                } else {
                    Rectangle()
                        .fill(Theme.bgTertiary)
                        .overlay(
                            Image(systemName: "applescript")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.textSecondary)
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
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.bgTertiary, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        .help(bot.name)
    }
}
