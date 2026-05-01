import SwiftUI

extension Color {
    static let appBg          = Color(hex: 0xFFF9F4)
    static let appPeach       = Color(hex: 0xFDDBC6)
    static let appPeachMid    = Color(hex: 0xF5B896)
    static let appTerra       = Color(hex: 0xD97455)
    static let appSage        = Color(hex: 0xA8C5A0)
    static let appSageLt      = Color(hex: 0xD6EAD0)
    static let appSageDark    = Color(hex: 0x5A8A52)
    static let appWarmGray    = Color(hex: 0xD0C6BE)
    static let appWarmGrayLt  = Color(hex: 0xEDE9E5)
    static let appText        = Color(hex: 0x3A2820)
    static let appMuted       = Color(hex: 0x9A8880)
    static let appWhite       = Color(hex: 0xFFFDF9)
    static let appBorder      = Color(hex: 0xE8DDD5)

    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8)  & 0xFF) / 255
        let b = Double(hex         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
