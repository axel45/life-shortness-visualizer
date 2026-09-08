import SwiftUI

enum DotColor {
    case future
    case unrecorded
    case normal    // recorded, avg ≤ 4.5
    case sunshine  // recorded, avg > 4.5
}

enum ColorResolver {

    static func dotColor(for weekRecord: WeekRecord?, isFuture: Bool) -> DotColor {
        if isFuture { return .future }
        guard let record = weekRecord, let avg = record.averageStars else { return .unrecorded }
        return avg > 4.5 ? .sunshine : .normal
    }

    static func color(for dotColor: DotColor) -> Color {
        switch dotColor {
        case .future:     return Color(hex: "48484A")  // チャコールグレー（小）
        case .unrecorded: return Color(hex: "48484A")  // チャコールグレー
        case .normal:     return Color(hex: "AEAEB2")  // ライトグレー
        case .sunshine:   return Color(hex: "FFE566")  // サンシャイン
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
