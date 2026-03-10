#!/bin/bash

# 修复 WatchFaceSDK.swift 重复引用问题

set -e

PBXPROJ="/Users/bruce/Downloads/SmartBracelet/SmartBracelet.xcodeproj/project.pbxproj"
BACKUP="${PBXPROJ}.backup-$(date +%Y%m%d-%H%M%S)"

echo "🔧 修复 Xcode 项目中的重复文件引用..."
echo ""

# 备份
echo "📦 备份项目文件..."
cp "$PBXPROJ" "$BACKUP"
echo "   备份至: $BACKUP"
echo ""

# 显示重复的引用
echo "🔍 检测到重复的 WatchFaceSDK.swift 引用:"
grep -n "WatchFaceSDK.swift" "$PBXPROJ" | grep "9A18248"
echo ""

# 删除第二个重复的引用 (9A1824862F03B5B70010B5B3)
echo "🗑️  删除重复引用..."

# 删除 BuildFile 中的重复项
sed -i '' '/9A1824942F03B5B70010B5B3 \/\* WatchFaceSDK.swift in Sources \*\//d' "$PBXPROJ"

# 删除 FileReference 中的重复项
sed -i '' '/9A1824862F03B5B70010B5B3 \/\* WatchFaceSDK.swift \*\//d' "$PBXPROJ"

# 删除可能在 group 中的重复引用
sed -i '' '/9A1824862F03B5B70010B5B3 \/\* WatchFaceSDK.swift \*\//d' "$PBXPROJ"

# 删除可能在 Sources 阶段的重复引用
sed -i '' '/9A1824942F03B5B70010B5B3 \/\* WatchFaceSDK.swift in Sources \*\//d' "$PBXPROJ"

echo "✅ 修复完成！"
echo ""
echo "📝 修改内容:"
echo "   - 删除了重复的 WatchFaceSDK.swift 引用 (9A18248862F03B5B70010B5B3)"
echo "   - 保留了原始引用 (9A1824822F03B5B70010B5B3)"
echo ""
echo "💡 如果需要恢复，请使用备份文件:"
echo "   cp $BACKUP $PBXPROJ"
echo ""
