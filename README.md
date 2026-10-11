# GameKey（游戏键）

一个 macOS 菜单栏小工具：一键切换「游戏模式 / 普通模式」，解决打游戏时中文输入法弹候选框、卡输入、误触快捷键的问题。

## 它能做什么

| 功能 | 说明 |
| --- | --- |
| 游戏模式 | 自动切成英文输入法（ABC），游戏里按 WASD / 聊天不再弹中文候选框 |
| 普通模式 | 恢复你之前用的输入法，正常中英自由切换 |
| 保持英文 | 游戏模式中若被切走，自动切回英文（默认关，可开） |
| 快捷键守护 | 游戏模式下屏蔽 `Cmd+Q` / `Cmd+Tab` / `Cmd+H` / `Cmd+M`，保留 `Cmd+Space`、`Cmd+C/V/W/T` |
| 自动检测游戏 | 添加游戏 App 后，它一启动就自动进游戏模式，全部退出自动回普通模式 |
| 开机自启 | 提供安装脚本（LaunchAgent） |
| 彩色图标 | 菜单栏图标按模式变色：普通=蓝色键盘，游戏=红色手柄 |

## 环境要求

- macOS 13 或更高（本机为 macOS 27.0.1，arm64）
- 无需安装 Xcode，只需 Xcode 命令行工具（`xcode-select --install`）

## 构建 & 打包

```bash
cd GameKey
./build.sh
```

打包产物在 `dist/GameKey.app`。双击即可运行（菜单栏出现图标）。

## 首次使用

1. 打开 `GameKey.app`，顶部菜单栏出现图标。
2. 点图标 →「进入游戏模式」，输入法自动切到英文 ABC。
3. 再点「切换回普通模式」，恢复原来的中文输入法。

### 自动检测游戏

1. 先启动你的游戏。
2. 点 GameKey 图标 → 打开「自动检测游戏进程」开关。
3. 点「把当前前台 App 设为游戏」，或在「添加游戏（从运行中的 App）」里选中你的游戏。
4. 之后游戏一启动就自动进游戏模式，游戏全退就自动回普通模式。

### 快捷键守护的权限

「快捷键守护」需要**辅助功能**权限：

1. 打开「启用快捷键守护」后，点「打开系统设置授权」。
2. 系统设置 → 隐私与安全性 → 辅助功能 → 勾选 GameKey。
3. 若仍提示无权限，退出 GameKey 重开一次。

> 注意：`Cmd+Tab`（应用切换器）由系统级处理，能否被完全拦截取决于 macOS 版本，
> 属于尽力而为；`Cmd+Q / Cmd+H / Cmd+M` 通常能稳定拦截。

## 开机自启

```bash
cd GameKey
./install-autostart.sh      # 开启开机自启（复制到 ~/Applications 并注册 LaunchAgent）
./uninstall-autostart.sh    # 关闭开机自启
```

## 常见问题

- **英文 ABC 没生效？** 系统设置 → 键盘 → 输入法，确认已添加「ABC」（美国英文）。
- **想改默认屏蔽的快捷键？** 编辑 `Sources/GameKey/ShortcutGuard.swift` 里的 `blockedKeyCodes`
  键码列表（0x04=H、0x0C=Q、0x2E=M、0x30=Tab），重新 `./build.sh`。

## 项目结构

```
GameKey/
├── Package.swift                    # SwiftPM 配置
├── Sources/GameKey/
│   ├── GameKeyApp.swift             # 入口 + MenuBarExtra
│   ├── AppModel.swift               # 状态、模式切换、自动检测
│   ├── InputSourceManager.swift     # 输入源枚举/识别/切换
│   ├── ShortcutGuard.swift          # CGEventTap 快捷键守护
│   ├── MenuContentView.swift        # 菜单内容
│   └── MenuBarIcon.swift            # 彩色菜单栏图标
├── Resources/Info.plist             # .app 打包用
├── build.sh                         # 构建 + 打包脚本
├── install-autostart.sh             # 开机自启（开启）
├── uninstall-autostart.sh           # 开机自启（关闭）
└── README.md
```

## 贡献者

DeepSeek
