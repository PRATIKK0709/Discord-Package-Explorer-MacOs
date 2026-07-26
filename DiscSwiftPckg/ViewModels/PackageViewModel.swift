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
    private var lastProgressUpdate: Date = Date.distantPast
    private let progressUpdateInterval: TimeInterval = 0.1 // Update UI at most every 100ms
    var packageRoot: URL?
    
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
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.parsePackage(at: url)
        }
    }
    
    private func updateProgress(_ progress: Double, _ status: String, force: Bool = false) {
        let now = Date()
        // Throttle: only update if forced or interval has passed
        guard force || now.timeIntervalSince(lastProgressUpdate) >= progressUpdateInterval else { return }
        lastProgressUpdate = now
        
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
        
        self.packageRoot = root
        
        log("Root: \(root.lastPathComponent)")
        
        // 1. Parse user.json
        updateProgress(0.05, "Loading account…", force: true)
        parseUser(at: root)
        
        // 2. Parse servers
        updateProgress(0.1, "Loading servers…")
        parseServers(at: root)

        // 2.25 Parse account, quests, and billing export summaries
        parsePackageInsights(at: root)
        
        // 2.5 Parse Bots
        updateProgress(0.12, "Loading applications…")
        parseBots(at: root)
        
        // 3. Parse messages - Discord-Package style
        updateProgress(0.15, "Processing messages…")
        parseMessagesDiscordPackageStyle(at: root)
        

        
        // 5. Parse Tickets
        updateProgress(0.95, "Loading support history…")
        parseTickets(at: root)
        
        updateProgress(1.0, "Analysis complete", force: true)
        
        log("Done: \(stats.messageCount) messages")
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.hasLoadedData = true
        }
    }
    
    // MARK: - Parse User

    private func parsePackageInsights(at root: URL) {
        let accountURL = root.appendingPathComponent("Account/user.json")
        if let data = try? Data(contentsOf: accountURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let notes = (json["notes"] as? [Any])?.count ?? (json["notes"] as? [String: Any])?.count ?? 0
            let sessions = (json["user_sessions"] as? [Any])?.count ?? 0
            let guildSettings = (json["guild_settings"] as? [Any])?.count ?? (json["guild_settings"] as? [String: Any])?.count ?? 0
            let appActivity = (json["user_activity_application_statistics"] as? [Any])?.count ?? 0
            let orbs = json["current_orbs_balance"] as? Int ?? 0
            DispatchQueue.main.async { [weak self] in
                self?.stats.noteCount = notes
                self?.stats.sessionCount = sessions
                self?.stats.guildSettingCount = guildSettings
                self?.stats.applicationActivityCount = appActivity
                self?.stats.currentOrbsBalance = orbs
            }
        }

        let questsURL = root.appendingPathComponent("Ads/quests_user_status.json")
        if let data = try? Data(contentsOf: questsURL),
           let quests = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            let completed = quests.filter { !($0["completed_at"] is NSNull) && $0["completed_at"] != nil }.count
            let claimed = quests.filter { !($0["claimed_at"] is NSNull) && $0["claimed_at"] != nil }.count
            let claimedOrbs = quests.reduce(0) { $0 + ($1["orb_quantity_claimed"] as? Int ?? 0) }
            DispatchQueue.main.async { [weak self] in
                self?.stats.questCount = quests.count
                self?.stats.completedQuestCount = completed
                self?.stats.claimedQuestCount = claimed
                self?.stats.claimedOrbs = claimedOrbs
            }
        }

        let billing = root.appendingPathComponent("Account/user_data_exports/discord_billing")
        func recordCount(_ name: String) -> Int {
            let url = billing.appendingPathComponent(name)
            guard let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return 0 }
            return json["record_count"] as? Int ?? (json["records"] as? [Any])?.count ?? 0
        }
        let entitlements = recordCount("entitlements.json")
        let sources = recordCount("payment_sources.json")
        var exportedPayments: [DiscordPayment] = []
        let paymentsURL = billing.appendingPathComponent("payments.json")
        if let data = try? Data(contentsOf: paymentsURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let records = json["records"] as? [[String: Any]] {
            exportedPayments = records.map {
                DiscordPayment(
                    id: $0["id"] as? String,
                    amount: $0["amount"] as? Int,
                    currency: $0["currency"] as? String,
                    status: $0["status"] as? Int,
                    description: $0["description"] as? String,
                    createdAt: $0["created_at"] as? String
                )
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.stats.entitlementCount = entitlements
            self?.stats.paymentSourceCount = sources
            if !exportedPayments.isEmpty {
                self?.stats.payments = exportedPayments
                self?.stats.paymentCount = exportedPayments.filter(\.isConfirmed).count
                self?.stats.totalSpent = Dictionary(grouping: exportedPayments.filter(\.isConfirmed), by: { $0.currency ?? "unknown" })
                    .mapValues { payments in
                        Double(payments.compactMap(\.amount).reduce(0, +)) / 100
                    }
            }
        }
    }
    
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
            
            // Payments
            var paymentsList: [DiscordPayment] = []
            var totalSpent: [String: Double] = [:]
            var paymentCount = 0
            
            if let paymentsRaw = json["payments"] {
                if let data = try? JSONSerialization.data(withJSONObject: paymentsRaw),
                   let parsed = try? JSONDecoder().decode([DiscordPayment].self, from: data) {
                    paymentsList = parsed
                    
                    let confirmed = paymentsList.filter { $0.status == 1 }
                    paymentCount = confirmed.count
                    
                    for p in confirmed {
                        if let amt = p.amount, let cur = p.currency {
                            totalSpent[cur, default: 0] += Double(amt) / 100.0
                        }
                    }
                }
            }


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
                payments: paymentsList
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
            



            
            DispatchQueue.main.async { [weak self] in
                self?.stats.user = user
                self?.stats.connections = connections
                self?.stats.friendCount = friendCount
                self?.stats.blockedCount = blockedCount
                self?.stats.totalSpent = totalSpent
                self?.stats.paymentCount = paymentCount
                self?.stats.payments = paymentsList
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
    
    // MARK: - Parse Tickets
    
    private func parseTickets(at root: URL) {
        // Support_Tickets/tickets.json
        for folder in ["Support_Tickets", "support_tickets", "Tickets", "tickets"] {
            let path = root.appendingPathComponent("\(folder)/tickets.json")
            if let data = try? Data(contentsOf: path) {
                // Discord exports tickets as a dictionary: { "ticket_id": {ticket object} }
                if let ticketsDict = try? JSONDecoder().decode([String: DiscordTicket].self, from: data) {
                    let ticketsArray = Array(ticketsDict.values).sorted { t1, t2 in
                        // Sort by creation date, newest first
                        t1.createdAt > t2.createdAt
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.stats.tickets = ticketsArray
                    }
                    log("Found \(ticketsArray.count) tickets")
                    return
                }
            }
        }
        log("No tickets found")
    }
    
    // MARK: - Parse Bots
    
    private func parseBots(at root: URL) {
        // Try Account/applications
        for folder in ["Account", "account", "Compte"] {
            let appsPath = root.appendingPathComponent("\(folder)/applications")
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: appsPath.path, isDirectory: &isDir), isDir.boolValue else { continue }
            
            guard let appFolders = try? FileManager.default.contentsOfDirectory(at: appsPath, includingPropertiesForKeys: nil) else { continue }
            
            var bots: [DiscordBot] = []
            
            for appFolder in appFolders {
                let jsonPath = appFolder.appendingPathComponent("application.json")
                if let data = try? Data(contentsOf: jsonPath),
                   var bot = try? JSONDecoder().decode(DiscordBot.self, from: data) {
                    
                    // Look for local icon
                    let iconTypes = ["icon.png", "bot-avatar.png", "app-icon.png"]
                    for iconName in iconTypes {
                        let iconPath = appFolder.appendingPathComponent(iconName)
                        if FileManager.default.fileExists(atPath: iconPath.path) {
                            bot.localIconURL = iconPath
                            break
                        }
                    }
                    
                    bots.append(bot)
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.stats.bots = bots
            }
            log("Found \(bots.count) bots")
            return // Found the folder, stop checking variants
        }
    }

    // MARK: - Parse Servers
    
    // Local cache for emojis found in package
    private var localEmojiMap: [String: URL] = [:]
    
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
        
        var serverFoldersToScan: [URL] = []
        
        if FileManager.default.fileExists(atPath: serversRoot.path),
           let serverFolders = try? FileManager.default.contentsOfDirectory(at: serversRoot, includingPropertiesForKeys: nil) {
            serverFoldersToScan.append(contentsOf: serverFolders)
        }
        
        // 2. Build Flat List of Channels (for batching)
        // We need to traverse Servers/GuildID -> [ChannelID] and also messages/ -> [ChannelID]
        var allChannelFolders: [URL] = []
        
        // Add DM folders
        if FileManager.default.fileExists(atPath: messagesRoot.path),
           let dmFolders = try? FileManager.default.contentsOfDirectory(at: messagesRoot, includingPropertiesForKeys: nil) {
            allChannelFolders.append(contentsOf: dmFolders)
        }
        
        // Add Server Channel folders
        for serverFolder in serverFoldersToScan {
            if let channels = try? FileManager.default.contentsOfDirectory(at: serverFolder, includingPropertiesForKeys: nil) {
                // Filter only directories if needed, but FileManager returns all.
                // We assume subfolders in Servers/GuildID are channels.
                allChannelFolders.append(contentsOf: channels)
            }
        }
        
        // 3. Prepare thread-safe aggregation
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
        var msgByMonth = [Int](repeating: 0, count: 12)
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
        var dmChannelIds = Set<String>() // Set of DM channel IDs encountered
        
        // --- REGEX SETUP ---
        // Pre-compute cursed words set for O(1) lookup
        let cursedWordsList = ["4r5e", "5h1t", "5hit", "a55", "anal", "anus", "ar5e", "arrse", "arse", "ass", "ass-fucker", "asses", "assfucker", "assfukka", "asshole", "assholes", "asswhole", "a_s_s", "b!tch", "b00bs", "b17ch", "b1tch", "ballbag", "balls", "ballsack", "bastard", "beastial", "beastiality", "bellend", "bestial", "bestiality", "bi+ch", "biatch", "bitch", "bitcher", "bitchers", "bitches", "bitchin", "bitching", "bloody", "blow job", "blowjob", "blowjobs", "boiolas", "bollock", "bollok", "boner", "boob", "boobs", "booobs", "boooobs", "booooobs", "booooooobs", "breasts", "buceta", "bugger", "bum", "bunny fucker", "butt", "butthole", "buttmuch", "buttplug", "c0ck", "c0cksucker", "carpet muncher", "cawk", "chink", "cipa", "cl1t", "clit", "clitoris", "clits", "cnut", "cock", "cock-sucker", "cockface", "cockhead", "cockmunch", "cockmuncher", "cocks", "cocksuck", "cocksucked", "cocksucker", "cocksucking", "cocksucks", "cocksuka", "cocksukka", "cok", "cokmuncher", "coksucka", "coon", "cox", "crap", "cum", "cummer", "cumming", "cums", "cumshot", "cunilingus", "cunillingus", "cunnilingus", "cunt", "cuntlick", "cuntlicker", "cuntlicking", "cunts", "cyalis", "cyberfuc", "cyberfuck", "cyberfucked", "cyberfucker", "cyberfuckers", "cyberfucking", "d1ck", "damn", "dick", "dickhead", "dildo", "dildos", "dink", "dinks", "dirsa", "dlck", "dog-fucker", "doggin", "dogging", "donkeyribber", "doosh", "duche", "dyke", "ejaculate", "ejaculated", "ejaculates", "ejaculating", "ejaculatings", "ejaculation", "ejakulate", "f u c k", "f u c k e r", "f4nny", "fag", "fagging", "faggitt", "faggot", "faggs", "fagot", "fagots", "fags", "fanny", "fannyflaps", "fannyfucker", "fanyy", "fatass", "fcuk", "fcuker", "fcuking", "feck", "fecker", "felching", "fellate", "fellatio", "fingerfuck", "fingerfucked", "fingerfucker", "fingerfuckers", "fingerfucking", "fingerfucks", "fistfuck", "fistfucked", "fistfucker", "fistfuckers", "fistfucking", "fistfuckings", "fistfucks", "flange", "fook", "fooker", "fuck", "fucka", "fucked", "fucker", "fuckers", "fuckhead", "fuckheads", "fuckin", "fucking", "fuckings", "fuckingshitmotherfucker", "fuckme", "fucks", "fuckwhit", "fuckwit", "fudge packer", "fudgepacker", "fuk", "fuker", "fukker", "fukkin", "fuks", "fukwhit", "fukwit", "fux", "fux0r", "f_u_c_k", "gangbang", "gangbanged", "gangbangs", "gaylord", "gaysex", "goatse", "God", "god-dam", "god-damned", "goddamn", "goddamned", "hardcoresex", "hell", "heshe", "hoar", "hoare", "hoer", "homo", "hore", "horniest", "horny", "hotsex", "jack-off", "jackoff", "jap", "jerk-off", "jism", "jiz", "jizm", "jizz", "kawk", "knob", "knobead", "knobed", "knobend", "knobhead", "knobjocky", "knobjokey", "kock", "kondum", "kondums", "kum", "kummer", "kumming", "kums", "kunilingus", "l3i+ch", "l3itch", "labia", "lust", "lusting", "m0f0", "m0fo", "m45terbate", "ma5terb8", "ma5terbate", "masochist", "master-bate", "masterb8", "masterbat*", "masterbat3", "masterbate", "masterbation", "masterbations", "masturbate", "mo-fo", "mof0", "mofo", "mothafuck", "mothafucka", "mothafuckas", "mothafuckaz", "mothafucked", "mothafucker", "mothafuckers", "mothafuckin", "mothafucking", "mothafuckings", "mothafucks", "mother fucker", "motherfuck", "motherfucked", "motherfucker", "motherfuckers", "motherfuckin", "motherfucking", "motherfuckings", "motherfuckka", "motherfucks", "muff", "mutha", "muthafecker", "muthafuckker", "muther", "mutherfucker", "n1gga", "n1gger", "nazi", "nigg3r", "nigg4h", "nigga", "niggah", "niggas", "niggaz", "nigger", "niggers", "nob", "nob jokey", "nobhead", "nobjocky", "nobjokey", "numbnuts", "nutsack", "orgasim", "orgasims", "orgasm", "orgasms", "p0rn", "pawn", "pecker", "penis", "penisfucker", "phonesex", "phuck", "phuk", "phuked", "phuking", "phukked", "phukking", "phuks", "phuq", "pigfucker", "pimpis", "piss", "pissed", "pisser", "pissers", "pisses", "pissflaps", "pissin", "pissing", "pissoff", "poop", "porn", "porno", "pornography", "pornos", "prick", "pricks", "pron", "pube", "pusse", "pussi", "pussies", "pussy", "pussys", "rectum", "retard", "rimjaw", "rimming", "s hit", "s.o.b.", "sadist", "schlong", "screwing", "scroat", "scrote", "scrotum", "semen", "sex", "sh!+", "sh!t", "sh1t", "shag", "shagger", "shaggin", "shagging", "shemale", "shi+", "shit", "shitdick", "shite", "shited", "shitey", "shitfuck", "shitfull", "shithead", "shiting", "shitings", "shits", "shitted", "shitter", "shitters", "shitting", "shittings", "shitty", "skank", "slut", "sluts", "smegma", "smut", "snatch", "son-of-a-bitch", "spac", "spunk", "s_h_i_t", "t1tt1e5", "t1tties", "teets", "teez", "testical", "testicle", "tit", "titfuck", "tits", "titt", "tittie5", "tittiefucker", "titties", "tittyfuck", "tittywank", "titwank", "tosser", "turd", "tw4t", "twat", "twathead", "twatty", "twunt", "twunter", "v14gra", "v1gra", "vagina", "viagra", "vulva", "w00se", "wang", "wank", "wanker", "wanky", "whoar", "whore", "willies", "willy", "xrated", "xxx"]
        let cursedWordsSet = Set(cursedWordsList)
        
        // Removed regex compilations for performance
        
        // Pre-compute local emoji map once
        let safeLocalEmojiMap = self.localEmojiMap
// Load message index for naming DMs or Channels if needed
        let loadedMessageIndex = (try? JSONSerialization.jsonObject(with: Data(contentsOf: messagesRoot.appendingPathComponent("index.json")))) as? [String: String] ?? [:]
        
        // IMPROVEMENT: Load Server Name Index FIRST to validate extracted names (Fixes 18K phantom servers)
        var knownServerNames = Set<String>()
        if let data = try? Data(contentsOf: root.appendingPathComponent("Servers/index.json")),
           let sIndex = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            knownServerNames = Set(sIndex.values)
        }

        // 3. Batched Concurrent Execution with LIMITED concurrency
        log("Scanning \(allChannelFolders.count) channels with optimized batching...")
        
        let batchSize = 20 // Process 20 channels per batch
        let chunks = stride(from: 0, to: allChannelFolders.count, by: batchSize).map {
            Array(allChannelFolders[$0..<min($0 + batchSize, allChannelFolders.count)])
        }
        
        let queue = DispatchQueue(label: "com.discswift.messages", attributes: .concurrent)
        let group = DispatchGroup()
        // Message files are independent. A modest, hardware-aware worker count keeps
        // SSD throughput high without creating thousands of competing file reads.
        let workerCount = min(8, max(4, ProcessInfo.processInfo.activeProcessorCount - 2))
        let semaphore = DispatchSemaphore(value: workerCount)
        
        for (index, chunk) in chunks.enumerated() {
            group.enter()
            queue.async { [weak self] in
                semaphore.wait() // Acquire slot
                defer { 
                    semaphore.signal() // Release slot
                    group.leave() 
                }
                
                for folder in chunk {
                    var localMsgCount = 0
                    var localWordCount = 0
                    var localCharCount = 0
                    var localFileCount = 0
                    var localEmoteCount = 0
                    var localMentionCount = 0
                    
                    var localByHour = [Int](repeating: 0, count: 24)
                    var localByDay = [Int](repeating: 0, count: 7)
                    var localByMonth = [Int](repeating: 0, count: 12)
                    var localByYear: [Int: Int] = [:]
                    
                    var localWords: [String: Int] = [:]
                    var localEmojis: [String: Int] = [:]
                    var localCursed: [String: Int] = [:]
                    var localLinks: [String: Int] = [:]
                    var localDiscordLinks: [String: Int] = [:]
                    
                    // Detailed Stats Accumulators
                    var localServerStats: [String: StatsAccumulator] = [:]
                    var localDMStats: [String: StatsAccumulator] = [:]
                    var localUnassignedStats = StatsAccumulator()
                    var localDMNames: [String: String] = [:] // Store better names found locally
                    
                    var chId = folder.lastPathComponent
                    let channelFile = folder.appendingPathComponent("channel.json")
                    let messagesFile = folder.appendingPathComponent("messages.csv")
                    let jsonFile = folder.appendingPathComponent("messages.json")
                    
                    // Determine Context (DM vs Server)
                    var isDM = false
                    var guildId: String? = nil
                    
                    if let cData = try? Data(contentsOf: channelFile),
                       let cJson = try? JSONSerialization.jsonObject(with: cData) as? [String: Any] {
                        if let type = cJson["type"] as? Int, (type == 1 || type == 3) {
                            isDM = true
                        }
                        if let gid = cJson["guild_id"] as? String {
                            guildId = gid
                        }
                        // If we have an ID in channel.json, use it
                        if let cid = cJson["id"] as? String {
                            chId = cid
                        }
                        
                        // Extract Recipients for better DM naming (Fixes "Unknown Participant")
                        if let recipients = cJson["recipients"] as? [[String: Any]] {
                            let names = recipients.compactMap { $0["global_name"] as? String ?? $0["username"] as? String }
                            if !names.isEmpty {
                                localDMNames[chId] = names.joined(separator: ", ")
                            }
                        }
                    }
                    
                    // Fallback to folder structure if guildId missing
                    // Robust check: Search for "servers" casing-insensitively
                    if guildId == nil {
                        let pathLower = folder.path.lowercased()
                        if pathLower.contains("/servers") {
                             // Attempt to find parent folder name as Guild ID
                             let components = folder.pathComponents
                             // Find index of "Servers" (case insensitive)
                             if let idx = components.lastIndex(where: { $0.caseInsensitiveCompare("servers") == .orderedSame }),
                                idx + 2 < components.count {
                                  // Found it! Parent of this folder is GuildID
                                  // structure: .../Servers/GuildID/ChannelID
                                  if components[idx].caseInsensitiveCompare("servers") == .orderedSame {
                                      guildId = components[idx+1]
                                  }
                             }
                        }
                        
                        /* Restored & Improved: Fallback logic for Server detection
                        // Pattern: "channel-name in Server Name"
                        // This is crucial because many exports lack channel.json or folder structure
                        */
                        if guildId == nil, let name = loadedMessageIndex[chId] {
                            if let range = name.range(of: " in ", options: .backwards) {
                                let serverName = String(name[range.upperBound...])
                                
                                // STRICT VALIDATION: Only accept if it matches a KNOWN server in Servers/index.json
                                // This prevents "Unknown channel in User" (DMs) from being counted as Servers
                                if !serverName.isEmpty && 
                                   serverName != "Direct Messages" && 
                                   serverName != "Group Direct Messages" &&
                                   knownServerNames.contains(serverName) {
                                    
                                    // It's a valid Verified Server Name
                                    guildId = serverName
                                }
                            }
                        }
                    }
                    
                    var channelMsgCount = 0
                    
                    // Analyze once and update both global and conversation-level totals.
                    func processMessage(_ content: String, _ timestamp: String, detailed: inout StatsAccumulator) {
                        channelMsgCount += 1
                        localCharCount += content.count
                        detailed.messageCount += 1
                        detailed.charCount += content.count
                        
                        if let time = self?.parseTimestampParts(timestamp) {
                            localByHour[time.hour] += 1
                            localByDay[time.weekday] += 1
                            localByMonth[time.month - 1] += 1
                            localByYear[time.year, default: 0] += 1
                        }
                        
                        // Single-pass optimized parsing
                        let words = content.components(separatedBy: .whitespacesAndNewlines)
                        for word in words {
                            if word.isEmpty { continue }
                            let w = word.lowercased().trimmingCharacters(in: .punctuationCharacters)

                            // Mentions also use angle brackets, so they must be
                            // recognized before custom emoji.
                            if word.hasPrefix("<@") {
                                localMentionCount += 1
                                continue
                            }

                            // Check for Emoji
                            if word.hasPrefix("<") && word.hasSuffix(">") {
                                 localEmoteCount += 1
                                 localEmojis[word, default: 0] += 1
                                 detailed.emojis[word, default: 0] += 1
                                 continue
                            }

                            // Check for Cursed Words (O(1))
                            if cursedWordsSet.contains(w) {
                                localCursed[w, default: 0] += 1
                                detailed.cursed[w, default: 0] += 1
                                continue
                            }

                            // Check for Links
                            if w.hasPrefix("http") {
                                 localLinks[w, default: 0] += 1
                                 detailed.links[w, default: 0] += 1
                                 
                                 // Check for Discord Links
                                 if w.contains("discord.gg") || w.contains("discord.com/invite") {
                                     localDiscordLinks[w, default: 0] += 1
                                     detailed.discordLinks[w, default: 0] += 1
                                 }
                                 continue // Don't count links as words
                            }

                            // Valid Word
                            if !w.isEmpty && w.count > 2 {
                                 localWordCount += 1 // Count valid words
                                 detailed.wordCount += 1
                                 if w.count > 3 { // Statistic threshold for "Favorite Words"
                                     localWords[w, default: 0] += 1
                                     detailed.words[w, default: 0] += 1
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
                                    
                                    if let gid = guildId {
                                        processMessage(contentStr, timestampStr, detailed: &localServerStats[gid, default: StatsAccumulator()])
                                    } else if isDM || !folder.path.lowercased().contains("/servers") {
                                        processMessage(contentStr, timestampStr, detailed: &localDMStats[chId, default: StatsAccumulator()])
                                    } else {
                                        processMessage(contentStr, timestampStr, detailed: &localUnassignedStats)
                                    }
                                }
                            }
                        }
                    }
                    // --- JSON PARSING (Optimized) ---
                    else if FileManager.default.fileExists(atPath: jsonFile.path) {
                         // Improved: Use mappedIfSafe for memory
                        if let data = try? Data(contentsOf: jsonFile, options: .mappedIfSafe),
                           let messages = try? JSONDecoder().decode([DiscordMessage].self, from: data) {
                            for message in messages {
                               if let content = message.contents {
                                   let ts = message.timestamp
                                    if let gid = guildId {
                                        processMessage(content, ts, detailed: &localServerStats[gid, default: StatsAccumulator()])
                                    } else if isDM || !folder.path.lowercased().contains("/servers") {
                                        processMessage(content, ts, detailed: &localDMStats[chId, default: StatsAccumulator()])
                                    } else {
                                        processMessage(content, ts, detailed: &localUnassignedStats)
                                    }
                               }
                               if let attachments = message.attachments, !attachments.isEmpty {
                                   localFileCount += 1
                               }
                            }
                        }
                    }
                    
                    localMsgCount = channelMsgCount // Sync
                    
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
                    for m in 0..<12 { msgByMonth[m] += localByMonth[m] }
                    for (y, c) in localByYear { msgByYear[y, default: 0] += c }
                    
                    for (w, c) in localWords { wordCounts[w, default: 0] += c }
                    for (e, c) in localEmojis { emojiCounts[e, default: 0] += c }
                    
                    for (w, c) in localCursed { cursedCounts[w, default: 0] += c }
                    for (w, c) in localLinks { linkCounts[w, default: 0] += c }
                    for (w, c) in localDiscordLinks { discordLinkCounts[w, default: 0] += c }
                    
                    for (gid, acc) in localServerStats {
                        serverStats[gid, default: StatsAccumulator()].merge(other: acc)
                    }
                    for (dmid, acc) in localDMStats {
                        dmStats[dmid, default: StatsAccumulator()].merge(other: acc)
                        
                        // FIX: Correctly update DM Channel Info in valid scope
                        // Prioritize better name found locally (recipients)
                        if let betterName = localDMNames[dmid] {
                            dmChannelInfos[dmid] = betterName
                        } else if dmChannelInfos[dmid] == nil {
                             dmChannelInfos[dmid] = loadedMessageIndex[dmid] ?? "Unknown DM"
                        }
                    }
                    
                    // Also track loose DM IDs
                    if channelMsgCount > 0 && isDM {
                         dmChannelIds.insert(chId)
                    } else if channelMsgCount > 0 && guildId == nil {
                         // Check path one last time
                         let pathLower = folder.path.lowercased()
                         if !pathLower.contains("/servers") {
                             dmChannelIds.insert(chId)
                         }
                    }
                    lock.unlock()
                }
                
                // Progress logging
                if index % 5 == 0 {
                    let progress = Double(index * batchSize) / Double(allChannelFolders.count) * 100
                    let uiProgress = 0.15 + (progress / 100.0) * 0.75
                    self?.log(String(format: "Messages Progress: %.1f%%", progress))
                    self?.updateProgress(uiProgress, String(format: "Processing messages… %.0f%%", progress))
                }
            }
        }
        
        group.wait()
        
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
        
        let allServers = serverStats.map { (id, acc) in
            let name = serverIdToName[id] ?? "Server \(id)"
            return (name: name, messageCount: acc.messageCount)
        }.sorted { $0.messageCount > $1.messageCount }
        
        let topDMs = dmStats.map { (id, acc) in
            let rawName = dmChannelInfos[id] ?? "Unknown DM"
            let cleanName = rawName.replacingOccurrences(of: "Direct Message with ", with: "")
            return createDetailedStats(id: id, name: cleanName, acc: acc)
        }.sorted { $0.messageCount > $1.messageCount }.prefix(20).map { $0 }
        
        let allDMs = dmStats.map { (id, acc) in
            let rawName = dmChannelInfos[id] ?? "Unknown DM"
            var cleanName = rawName.replacingOccurrences(of: "Direct Message with ", with: "")
            cleanName = cleanName.replacingOccurrences(of: "Unknown channel in ", with: "") // Clean "Unknown channel in X"
            cleanName = cleanName.replacingOccurrences(of: " in Direct Messages", with: "")
            return (name: cleanName, messageCount: acc.messageCount)
        }.sorted { $0.messageCount > $1.messageCount }
        
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
            self.stats.messagesByMonth = msgByMonth
            self.stats.messagesByYear = msgByYear
            
            self.stats.topWords = topWords
            self.stats.topCustomEmojis = topEmojis
            self.stats.topServers = Array(topServers) // Explicitly cast if needed, though map returns array
            self.stats.serverList = allServers
            
            // Calculate total server messages
            self.stats.serverMessages = allServers.reduce(0) { $0 + $1.messageCount }
            
            self.stats.topDMs = Array(topDMs)
            self.stats.dmList = allDMs
            self.stats.topCursedWords = topCursed
            self.stats.topLinks = topLinks
            self.stats.topDiscordLinks = topDiscordLinks
            self.stats.dmConversations = dmChannelInfos.count
        }
    }
    

    

    
    /// Extracts the fields used by the charts directly from Discord's ISO timestamp.
    /// This avoids constructing several DateFormatter instances for every message.
    private func parseTimestampParts(_ timestamp: String) -> (year: Int, month: Int, hour: Int, weekday: Int)? {
        let bytes = timestamp.utf8
        guard bytes.count >= 13 else { return nil }

        func number(at offset: Int, length: Int) -> Int? {
            guard offset + length <= bytes.count else { return nil }
            var index = bytes.index(bytes.startIndex, offsetBy: offset)
            var value = 0
            for _ in 0..<length {
                let byte = bytes[index]
                guard byte >= 48, byte <= 57 else { return nil }
                value = value * 10 + Int(byte - 48)
                index = bytes.index(after: index)
            }
            return value
        }

        guard let year = number(at: 0, length: 4),
              let month = number(at: 5, length: 2),
              let day = number(at: 8, length: 2),
              let hour = number(at: 11, length: 2),
              (1...12).contains(month),
              (0...23).contains(hour)
        else { return nil }

        // Sakamoto's Gregorian weekday algorithm. Result is converted from
        // Sunday-based (0) to the app's Monday-based array (0).
        let offsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
        let adjustedYear = month < 3 ? year - 1 : year
        let sundayBased = (
            adjustedYear + adjustedYear / 4 - adjustedYear / 100 +
            adjustedYear / 400 + offsets[month - 1] + day
        ) % 7
        let mondayBased = (sundayBased + 6) % 7

        return (year, month, hour, mondayBased)
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
