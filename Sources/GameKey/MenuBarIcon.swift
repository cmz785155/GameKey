import AppKit

/// 生成彩色菜单栏图标（按模式区分颜色，更醒目）。
enum MenuBarIcon {
    static func icon(gameMode: Bool) -> NSImage {
        let symbolName = gameMode ? "gamecontroller.fill" : "keyboard"
        let color: NSColor = gameMode ? .systemRed : .systemBlue
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)

        guard let base = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil),
              let configured = base.withSymbolConfiguration(config) else {
            return NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) ?? NSImage()
        }

        let tinted = configured.copy() as! NSImage
        tinted.lockFocus()
        color.set()
        NSRect(origin: .zero, size: tinted.size).fill(using: .sourceAtop)
        tinted.unlockFocus()
        tinted.isTemplate = false
        return tinted
    }
}
