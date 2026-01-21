import SwiftUI

struct FolderDetailView: View {
    let node: FileNode
    @State private var expandedNodes: Set<String> = []
    @State private var searchText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorForNode(node).opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: node.iconName)
                            .font(.title2)
                            .foregroundStyle(colorForNode(node))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(node.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(node.totalFileCount) files • \(node.totalFolderCount) folders")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search files...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .padding()
            
            // Content list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if let children = node.children {
                        ForEach(filteredChildren(children)) { child in
                            FileNodeRow(
                                node: child,
                                depth: 0,
                                expandedNodes: $expandedNodes,
                                searchText: searchText
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    func filteredChildren(_ children: [FileNode]) -> [FileNode] {
        if searchText.isEmpty { return children }
        return children.filter { nodeMatchesSearch($0, query: searchText.lowercased()) }
    }
    
    func nodeMatchesSearch(_ node: FileNode, query: String) -> Bool {
        if node.name.lowercased().contains(query) { return true }
        if node.displayName.lowercased().contains(query) { return true }
        if let children = node.children {
            return children.contains { nodeMatchesSearch($0, query: query) }
        }
        return false
    }
    
    func colorForNode(_ node: FileNode) -> Color {
        switch node.iconColor {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "indigo": return .indigo
        case "teal": return .teal
        case "pink": return .pink
        case "yellow": return .yellow
        default: return .secondary
        }
    }
}

struct FileNodeRow: View {
    let node: FileNode
    let depth: Int
    @Binding var expandedNodes: Set<String>
    let searchText: String
    
    private var isExpanded: Bool {
        expandedNodes.contains(node.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Row content
            HStack(spacing: 8) {
                // Indentation
                if depth > 0 {
                    ForEach(0..<depth, id: \.self) { _ in
                        Rectangle()
                            .fill(.quaternary)
                            .frame(width: 1)
                            .padding(.leading, 12)
                    }
                }
                
                // Expand button for directories
                if node.isDirectory {
                    Button(action: toggleExpanded) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                        .frame(width: 16)
                }
                
                // Icon
                Image(systemName: node.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                    .frame(width: 20)
                
                // Name
                Text(node.displayName)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                Spacer()
                
                // Child count for directories
                if node.isDirectory && node.childCount > 0 {
                    Text("\(node.childCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isExpanded && node.isDirectory ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if node.isDirectory {
                    toggleExpanded()
                }
            }
            
            // Children (if expanded)
            if isExpanded, let children = node.children {
                ForEach(children) { child in
                    FileNodeRow(
                        node: child,
                        depth: depth + 1,
                        expandedNodes: $expandedNodes,
                        searchText: searchText
                    )
                }
            }
        }
    }
    
    private func toggleExpanded() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if isExpanded {
                expandedNodes.remove(node.id)
            } else {
                expandedNodes.insert(node.id)
            }
        }
    }
    
    private var iconColor: Color {
        if node.isDirectory {
            return .orange
        }
        let ext = (node.name as NSString).pathExtension.lowercased()
        switch ext {
        case "json": return .yellow
        case "png", "jpg", "jpeg", "gif": return .pink
        case "txt": return .secondary
        default: return .blue
        }
    }
}

#Preview {
    FolderDetailView(node: FileNode(
        name: "Messages",
        type: "directory",
        children: [
            FileNode(name: "channel1", type: "directory", children: [
                FileNode(name: "messages.json", type: "file", children: nil),
                FileNode(name: "channel.json", type: "file", children: nil)
            ]),
            FileNode(name: "channel2", type: "directory", children: nil)
        ]
    ))
    .frame(width: 600, height: 500)
}
