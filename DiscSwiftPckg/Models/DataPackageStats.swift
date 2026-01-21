import Foundation

/// Statistics computed from the package structure for dashboard display
struct DataPackageStats {
    let totalFiles: Int
    let totalFolders: Int
    let messageConversations: Int
    let applications: Int
    let categories: [(name: String, icon: String, count: Int, color: String)]
    
    init(from root: FileNode?) {
        guard let root = root else {
            totalFiles = 0
            totalFolders = 0
            messageConversations = 0
            applications = 0
            categories = []
            return
        }
        
        totalFiles = root.totalFileCount
        totalFolders = root.totalFolderCount
        
        // Count message conversations
        if let messagesFolder = root.children?.first(where: { $0.name == "Messages" }) {
            messageConversations = messagesFolder.children?.count ?? 0
        } else {
            messageConversations = 0
        }
        
        // Count applications
        if let accountFolder = root.children?.first(where: { $0.name == "Account" }),
           let appsFolder = accountFolder.children?.first(where: { $0.name == "applications" }) {
            applications = appsFolder.children?.count ?? 0
        } else {
            applications = 0
        }
        
        // Build categories summary
        var cats: [(name: String, icon: String, count: Int, color: String)] = []
        for child in (root.children ?? []) where child.isDirectory {
            cats.append((
                name: child.displayName,
                icon: child.iconName,
                count: child.totalFileCount,
                color: child.iconColor
            ))
        }
        categories = cats.sorted { $0.count > $1.count }
    }
}
