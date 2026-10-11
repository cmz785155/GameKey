#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="GameKey"
BUNDLE_ID="com.gamekey.app"
SRC="dist/${APP_NAME}.app"
DEST_DIR="$HOME/Applications"
DEST="$DEST_DIR/${APP_NAME}.app"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/${BUNDLE_ID}.plist"

if [[ ! -d "$SRC" ]]; then
    echo "错误：找不到 $SRC，请先在 GameKey 目录下执行 ./build.sh"
    exit 1
fi

echo "==> 复制到 $DEST"
mkdir -p "$DEST_DIR"
rm -rf "$DEST"
cp -R "$SRC" "$DEST"

echo "==> 生成 LaunchAgent"
mkdir -p "$PLIST_DIR"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${BUNDLE_ID}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>${DEST}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

echo "==> 加载 LaunchAgent"
launchctl bootout "gui/$(id -u)/${BUNDLE_ID}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "✅ 完成：GameKey 已设为开机自启（下次登录自动运行）。"
echo "   想立即启动一次：open '${DEST}'"
