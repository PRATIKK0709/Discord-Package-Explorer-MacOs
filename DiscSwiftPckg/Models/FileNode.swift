import Foundation

/// Represents a file or directory node in the package structure
struct FileNode: Codable, Identifiable, Hashable {
    let name: String
    let type: String
    let children: [FileNode]?
    
    var id: String { name }
    
    var isDirectory: Bool {
        type == "directory"
    }
    
    var isFile: Bool {
        type == "file"
    }
    
    /// Returns a user-friendly display name
    var displayName: String {
        // Convert technical names to friendly names
        switch name {
        case "Account": return "Your Account"
        case "Activities": return "Activities & Games"
        case "Activity": return "Activity Logs"
        case "Ads": return "Advertising Data"
        case "Messages": return "Your Messages"
        case "Servers": return "Server Info"
        case "applications": return "Connected Apps"
        case "recent_avatars": return "Recent Avatars"
        default:
            // Clean up channel IDs and other technical names
            if name.hasPrefix("c") && name.count > 15 && name.dropFirst().allSatisfy({ $0.isNumber }) {
                return "Conversation"
            }
            if name.allSatisfy({ $0.isNumber }) && name.count > 10 {
                return "Application"
            }
            return name.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    /// Returns an appropriate SF Symbol icon
    var iconName: String {
        if isDirectory {
            switch name {
            case "Account": return "person.circle.fill"
            case "Activities": return "gamecontroller.fill"
            case "Activity": return "chart.line.uptrend.xyaxis"
            case "Ads": return "megaphone.fill"
            case "Messages": return "bubble.left.and.bubble.right.fill"
            case "Servers": return "server.rack"
            case "applications": return "app.badge.fill"
            case "recent_avatars": return "person.crop.circle.badge.clock"
            default:
                if name.hasPrefix("c") && name.count > 15 {
                    return "bubble.left.fill"
                }
                return "folder.fill"
            }
        } else {
            // File icons based on extension
            let ext = (name as NSString).pathExtension.lowercased()
            switch ext {
            case "json": return "doc.text.fill"
            case "png", "jpg", "jpeg", "gif": return "photo.fill"
            case "txt": return "doc.plaintext.fill"
            default: return "doc.fill"
            }
        }
    }
    
    /// Icon color based on type
    var iconColor: String {
        if isDirectory {
            switch name {
            case "Account": return "blue"
            case "Activities": return "purple"
            case "Activity": return "green"
            case "Ads": return "orange"
            case "Messages": return "indigo"
            case "Servers": return "teal"
            default: return "gray"
            }
        } else {
            let ext = (name as NSString).pathExtension.lowercased()
            switch ext {
            case "json": return "yellow"
            case "png", "jpg", "jpeg", "gif": return "pink"
            default: return "secondary"
            }
        }
    }
    
    /// Count of immediate children
    var childCount: Int {
        children?.count ?? 0
    }
    
    /// Recursive count of all files
    var totalFileCount: Int {
        if isFile { return 1 }
        return (children ?? []).reduce(0) { $0 + $1.totalFileCount }
    }
    
    /// Recursive count of all directories
    var totalFolderCount: Int {
        if isFile { return 0 }
        return 1 + (children ?? []).reduce(0) { $0 + $1.totalFolderCount }
    }
}
