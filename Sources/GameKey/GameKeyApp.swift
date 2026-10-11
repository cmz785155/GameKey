import SwiftUI
import AppKit

@main
struct GameKeyApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(model: model)
        } label: {
            // 菜单栏图标：普通模式=蓝色键盘，游戏模式=红色手柄
            Image(nsImage: MenuBarIcon.icon(gameMode: model.isGameMode))
        }
        .menuBarExtraStyle(.menu)
    }
}
