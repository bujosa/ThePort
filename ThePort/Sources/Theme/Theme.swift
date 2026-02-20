import SwiftUI

// MARK: - Theme Manager

@Observable
class ThemeManager {
    static let shared = ThemeManager()

    var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }

    private init() {
        self.isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
    }

    var current: TPThemeColors {
        isDarkMode ? TPThemeColors.dark : TPThemeColors.light
    }
}

// MARK: - Theme Colors

struct TPThemeColors {
    let background: Color
    let surface: Color
    let card: Color
    let cardHover: Color
    let accent: Color
    let accentSecondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    let border: Color
    let borderLight: Color

    // Dark theme
    static let dark = TPThemeColors(
        background: Color(hex: "0D0D0D"),
        surface: Color(hex: "1A1A1A"),
        card: Color(hex: "242424"),
        cardHover: Color(hex: "2A2A2A"),
        accent: Color(hex: "3B82F6"),
        accentSecondary: Color(hex: "8B5CF6"),
        textPrimary: Color(hex: "FFFFFF"),
        textSecondary: Color(hex: "A3A3A3"),
        textMuted: Color(hex: "737373"),
        success: Color(hex: "22C55E"),
        warning: Color(hex: "F59E0B"),
        error: Color(hex: "EF4444"),
        info: Color(hex: "3B82F6"),
        border: Color(hex: "333333"),
        borderLight: Color(hex: "404040")
    )

    // Light theme
    static let light = TPThemeColors(
        background: Color(hex: "F5F5F5"),
        surface: Color(hex: "FFFFFF"),
        card: Color(hex: "FFFFFF"),
        cardHover: Color(hex: "F0F0F0"),
        accent: Color(hex: "2563EB"),
        accentSecondary: Color(hex: "7C3AED"),
        textPrimary: Color(hex: "111111"),
        textSecondary: Color(hex: "4B5563"),
        textMuted: Color(hex: "9CA3AF"),
        success: Color(hex: "16A34A"),
        warning: Color(hex: "D97706"),
        error: Color(hex: "DC2626"),
        info: Color(hex: "2563EB"),
        border: Color(hex: "E5E5E5"),
        borderLight: Color(hex: "D4D4D4")
    )
}

// MARK: - Static Theme Access (uses current theme)

enum TPTheme {
    static var background: Color { ThemeManager.shared.current.background }
    static var surface: Color { ThemeManager.shared.current.surface }
    static var card: Color { ThemeManager.shared.current.card }
    static var cardHover: Color { ThemeManager.shared.current.cardHover }
    static var accent: Color { ThemeManager.shared.current.accent }
    static var accentSecondary: Color { ThemeManager.shared.current.accentSecondary }
    static var textPrimary: Color { ThemeManager.shared.current.textPrimary }
    static var textSecondary: Color { ThemeManager.shared.current.textSecondary }
    static var textMuted: Color { ThemeManager.shared.current.textMuted }
    static var success: Color { ThemeManager.shared.current.success }
    static var warning: Color { ThemeManager.shared.current.warning }
    static var error: Color { ThemeManager.shared.current.error }
    static var info: Color { ThemeManager.shared.current.info }
    static var border: Color { ThemeManager.shared.current.border }
    static var borderLight: Color { ThemeManager.shared.current.borderLight }

    // Sizes
    static let cornerRadius: CGFloat = 8
    static let cardCornerRadius: CGFloat = 12
    static let sidebarWidth: CGFloat = 220
    static let spacing: CGFloat = 12
    static let spacingSmall: CGFloat = 8
    static let spacingLarge: CGFloat = 16

    // State colors
    static var listening: Color { ThemeManager.shared.current.success }
    static var established: Color { ThemeManager.shared.current.info }
    static var waiting: Color { ThemeManager.shared.current.warning }
    static var closing: Color { Color(hex: "F97316") }
    static var closed: Color { ThemeManager.shared.current.textMuted }

    // Priority colors
    static var priorityCritical: Color { ThemeManager.shared.current.error }
    static var priorityHigh: Color { Color(hex: "F97316") }
    static var priorityMedium: Color { ThemeManager.shared.current.info }
    static var priorityLow: Color { ThemeManager.shared.current.textMuted }

    static func stateColor(_ state: PortState) -> Color {
        switch state {
        case .listen: return listening
        case .established: return established
        case .timeWait, .finWait1, .finWait2: return waiting
        case .closeWait, .closing, .lastAck: return closing
        case .closed: return closed
        case .synSent, .synReceived: return accentSecondary
        case .unknown: return textMuted
        }
    }

    static func priorityColor(_ priority: WatchlistPriority) -> Color {
        switch priority {
        case .critical: return priorityCritical
        case .high: return priorityHigh
        case .medium: return priorityMedium
        case .low: return priorityLow
        }
    }

    static func cpuColor(_ percent: Double) -> Color {
        if percent > 80 { return error }
        if percent > 50 { return warning }
        if percent > 20 { return Color(hex: "FBBF24") }
        return success
    }

    static func memoryColor(_ percent: Double) -> Color {
        if percent > 80 { return error }
        if percent > 50 { return warning }
        return success
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else { return "000000" }
        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    @State var themeManager = ThemeManager.shared
    var isHovering: Bool = false

    func body(content: Content) -> some View {
        content
            .background(isHovering ? themeManager.current.cardHover : themeManager.current.card)
            .cornerRadius(TPTheme.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: TPTheme.cardCornerRadius)
                    .stroke(themeManager.current.border, lineWidth: 1)
            )
    }
}

struct SurfaceStyle: ViewModifier {
    @State var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .background(themeManager.current.surface)
            .cornerRadius(TPTheme.cornerRadius)
    }
}

extension View {
    func cardStyle(isHovering: Bool = false) -> some View {
        modifier(CardStyle(isHovering: isHovering))
    }

    func surfaceStyle() -> some View {
        modifier(SurfaceStyle())
    }
}
