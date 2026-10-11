#!/usr/bin/env bash
set -euo pipefail
BUNDLE_ID="com.gamekey.app"
launchctl bootout "gui/$(id -u)/${BUNDLE_ID}" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/${BUNDLE_ID}.plist"
echo "✅ 已关闭开机自启。"
