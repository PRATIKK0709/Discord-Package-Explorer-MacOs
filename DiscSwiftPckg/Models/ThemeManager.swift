import SwiftUI
import Combine

enum ThemeProfile: String, CaseIterable, Identifiable {
    case standard = "Soft Pastel"
    case discord = "Lavender"
    
    var id: String { rawValue }
}

class ThemeManager: ObservableObject {
    @Published var currentProfile: ThemeProfile {
        didSet {
            UserDefaults.standard.set(currentProfile.rawValue, forKey: "selectedTheme")
        }
    }
    
    init() {
        // storage init
        if let saved = UserDefaults.standard.string(forKey: "selectedTheme"),
           let profile = ThemeProfile(rawValue: saved) {
            self.currentProfile = profile
        } else {
            self.currentProfile = .standard
        }
    }
    
    // Derived Colors
    var bgPrimary: Color { Color(hex: 0xF8FAFD) }
    
    var bgSecondary: Color {
        Color.white
    }
    
    var bgTertiary: Color {
        currentProfile == .discord ? Color(hex: 0xF0EEFF) : Color(hex: 0xF1F5F9)
    }
    
    var textPrimary: Color {
        Color(hex: 0x172033)
    }
    
    var textSecondary: Color {
        Color(hex: 0x718096)
    }
    
    var accent: Color {
        currentProfile == .discord ? Color(hex: 0x8B7CF6) : Color(hex: 0x6D8EF7)
    }
    
    var border: Color {
        Color(hex: 0xE6EAF0)
    }
    
    var cardBg: Color {
        Color.white
    }

    var mint: Color { Color(hex: 0xDDF7EC) }
    var lavender: Color { Color(hex: 0xEEE9FF) }
    var peach: Color { Color(hex: 0xFFF0E4) }
    var sky: Color { Color(hex: 0xE4F2FF) }
    var rose: Color { Color(hex: 0xFFE9F0) }
}
