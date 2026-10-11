import Foundation
import CoreGraphics
import ApplicationServices

/// 快捷键守护：游戏模式下用 CGEventTap 拦截并丢弃「纯 Cmd + 键」的危险组合。
///
/// 说明（务必阅读）：
/// - 需要「辅助功能」权限（AXIsProcessTrusted），否则 tap 不会生效。
/// - Cmd+Tab（应用切换器）由系统级处理，能否被完全拦截取决于 macOS 版本，
///   属于尽力而为；Cmd+Q / Cmd+H / Cmd+M 通常能稳定拦截。
final class ShortcutGuard {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// 游戏模式下要屏蔽的「纯 Cmd + 键」组合（macOS 虚拟键码）。
    /// 0x04 = H（隐藏窗口） 0x0C = Q（退出应用） 0x2E = M（最小化） 0x30 = Tab（切换应用）
    private let blockedKeyCodes: Set<CGKeyCode> = [0x04, 0x0C, 0x2E, 0x30]

    func start() {
        guard AXIsProcessTrusted() else { return }
        guard eventTap == nil else { return }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, _, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let guardRef = Unmanaged<ShortcutGuard>.fromOpaque(refcon).takeUnretainedValue()
                return guardRef.shouldBlock(event) ? nil : Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
    }

    /// 只拦截「恰好只有 Cmd」的按键（不含 Shift/Option/Control），
    /// 这样 Cmd+Space、Cmd+C/V/W/T、Cmd+Shift+… 等都不受影响。
    private func shouldBlock(_ event: CGEvent) -> Bool {
        let modifierMask: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
        let mods = event.flags.intersection(modifierMask)
        guard mods == .maskCommand else { return false }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        return blockedKeyCodes.contains(keyCode)
    }
}
