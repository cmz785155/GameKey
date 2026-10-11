import Foundation
import AppKit

/// 一个「游戏 App」记录。
struct GameApp: Codable, Identifiable, Equatable {
    let id: String      // bundleIdentifier
    let name: String    // 显示名
}

/// 应用核心状态与逻辑。
final class AppModel: ObservableObject {
    @Published var isGameMode = false
    @Published var currentInputName = "—"
    @Published var keepEnglishInGame = false
    @Published var shortcutGuardEnabled = true
    @Published var autoDetectEnabled = false
    @Published var gameApps: [GameApp] = []

    private var restoreSourceID: String?
    private var keepTimer: Timer?
    private let shortcutGuard = ShortcutGuard()
    private var autoEnteredGameMode = false
    private var launchObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?

    private static let gameAppsKey = "gameApps"

    init() {
        currentInputName = InputSourceManager.currentName() ?? "未知"
        gameApps = Self.loadGameApps()
        startObserving()
    }

    // MARK: - 模式切换

    func toggleGameMode() {
        isGameMode ? exitGameMode() : enterGameMode(auto: false)
    }

    func enterGameMode(auto: Bool = false) {
        restoreSourceID = InputSourceManager.currentID()
        InputSourceManager.selectEnglish()
        isGameMode = true
        autoEnteredGameMode = auto
        refreshInput()
        startKeepTimerIfNeeded()
        applyGuard()
    }

    func exitGameMode() {
        stopKeepTimer()
        shortcutGuard.stop()
        if let id = restoreSourceID {
            InputSourceManager.select(id: id)
        }
        isGameMode = false
        autoEnteredGameMode = false
        refreshInput()
    }

    // MARK: - 输入法 / 快捷键守护

    func refreshInput() {
        currentInputName = InputSourceManager.currentName() ?? "未知"
    }

    func setKeepEnglish(_ value: Bool) {
        keepEnglishInGame = value
        value ? startKeepTimerIfNeeded() : stopKeepTimer()
    }

    func setGuardEnabled(_ value: Bool) {
        shortcutGuardEnabled = value
        applyGuard()
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - 自动检测游戏

    func setAutoDetect(_ value: Bool) {
        autoDetectEnabled = value
        if value { handleAppChange() }
    }

    /// 当前运行中、可添加为游戏的 App（排除自身和已添加的）。
    var runningCandidateApps: [GameApp] {
        let addedIds = Set(gameApps.map { $0.id })
        var seen = Set<String>()
        var result: [GameApp] = []
        for app in NSWorkspace.shared.runningApplications {
            guard let id = app.bundleIdentifier, id != "com.gamekey.app" else { continue }
            guard !addedIds.contains(id), !seen.contains(id) else { continue }
            seen.insert(id)
            result.append(GameApp(id: id, name: app.localizedName ?? id))
        }
        result.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return result
    }

    func addCurrentFrontmostAppAsGame() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let id = app.bundleIdentifier,
              id != "com.gamekey.app" else { return }
        addGameApp(GameApp(id: id, name: app.localizedName ?? id))
    }

    func addGameApp(_ app: GameApp) {
        guard !gameApps.contains(where: { $0.id == app.id }) else { return }
        gameApps.append(app)
        persistGameApps()
    }

    func removeGameApp(_ app: GameApp) {
        gameApps.removeAll { $0.id == app.id }
        persistGameApps()
    }

    func clearGameApps() {
        gameApps.removeAll()
        persistGameApps()
    }

    private func startObserving() {
        let center = NSWorkspace.shared.notificationCenter
        launchObserver = center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.handleAppChange() }
        terminateObserver = center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.handleAppChange() }
    }

    private func handleAppChange() {
        guard autoDetectEnabled else { return }
        let running = isAnyGameRunning()
        if running && !isGameMode {
            enterGameMode(auto: true)
        } else if !running && isGameMode && autoEnteredGameMode {
            exitGameMode()
        }
    }

    private func isAnyGameRunning() -> Bool {
        guard !gameApps.isEmpty else { return false }
        let ids = Set(gameApps.map { $0.id })
        let names = Set(gameApps.map { $0.name.lowercased() })
        for app in NSWorkspace.shared.runningApplications {
            if let bid = app.bundleIdentifier, ids.contains(bid) { return true }
            if let ln = app.localizedName, names.contains(ln.lowercased()) { return true }
        }
        return false
    }

    private func persistGameApps() {
        if let data = try? JSONEncoder().encode(gameApps) {
            UserDefaults.standard.set(data, forKey: Self.gameAppsKey)
        }
    }

    private static func loadGameApps() -> [GameApp] {
        guard let data = UserDefaults.standard.data(forKey: gameAppsKey),
              let apps = try? JSONDecoder().decode([GameApp].self, from: data) else { return [] }
        return apps
    }

    // MARK: - 私有：守护 / 保持英文

    private func applyGuard() {
        if shortcutGuardEnabled && isGameMode {
            shortcutGuard.start()
        } else {
            shortcutGuard.stop()
        }
    }

    private func startKeepTimerIfNeeded() {
        guard keepEnglishInGame, keepTimer == nil else { return }
        keepTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.assertEnglish()
        }
    }

    private func stopKeepTimer() {
        keepTimer?.invalidate()
        keepTimer = nil
    }

    private func assertEnglish() {
        guard isGameMode else { return }
        if !InputSourceManager.isCurrentEnglish() {
            InputSourceManager.selectEnglish()
            refreshInput()
        }
    }
}
