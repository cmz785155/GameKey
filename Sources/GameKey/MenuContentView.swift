import SwiftUI
import AppKit
import ApplicationServices

struct MenuContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(model.isGameMode ? "🎮 游戏模式" : "⌨️ 普通模式")
                    .font(.headline)
                Spacer()
            }

            Text("当前输入法：\(model.currentInputName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Button(model.isGameMode ? "切换回普通模式" : "进入游戏模式") {
                model.toggleGameMode()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

            Divider()

            Toggle("游戏模式中保持英文", isOn: Binding(
                get: { model.keepEnglishInGame },
                set: { model.setKeepEnglish($0) }
            ))
            Toggle("启用快捷键守护", isOn: Binding(
                get: { model.shortcutGuardEnabled },
                set: { model.setGuardEnabled($0) }
            ))
            Text("守护会屏蔽 Cmd+Q / Cmd+Tab / Cmd+H / Cmd+M，保留 Cmd+Space、Cmd+C/V/W/T")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !AXIsProcessTrusted() {
                Text("⚠️ 快捷键守护需要「辅助功能」权限")
                    .font(.caption).foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                Button("打开系统设置授权") { model.openAccessibilitySettings() }
            }

            Divider()

            Toggle("自动检测游戏进程", isOn: Binding(
                get: { model.autoDetectEnabled },
                set: { model.setAutoDetect($0) }
            ))
            Button("把当前前台 App 设为游戏") { model.addCurrentFrontmostAppAsGame() }
            Menu("添加游戏（从运行中的 App）") {
                if model.runningCandidateApps.isEmpty {
                    Text("没有可添加的 App").foregroundStyle(.secondary)
                } else {
                    ForEach(model.runningCandidateApps) { app in
                        Button(app.name) { model.addGameApp(app) }
                    }
                }
            }
            .disabled(model.runningCandidateApps.isEmpty)

            if !model.gameApps.isEmpty {
                Text("已添加：\(model.gameApps.map(\.name).joined(separator: "、"))")
                    .font(.caption2).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("清除游戏列表") { model.clearGameApps() }
            }

            Text("这些 App 启动时自动进入游戏模式，全部退出后自动回到普通模式")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Button("刷新输入法状态") { model.refreshInput() }
            Button("退出 GameKey") { NSApp.terminate(nil) }
        }
        .padding(12)
        .frame(minWidth: 280)
    }
}
