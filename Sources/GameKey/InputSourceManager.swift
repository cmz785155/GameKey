import Foundation
import Carbon.HIToolbox

/// 输入法（输入源）管理：列出、识别英文 ABC、切换输入源。
enum InputSourceManager {

    /// 所有输入源（含未启用的）。
    static func allSources() -> [TISInputSource] {
        guard let raw = TISCreateInputSourceList(nil, false) else { return [] }
        return (raw.takeRetainedValue() as? [TISInputSource]) ?? []
    }

    /// 仅「已启用」的输入源。
    static func listEnabled() -> [TISInputSource] {
        allSources().filter(isEnabled)
    }

    /// 当前选中的输入源。
    static func current() -> TISInputSource? {
        TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }

    static func currentID() -> String? {
        current().flatMap { property($0, kTISPropertyInputSourceID) }
    }

    static func currentName() -> String? {
        current().flatMap { property($0, kTISPropertyLocalizedName) }
    }

    static func isCurrentEnglish() -> Bool {
        current().map(isEnglish) ?? false
    }

    /// 判断是否为「英文键盘布局」（如 ABC / English / U.S.）。
    /// 注意：中文拼音的输入源 ID 也含 "ABC" 字样（com.apple.inputmethod.SCIM.ITABC），
    /// 但它的类型是「输入法」而非「键盘布局」，这里用类型 + ID + 名称三重判断，避免误判。
    static func isEnglish(_ source: TISInputSource) -> Bool {
        let type = property(source, kTISPropertyInputSourceType) ?? ""
        guard type == (kTISTypeKeyboardLayout as String) else { return false }

        let id = property(source, kTISPropertyInputSourceID) ?? ""
        if id == "com.apple.keylayout.ABC" { return true }

        let name = (property(source, kTISPropertyLocalizedName) ?? "").lowercased()
        return name == "abc" || name == "english" || name == "u.s." || name.hasPrefix("u.s. ")
    }

    static func englishSource() -> TISInputSource? {
        listEnabled().first(where: isEnglish)
    }

    /// 切到英文输入源（游戏模式用）。
    @discardableResult
    static func selectEnglish() -> Bool {
        guard let source = englishSource() else { return false }
        return TISSelectInputSource(source) == noErr
    }

    /// 按输入源 ID 切换（退出游戏模式时恢复原输入法）。
    @discardableResult
    static func select(id: String) -> Bool {
        guard let source = listEnabled().first(where: { property($0, kTISPropertyInputSourceID) == id }) else {
            return false
        }
        return TISSelectInputSource(source) == noErr
    }

    // MARK: - 私有辅助

    static func property(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return nil }
        let value = Unmanaged<CFTypeRef>.fromOpaque(ptr).takeUnretainedValue()
        return value as? String
    }

    private static func isEnabled(_ source: TISInputSource) -> Bool {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) else { return false }
        let value = Unmanaged<CFTypeRef>.fromOpaque(ptr).takeUnretainedValue()
        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            return CFBooleanGetValue((value as! CFBoolean))
        }
        return false
    }
}
