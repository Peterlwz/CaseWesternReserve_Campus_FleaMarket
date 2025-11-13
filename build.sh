#!/bin/bash
set -e

# 安装 Flutter（如果还没有安装）
if ! command -v flutter &> /dev/null; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
  export PATH="$HOME/flutter/bin:$PATH"
fi

# 确保 Flutter 在 PATH 中
export PATH="$HOME/flutter/bin:$PATH"

# 检查 Flutter 是否可用
flutter --version

# 获取依赖
flutter pub get

# 构建 Web 版本
flutter build web --release

echo "Build completed successfully!"

