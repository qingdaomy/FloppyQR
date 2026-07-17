#!/bin/bash
# 数字软盘生成器 - 项目设置脚本
# 需要安装 XcodeGen: brew install xcodegen

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v xcodegen &> /dev/null; then
    echo "正在安装 XcodeGen..."
    brew install xcodegen
fi

echo "正在生成 Xcode 项目..."
xcodegen generate

echo "完成！请打开 数字软盘生成器.xcodeproj"
