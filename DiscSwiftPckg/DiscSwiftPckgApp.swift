import SwiftUI

@main
struct DiscSwiftPckgApp: App {
    @StateObject private var viewModel = PackageViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .windowResizability(.contentSize)
    }
}
