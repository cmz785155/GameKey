#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="GameKey"
BUNDLE_ID="com.gamekey.app"
VERSION="1.0.0"

echo "==> swift build (release)"
swift build -c release

BIN=".build/release/${APP_NAME}"
if [[ ! -x "$BIN" ]]; then
    echo "构建失败：未找到 $BIN"
    exit 1
fi

echo "==> 打包 ${APP_NAME}.app"
APP="dist/${APP_NAME}.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/${APP_NAME}"
cp Resources/Info.plist "$APP/Contents/Info.plist"

echo "==> adhoc 签名"
codesign --force --deep --sign - "$APP"

echo "==> 完成：${APP}"
echo "   双击打开，或在 Finder 中拖入「应用程序」文件夹。"
