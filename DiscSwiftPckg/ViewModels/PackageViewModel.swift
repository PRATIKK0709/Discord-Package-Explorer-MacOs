import Foundation
import Combine

/// ViewModel for parsing Discord data package - Discord-Package exact logic
class PackageViewModel: ObservableObject {
    @Published var stats = DiscordStats()
    @Published var isLoading = false
    @Published var loadingStatus = ""
    @Published var loadingProgress: Double = 0
    @Published var errorMessage: String?
    @Published var hasLoadedData = false
    @Published var debugLog: [String] = []
    
    private var startTime: Date?
    
    private func log(_ msg: String) {
        let elapsed = startTime.map { String(format: "%.2fs", Date().timeIntervalSince($0)) } ?? "0.00s"
        print("[\(elapsed)] \(msg)")
        DispatchQueue.main.async { [weak self] in
            self?.debugLog.append("[\(elapsed)] \(msg)")
        }
    }
    
    func scanPackage(at url: URL) {
        isLoading = true
        errorMessage = nil
        stats = DiscordStats()
        debugLog = []
        startTime = Date()
        
        log("Starting scan: \(url.lastPathComponent)")
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.parsePackage(at: url)
        }
    }
    
    private func updateProgress(_ progress: Double, _ status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.loadingProgress = progress
            self?.loadingStatus = status
        }
    }
    
    private func parsePackage(at url: URL) {
        let fm = FileManager.default
        var root = url
        
        // Find package root
        if fm.fileExists(atPath: url.appendingPathComponent("package").path) {
            root = url.appendingPathComponent("package")
        }
        
        log("Root: \(root.lastPathComponent)")
        
        // 1. Parse user.json
        updateProgress(0.05, "Loading user...")
        parseUser(at: root)
        
        // 2. Parse servers
        updateProgress(0.1, "Loading servers...")
        parseServers(at: root)
        
        // 3. Parse messages - Discord-Package style
        updateProgress(0.15, "Processing messages...")
        parseMessagesDiscordPackageStyle(at: root)
        
        // 4. Parse analytics if available
        updateProgress(0.9, "Parsing analytics...")
        parseAnalytics(at: root)
        
        updateProgress(1.0, "Complete!")
        
        log("Done: \(stats.messageCount) messages")
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.hasLoadedData = true
        }
    }
    
    // MARK: - Parse User
    
    private func parseUser(at root: URL) {
        // Try different folder names
        for folder in ["Account", "account", "Compte"] {
            let path = root.appendingPathComponent("\(folder)/user.json")
            guard let data = try? Data(contentsOf: path),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            
            // Extract user info
            let userId = json["id"] as? String ?? ""
            let username = json["username"] as? String ?? "Discord User"
            let discriminator = json["discriminator"] as? String ?? "0"
            let avatarHash = json["avatar_hash"] as? String
            let globalName = json["global_name"] as? String
            
            // Create user
            let user = DiscordUser(
                id: userId,
                username: username,
                discriminator: discriminator,
                globalName: globalName,
                email: nil,
                phone: nil,
                verified: nil,
                mfaEnabled: nil,
                premiumType: json["premium_type"] as? Int,
                flags: json["flags"] as? Int,
                avatarHash: avatarHash,
                payments: nil
            )
            
            // Connections
            var connections: [(String, String)] = []
            if let conns = json["connections"] as? [[String: Any]] {
                connections = conns.compactMap { conn -> (String, String)? in
                    guard let type = conn["type"] as? String,
                          let name = conn["name"] as? String,
                          type != "contacts" else { return nil }
                    return (type, name)
                }
            }
            
            // Relationships
            var friendCount = 0, blockedCount = 0
            if let rels = json["relationships"] as? [[String: Any]] {
                friendCount = rels.filter { ($0["type"] as? Int) == 1 }.count
                blockedCount = rels.filter { ($0["type"] as? Int) == 2 }.count
            }
            
            // Payments
            var totalSpent: [String: Double] = [:]
            var paymentCount = 0
            if let payments = json["payments"] as? [[String: Any]] {
                let confirmed = payments.filter { ($0["status"] as? Int) == 1 }
                paymentCount = confirmed.count
                for p in confirmed {
                    if let amt = p["amount"] as? Int, let cur = p["currency"] as? String {
                        totalSpent[cur, default: 0] += Double(amt) / 100.0
                    }
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.stats.user = user
                self?.stats.connections = connections
                self?.stats.friendCount = friendCount
                self?.stats.blockedCount = blockedCount
                self?.stats.totalSpent = totalSpent
                self?.stats.paymentCount = paymentCount
            }
            
            // Scan for recent avatars history
            let avatarsPath = root.appendingPathComponent("\(folder)/recent_avatars")
            if FileManager.default.fileExists(atPath: avatarsPath.path) {
                if let files = try? FileManager.default.contentsOfDirectory(at: avatarsPath, includingPropertiesForKeys: nil) {
                    let imageFiles = files.filter { url in
                        let ext = url.pathExtension.lowercased()
                        return ["png", "jpg", "jpeg", "gif", "webp"].contains(ext)
                    }.sorted { $0.lastPathComponent > $1.lastPathComponent } // Newest first
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.stats.recentAvatars = imageFiles
                    }
                    log("Found \(imageFiles.count) historical avatars")
                }
            }

            
            log("User: \(username), Friends: \(friendCount), Connections: \(connections.count)")
            return
        }
    }
    
    // MARK: - Parse Servers
    
    // Local cache for emojis found in package
    private var localEmojiMap: [String: URL] = [:]
    
    // MARK: - Parse Servers
    
    private func parseServers(at root: URL) {
        // 1. Index local emojis first
        indexLocalEmojis(at: root)
        
        for folder in ["Servers", "servers"] {
            let path = root.appendingPathComponent("\(folder)/index.json")
            if let data = try? Data(contentsOf: path),
               let index = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                DispatchQueue.main.async { [weak self] in
                    self?.stats.serverCount = index.count
                    self?.stats.serverNames = Array(index.values).sorted()
                }
                log("Servers: \(index.count)")
                return
            }
        }
    }
    
    // Scan all Servers/*/emoji/ folders to build a map of ID -> LocalURL
    private func indexLocalEmojis(at root: URL) {
        let serversRoot = root.appendingPathComponent("Servers")
        guard FileManager.default.fileExists(atPath: serversRoot.path),
              let serverFolders = try? FileManager.default.contentsOfDirectory(at: serversRoot, includingPropertiesForKeys: nil) else { return }
        
        var count = 0
        for folder in serverFolders {
            let emojiFolder = folder.appendingPathComponent("emoji")
            if FileManager.default.fileExists(atPath: emojiFolder.path),
               let files = try? FileManager.default.contentsOfDirectory(at: emojiFolder, includingPropertiesForKeys: nil) {
                
                for file in files {
                    // Filename is usually {id}.png or {id}.gif
                    let filename = file.lastPathComponent // "123456.png"
                    let id = file.deletingPathExtension().lastPathComponent // "123456"
                    
                    if !id.isEmpty && id.allSatisfy({ $0.isNumber }) {
                        localEmojiMap[id] = file
                        count += 1
                    }
                }
            }
        }
        log("Indexed \(count) local emojis from package")
    }
    
    // MARK: - Parse Messages - Discord-Package Style
    
    // MARK: - Parse Messages - Parallel Optimized
    
    private func parseMessagesDiscordPackageStyle(at root: URL) {
        log("Starting parallel message scan...")
        
        // 1. Identify all Server folders
        let serversRoot = root.appendingPathComponent("Servers")
        let messagesRoot = root.appendingPathComponent("messages") // DMs or old format
        
        var foldersToScan: [URL] = []
        
        if FileManager.default.fileExists(atPath: serversRoot.path),
           let serverFolders = try? FileManager.default.contentsOfDirectory(at: serversRoot, includingPropertiesForKeys: nil) {
            foldersToScan.append(contentsOf: serverFolders)
        }
        
        if FileManager.default.fileExists(atPath: messagesRoot.path) {
            foldersToScan.append(messagesRoot)
        }
        
        // 2. Prepare thread-safe aggregation
        let lock = NSLock()
        
        // Helper struct for detailed aggregation
        struct StatsAccumulator {
            var messageCount = 0
            var wordCount = 0
            var charCount = 0
            var words = [String: Int]()
            var emojis = [String: Int]()
            var cursed = [String: Int]()
            var links = [String: Int]()
            var discordLinks = [String: Int]()
            
            mutating func merge(other: StatsAccumulator) {
                messageCount += other.messageCount
                wordCount += other.wordCount
                charCount += other.charCount
                for (k, v) in other.words { words[k, default: 0] += v }
                for (k, v) in other.emojis { emojis[k, default: 0] += v }
                for (k, v) in other.cursed { cursed[k, default: 0] += v }
                for (k, v) in other.links { links[k, default: 0] += v }
                for (k, v) in other.discordLinks { discordLinks[k, default: 0] += v }
            }
        }
        
        // Accumulators
        var totalMessages = 0
        var totalWords = 0
        var totalChars = 0
        var totalFiles = 0
        var totalEmotes = 0
        var totalMentions = 0
        
        var msgByHour = [Int](repeating: 0, count: 24)
        var msgByDay = [Int](repeating: 0, count: 7)
        var msgByYear = [Int: Int]()
        
        var wordCounts = [String: Int]()
        var emojiCounts = [String: Int]()
        var cursedCounts = [String: Int]()
        var linkCounts = [String: Int]()
        var discordLinkCounts = [String: Int]()
        
        // Detailed Accumulators
        // Key: Server ID (or DM Channel ID) -> Stats
        var serverStats = [String: StatsAccumulator]()
        var dmStats = [String: StatsAccumulator]()
        
        var dmChannelInfos = [String: String]() // Channel ID -> Name (for final mapping)
        
        // --- REGEX SETUP ---
        // Pre-compute cursed words set for O(1) lookup
        let cursedWordsList = ["4r5e", "5h1t", "5hit", "a55", "anal", "anus", "ar5e", "arrse", "arse", "ass", "ass-fucker", "asses", "assfucker", "assfukka", "asshole", "assholes", "asswhole", "a_s_s", "b!tch", "b00bs", "b17ch", "b1tch", "ballbag", "balls", "ballsack", "bastard", "beastial", "beastiality", "bellend", "bestial", "bestiality", "bi+ch", "biatch", "bitch", "bitcher", "bitchers", "bitches", "bitchin", "bitching", "bloody", "blow job", "blowjob", "blowjobs", "boiolas", "bollock", "bollok", "boner", "boob", "boobs", "booobs", "boooobs", "booooobs", "booooooobs", "breasts", "buceta", "bugger", "bum", "bunny fucker", "butt", "butthole", "buttmuch", "buttplug", "c0ck", "c0cksucker", "carpet muncher", "cawk", "chink", "cipa", "cl1t", "clit", "clitoris", "clits", "cnut", "cock", "cock-sucker", "cockface", "cockhead", "cockmunch", "cockmuncher", "cocks", "cocksuck", "cocksucked", "cocksucker", "cocksucking", "cocksucks", "cocksuka", "cocksukka", "cok", "cokmuncher", "coksucka", "coon", "cox", "crap", "cum", "cummer", "cumming", "cums", "cumshot", "cunilingus", "cunillingus", "cunnilingus", "cunt", "cuntlick", "cuntlicker", "cuntlicking", "cunts", "cyalis", "cyberfuc", "cyberfuck", "cyberfucked", "cyberfucker", "cyberfuckers", "cyberfucking", "d1ck", "damn", "dick", "dickhead", "dildo", "dildos", "dink", "dinks", "dirsa", "dlck", "dog-fucker", "doggin", "dogging", "donkeyribber", "doosh", "duche", "dyke", "ejaculate", "ejaculated", "ejaculates", "ejaculating", "ejaculatings", "ejaculation", "ejakulate", "f u c k", "f u c k e r", "f4nny", "fag", "fagging", "faggitt", "faggot", "faggs", "fagot", "fagots", "fags", "fanny", "fannyflaps", "fannyfucker", "fanyy", "fatass", "fcuk", "fcuker", "fcuking", "feck", "fecker", "felching", "fellate", "fellatio", "fingerfuck", "fingerfucked", "fingerfucker", "fingerfuckers", "fingerfucking", "fingerfucks", "fistfuck", "fistfucked", "fistfucker", "fistfuckers", "fistfucking", "fistfuckings", "fistfucks", "flange", "fook", "fooker", "fuck", "fucka", "fucked", "fucker", "fuckers", "fuckhead", "fuckheads", "fuckin", "fucking", "fuckings", "fuckingshitmotherfucker", "fuckme", "fucks", "fuckwhit", "fuckwit", "fudge packer", "fudgepacker", "fuk", "fuker", "fukker", "fukkin", "fuks", "fukwhit", "fukwit", "fux", "fux0r", "f_u_c_k", "gangbang", "gangbanged", "gangbangs", "gaylord", "gaysex", "goatse", "God", "god-dam", "god-damned", "goddamn", "goddamned", "hardcoresex", "hell", "heshe", "hoar", "hoare", "hoer", "homo", "hore", "horniest", "horny", "hotsex", "jack-off", "jackoff", "jap", "jerk-off", "jism", "jiz", "jizm", "jizz", "kawk", "knob", "knobead", "knobed", "knobend", "knobhead", "knobjocky", "knobjokey", "kock", "kondum", "kondums", "kum", "kummer", "kumming", "kums", "kunilingus", "l3i+ch", "l3itch", "labia", "lust", "lusting", "m0f0", "m0fo", "m45terbate", "ma5terb8", "ma5terbate", "masochist", "master-bate", "masterb8", "masterbat*", "masterbat3", "masterbate", "masterbation", "masterbations", "masturbate", "mo-fo", "mof0", "mofo", "mothafuck", "mothafucka", "mothafuckas", "mothafuckaz", "mothafucked", "mothafucker", "mothafuckers", "mothafuckin", "mothafucking", "mothafuckings", "mothafucks", "mother fucker", "motherfuck", "motherfucked", "motherfucker", "motherfuckers", "motherfuckin", "motherfucking", "motherfuckings", "motherfuckka", "motherfucks", "muff", "mutha", "muthafecker", "muthafuckker", "muther", "mutherfucker", "n1gga", "n1gger", "nazi", "nigg3r", "nigg4h", "nigga", "niggah", "niggas", "niggaz", "nigger", "niggers", "nob", "nob jokey", "nobhead", "nobjocky", "nobjokey", "numbnuts", "nutsack", "orgasim", "orgasims", "orgasm", "orgasms", "p0rn", "pawn", "pecker", "penis", "penisfucker", "phonesex", "phuck", "phuk", "phuked", "phuking", "phukked", "phukking", "phuks", "phuq", "pigfucker", "pimpis", "piss", "pissed", "pisser", "pissers", "pisses", "pissflaps", "pissin", "pissing", "pissoff", "poop", "porn", "porno", "pornography", "pornos", "prick", "pricks", "pron", "pube", "pusse", "pussi", "pussies", "pussy", "pussys", "rectum", "retard", "rimjaw", "rimming", "s hit", "s.o.b.", "sadist", "schlong", "screwing", "scroat", "scrote", "scrotum", "semen", "sex", "sh!+", "sh!t", "sh1t", "shag", "shagger", "shaggin", "shagging", "shemale", "shi+", "shit", "shitdick", "shite", "shited", "shitey", "shitfuck", "shitfull", "shithead", "shiting", "shitings", "shits", "shitted", "shitter", "shitters", "shitting", "shittings", "shitty", "skank", "slut", "sluts", "smegma", "smut", "snatch", "son-of-a-bitch", "spac", "spunk", "s_h_i_t", "t1tt1e5", "t1tties", "teets", "teez", "testical", "testicle", "tit", "titfuck", "tits", "titt", "tittie5", "tittiefucker", "titties", "tittyfuck", "tittywank", "titwank", "tosser", "turd", "tw4t", "twat", "twathead", "twatty", "twunt", "twunter", "v14gra", "v1gra", "vagina", "viagra", "vulva", "w00se", "wang", "wank", "wanker", "wanky", "whoar", "whore", "willies", "willy", "xrated", "xxx"]
        let cursedWordsSet = Set(cursedWordsList)
        
        // Removed regex compilations for performance
        
        // Pre-compute local emoji map once
        let safeLocalEmojiMap = self.localEmojiMap
        // Load message index for naming DMs or Channels if needed
        let loadedMessageIndex = (try? JSONSerialization.jsonObject(with: Data(contentsOf: messagesRoot.appendingPathComponent("index.json")))) as? [String: String] ?? [:]
        
        // 3. Concurrent Execution
        DispatchQueue.concurrentPerform(iterations: foldersToScan.count) { i in
            let folder = foldersToScan[i]
            
            // Local accumulators
            var localMsgCount = 0
            var localWordCount = 0
            var localCharCount = 0
            var localFileCount = 0
            var localEmoteCount = 0
            var localMentionCount = 0
            
            var localByHour = [Int](repeating: 0, count: 24)
            var localByDay = [Int](repeating: 0, count: 7)
            var localByYear = [Int: Int]()
            
            var localWords = [String: Int]()
            var localEmojis = [String: Int]()
            var localCursed = [String: Int]()
            var localLinks = [String: Int]()
            var localDiscordLinks = [String: Int]()
            
            // Detailed Local Accumulators
            // We need to track which channel ID contributes to which Guild locally
            var localServerStats = [String: StatsAccumulator]()
            var localDMStats = [String: StatsAccumulator]()
            
            // Map Channel ID -> Guild ID (if found in channel.json)
            var channelToGuild = [String: String]()
            // Set of DM channel IDs encountered
            var dmChannelIds = Set<String>()
            
            let channelFolders: [URL]
            if let sub = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
                channelFolders = sub
            } else {
                return
            }
            
            // Robust Date Parsers (Local to thread)
            // 1. ISO8601 with fractional seconds (Discord Standard)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            // 2. Simple fallback
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.dS"
            simpleFormatter.locale = Locale(identifier: "en_US_POSIX")
            // 3. Another fallback
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            func parseDate(_ ts: String) -> Date? {
                if let d = isoFormatter.date(from: ts) { return d }
                // Try truncating potential 6-digit micros which ISO8601 sometimes chokes on if setup for millis
                // Actually ISO8601DateFormatter handles 3 digits mostly.
                if let d = simpleFormatter.date(from: ts) { return d }
                return fallbackFormatter.date(from: ts)
            }
            
            for channel in channelFolders {
                // Determine Channel Info
                let chJsonPath = channel.appendingPathComponent("channel.json")
                var chId = channel.lastPathComponent
                var isDM = false
                var guildId: String? = nil
                
                // Try reading channel.json
                if let chData = try? Data(contentsOf: chJsonPath),
                   let chJson = try? JSONSerialization.jsonObject(with: chData) as? [String: Any] {
                    
                    chId = chJson["id"] as? String ?? chId
                    
                    // Check for Guild ID directly or in 'guild' object
                    if let gid = chJson["guild_id"] as? String {
                        guildId = gid
                    } else if let guildObj = chJson["guild"] as? [String: Any], let gid = guildObj["id"] as? String {
                        guildId = gid
                    }
                    
                    // Check DM
                    if let type = chJson["type"] as? Int {
                        if type == 1 || type == 3 { isDM = true } // 1=DM, 3=GroupDM
                    } else if let recipients = chJson["recipients"] as? [String], !recipients.isEmpty {
                         // Fallback logic
                         isDM = true
                    }
                }
                
                // If we didn't find specific guild info, but we are inside "Servers/{GuildID}", use that
                if guildId == nil && folder.path.contains("/Servers") {
                     guildId = folder.lastPathComponent
                }
                
                let messagesFile = channel.appendingPathComponent("messages.csv")
                let jsonFile = channel.appendingPathComponent("messages.json")
                
                var channelMsgCount = 0
                
                // Helper to process a message
                func processMessage(_ content: String, _ timestamp: String) {
                    channelMsgCount += 1
                    localCharCount += content.count
                    
                    // Time
                    if let date = parseDate(timestamp) {
                        let cal = Calendar.current
                        localByHour[cal.component(.hour, from: date)] += 1
                        localByDay[(cal.component(.weekday, from: date) + 5) % 7] += 1
                        localByYear[cal.component(.year, from: date), default: 0] += 1
                    }
                    
                    // Single-pass optimized parsing
                    let words = content.components(separatedBy: .whitespacesAndNewlines)
                    for word in words {
                        if word.isEmpty { continue }
                        let w = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                        
                        // Check for Emoji
                        if word.hasPrefix("<") && word.hasSuffix(">") {
                             localEmoteCount += 1
                             localEmojis[word, default: 0] += 1
                             continue
                        }
                        
                        // Check for Mention
                        if word.hasPrefix("<@") {
                            localMentionCount += 1
                            continue
                        }
                        
                        // Check for Cursed Words (O(1))
                        if cursedWordsSet.contains(w) {
                            localCursed[w, default: 0] += 1
                        }
                        
                        // Check for Links
                        if word.lowercased().hasPrefix("http") || word.lowercased().hasPrefix("ftp") || word.lowercased().hasPrefix("file") {
                             localLinks[word, default: 0] += 1
                             
                             // Check for Discord Links
                             let lcWord = word.lowercased()
                             if lcWord.contains("discord.gg") || 
                                lcWord.contains("discord.com/invite") || 
                                lcWord.contains("discordapp.com/invite") || 
                                lcWord.contains("discord.me") {
                                 localDiscordLinks[word, default: 0] += 1
                             }
                             continue // Don't count links as words
                        }
                        
                        // Valid Word
                        if !w.isEmpty && w.count > 2 {
                             localWordCount += 1 // Count valid words
                             if w.count > 3 { // Statistic threshold for "Favorite Words"
                                 localWords[w, default: 0] += 1
                             }
                        }
                    }
                }
                
                
                // Helper to update specific accumulator
                func updateStats(_ stats: inout StatsAccumulator, _ content: String) {
                    stats.messageCount += 1
                    stats.charCount += content.count
                    
                    let words = content.components(separatedBy: .whitespacesAndNewlines)
                    for word in words {
                        if word.isEmpty { continue }
                        let w = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                        
                        // Emoji
                        if word.hasPrefix("<") && word.hasSuffix(">") {
                            stats.emojis[word, default: 0] += 1
                            continue
                        }
                        
                        // Cursed Word Check - O(1)
                        if cursedWordsSet.contains(w) {
                            stats.cursed[w, default: 0] += 1
                            continue
                        }
                        
                        // Link Check
                        if word.lowercased().hasPrefix("http") || word.lowercased().hasPrefix("ftp") || word.lowercased().hasPrefix("file") {
                             stats.links[word, default: 0] += 1
                             
                             // Discord Link Check
                             let lcWord = word.lowercased()
                             if lcWord.contains("discord.gg") || 
                                lcWord.contains("discord.com/invite") || 
                                lcWord.contains("discordapp.com/invite") || 
                                lcWord.contains("discord.me") {
                                 stats.discordLinks[word, default: 0] += 1
                             }
                             continue
                        }
                        
                        if !w.isEmpty && w.count > 2 {
                             stats.wordCount += 1
                             if w.count > 3 {
                                 stats.words[w, default: 0] += 1
                             }
                        }
                    }
                }

                // --- CSV PARSING ---
                if FileManager.default.fileExists(atPath: messagesFile.path) {
                    if let content = try? String(contentsOf: messagesFile, encoding: .utf8) {
                        let lines = content.components(separatedBy: .newlines)
                        for (idx, line) in lines.enumerated() {
                            if idx == 0 || line.isEmpty { continue }
                            let parts = line.components(separatedBy: ",")
                            if parts.count >= 3 {
                                // CSV: ID,Timestamp,Contents,Attachments
                                let timestampStr = parts[1]
                                let contentStr = parts.dropFirst(2).joined(separator: ",")
                                
                                processMessage(contentStr, timestampStr)
                                
                                // Accumulate Detailed Stats
                                if channelMsgCount > 0 { // Just processed
                                    if let gid = guildId {
                                        updateStats(&localServerStats[gid, default: StatsAccumulator()], contentStr)
                                    } else if isDM {
                                        updateStats(&localDMStats[chId, default: StatsAccumulator()], contentStr)
                                    } else {
                                        // Fallback
                                        if !folder.path.contains("/Servers") {
                                            updateStats(&localDMStats[chId, default: StatsAccumulator()], contentStr)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // --- JSON PARSING ---
                else if FileManager.default.fileExists(atPath: jsonFile.path) {
                    if let data = try? Data(contentsOf: jsonFile),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        for msg in json {
                           if let content = msg["Contents"] as? String, let ts = msg["Timestamp"] as? String {
                               processMessage(content, ts)
                               
                               // Accumulate Detailed Stats
                                if let gid = guildId {
                                    updateStats(&localServerStats[gid, default: StatsAccumulator()], content)
                                } else if isDM {
                                    updateStats(&localDMStats[chId, default: StatsAccumulator()], content)
                                } else {
                                    // Fallback
                                    if !folder.path.contains("/Servers") {
                                        updateStats(&localDMStats[chId, default: StatsAccumulator()], content)
                                    }
                                }
                           }
                           if let attachments = msg["Attachments"] as? String, !attachments.isEmpty {
                               localFileCount += 1
                           }
                        }
                    }
                }
                
                localMsgCount += channelMsgCount
                
                // Record Stats for later merging (identifying DMs name)
                if channelMsgCount > 0 && isDM {
                     dmChannelIds.insert(chId)
                } else if channelMsgCount > 0 && !folder.path.contains("/Servers") && guildId == nil {
                     dmChannelIds.insert(chId)
                }
            }
            
            // Merge thread results
            lock.lock()
            totalMessages += localMsgCount
            totalWords += localWordCount
            totalChars += localCharCount
            totalFiles += localFileCount
            totalEmotes += localEmoteCount
            totalMentions += localMentionCount
            
            for h in 0..<24 { msgByHour[h] += localByHour[h] }
            for d in 0..<7 { msgByDay[d] += localByDay[d] }
            for (y, c) in localByYear { msgByYear[y, default: 0] += c }
            
            for (w, c) in localWords { wordCounts[w, default: 0] += c }
            for (e, c) in localEmojis { emojiCounts[e, default: 0] += c }
            
            for (w, c) in localCursed { cursedCounts[w, default: 0] += c }
            for (w, c) in localLinks { linkCounts[w, default: 0] += c }
            for (w, c) in localDiscordLinks { discordLinkCounts[w, default: 0] += c }
            
            
            // Detailed Stats Classification Merge
            for (id, stats) in localServerStats {
                serverStats[id, default: StatsAccumulator()].merge(other: stats)
            }
            
            for (id, stats) in localDMStats {
                dmStats[id, default: StatsAccumulator()].merge(other: stats)
                
                if dmChannelInfos[id] == nil {
                     let name = loadedMessageIndex[id] ?? "Unknown DM"
                     dmChannelInfos[id] = name
                }
            }
            lock.unlock()
        }
        
        // Final Processing on Main Thread
        
        // Helper to convert Accumulator to DetailedStats
        func createDetailedStats(id: String, name: String, acc: StatsAccumulator, serverName: String? = nil) -> DetailedStats {
             // Filter top words
             let tWords = acc.words
                .filter { pair in
                    let w = pair.key.lowercased()
                    return !["the", "and", "that", "have", "for", "with", "this", "what", "just", "from", "your", "http", "https", "you", "are", "but", "not", "can", "all", "was"].contains(w)
                    && w.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil
                }
                .sorted { $0.value > $1.value }
                .prefix(20)
                .map { ($0.key, $0.value) }
            
            // Filter top emojis
            let tEmojis = acc.emojis.sorted { $0.value > $1.value }.prefix(10).compactMap { (emojiStr, count) -> (name: String, id: String, count: Int, imageURL: String)? in
                let pattern = "<(a)?:([^:]+):(\\d+)>"
                guard let regex = try? NSRegularExpression(pattern: pattern),
                      let match = regex.firstMatch(in: emojiStr, range: NSRange(emojiStr.startIndex..., in: emojiStr)) else { return nil }
                let animated = (String(emojiStr[Range(match.range(at: 1), in: emojiStr) ?? emojiStr.startIndex..<emojiStr.startIndex]) == "a")
                let name = String(emojiStr[Range(match.range(at: 2), in: emojiStr)!])
                let id = String(emojiStr[Range(match.range(at: 3), in: emojiStr)!])
                var urlString: String
                if let localURL = safeLocalEmojiMap[id] { urlString = localURL.absoluteString }
                else { urlString = "https://cdn.discordapp.com/emojis/\(id).\(animated ? "gif" : "png")?size=96&quality=lossless" }
                return (name, id, count, urlString)
            }

            return DetailedStats(
                id: id,
                name: name,
                messageCount: acc.messageCount,
                wordCount: acc.wordCount,
                characterCount: acc.charCount,
                topWords: tWords,
                topEmojis: tEmojis,
                topCursedWords: acc.cursed.sorted { $0.value > $1.value }.prefix(20).map { ($0.key, $0.value) },
                topLinks: acc.links.sorted { $0.value > $1.value }.prefix(20).map { ($0.key, $0.value) },
                topDiscordLinks: acc.discordLinks.sorted { $0.value > $1.value }.prefix(20).map { ($0.key, $0.value) },
                serverName: serverName
            )
        }
        
        // Calculate Top Words (Global)
        let topWords = wordCounts
            .filter { (word, _) in
                let w = word.lowercased()
                return !["the", "and", "that", "have", "for", "with", "this", "what", "just", "from", "your", "http", "https", "you", "are", "but", "not", "can", "all", "was"].contains(w)
                && w.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil
            }
            .sorted { $0.value > $1.value }
            .prefix(50)
            .map { ($0.key, $0.value) }
            
        // Calculate Top Emojis (Global)
        let topEmojis = emojiCounts.sorted { $0.value > $1.value }.prefix(30).compactMap { (emojiStr, count) -> (name: String, id: String, count: Int, imageURL: String)? in
            let pattern = "<(a)?:([^:]+):(\\d+)>"
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: emojiStr, range: NSRange(emojiStr.startIndex..., in: emojiStr)) else { return nil }
            
            let animated = (String(emojiStr[Range(match.range(at: 1), in: emojiStr) ?? emojiStr.startIndex..<emojiStr.startIndex]) == "a")
            let name = String(emojiStr[Range(match.range(at: 2), in: emojiStr)!])
            let id = String(emojiStr[Range(match.range(at: 3), in: emojiStr)!])
            
            var urlString: String
            if let localURL = safeLocalEmojiMap[id] {
                urlString = localURL.absoluteString
            } else {
                let ext = animated ? "gif" : "png"
                urlString = "https://cdn.discordapp.com/emojis/\(id).\(ext)?size=96&quality=lossless"
            }
            return (name, id, count, urlString)
        }
        
        // Resolve Server Names
        var serverIdToName: [String: String] = [:]
        if let data = try? Data(contentsOf: root.appendingPathComponent("Servers/index.json")),
           let index = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            serverIdToName = index
        }
        
        let topServers = serverStats.map { (id, acc) in
            createDetailedStats(id: id, name: serverIdToName[id] ?? "Server \(id)", acc: acc)
        }.sorted { $0.messageCount > $1.messageCount }.prefix(20).map { $0 }
        
        let topDMs = dmStats.map { (id, acc) in
            let rawName = dmChannelInfos[id] ?? "Unknown DM"
            let cleanName = rawName.replacingOccurrences(of: "Direct Message with ", with: "")
            return createDetailedStats(id: id, name: cleanName, acc: acc)
        }.sorted { $0.messageCount > $1.messageCount }.prefix(20).map { $0 }
        
        let topCursed = cursedCounts.sorted { $0.value > $1.value }.prefix(50).map { ($0.key, $0.value) }
        let topLinks = linkCounts.sorted { $0.value > $1.value }.prefix(50).map { ($0.key, $0.value) }
        let topDiscordLinks = discordLinkCounts.sorted { $0.value > $1.value }.prefix(50).map { ($0.key, $0.value) }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stats.messageCount = totalMessages
            self.stats.wordCount = totalWords
            self.stats.characterCount = totalChars
            self.stats.filesUploaded = totalFiles
            self.stats.emoteCount = totalEmotes
            self.stats.mentionCount = totalMentions
            
            self.stats.messagesByHour = msgByHour
            self.stats.messagesByDay = msgByDay
            self.stats.messagesByYear = msgByYear
            
            self.stats.topWords = topWords
            self.stats.topCustomEmojis = topEmojis
            self.stats.topServers = Array(topServers) // Explicitly cast if needed, though map returns array
            self.stats.topDMs = Array(topDMs)
            self.stats.topCursedWords = topCursed
            self.stats.topLinks = topLinks
            self.stats.topDiscordLinks = topDiscordLinks
            self.stats.dmConversations = dmChannelInfos.count
        }
    }
    
    // MARK: - Parse Analytics
    
    private func parseAnalytics(at root: URL) {
        // Find analytics file
        for folder in ["Activity", "activity"] {
            let analyticsPath = root.appendingPathComponent("\(folder)/analytics").appendingPathExtension("json")
            let reportingPath = root.appendingPathComponent("\(folder)/reporting").appendingPathExtension("json")
            
            // Try to read analytics events
            for path in [analyticsPath, reportingPath] {
                guard let data = try? Data(contentsOf: path),
                      let content = String(data: data, encoding: .utf8) else { continue }
                
                // Count events by searching for event names (Discord-Package style)
                let events: [(String, WritableKeyPath<DiscordStats, Int>)] = [
                    ("app_opened", \.appOpenedCount),
                    ("join_voice_channel", \.voiceChannelJoins),
                    ("join_call", \.callsJoined),
                    ("add_reaction", \.reactionsAdded),
                    ("message_edited", \.messagesEdited),
                    ("message_deleted", \.messagesDeleted),
                    ("slash_command_used", \.slashCommandsUsed),
                    ("notification_clicked", \.notificationsClicked),
                    ("invite_sent", \.invitesSent),
                    ("gift_code_sent", \.giftsSent),
                    ("search_started", \.searchesStarted),
                    ("app_crashed", \.appCrashes),
                ]
                
                DispatchQueue.main.async { [weak self] in
                    for (eventName, keyPath) in events {
                        let count = content.components(separatedBy: eventName).count - 1
                        self?.stats[keyPath: keyPath] = count
                    }
                }
                
                log("Analytics parsed")
                return
            }
        }
    }
    
    private func parseDate(_ ts: String) -> Date? {
        // Discord timestamp format: 2024-01-15T12:30:45.123+00:00 or 2024-01-15T12:30:45.123Z
        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd HH:mm:ss"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: ts) {
                return date
            }
        }
        
        // Also try ISO8601
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: ts) { return date }
        
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: ts)
    }
    
    func reset() {
        stats = DiscordStats()
        hasLoadedData = false
        errorMessage = nil
        debugLog = []
        loadingProgress = 0
    }
    
    func formatNumber(_ num: Int) -> String {
        if num >= 1_000_000 { return String(format: "%.1fM", Double(num) / 1_000_000.0) }
        if num >= 1000 { return String(format: "%.1fK", Double(num) / 1000.0) }
        return "\(num)"
    }
}
