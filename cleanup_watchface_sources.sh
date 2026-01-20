#!/bin/bash

# 清理 SmartBracelet 项目中的 WatchFaceSDK 源代码引用
# 使其只使用 WatchFaceSDK.xcframework

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  清理 WatchFaceSDK 源代码引用${NC}"
echo -e "${BLUE}  改为使用 WatchFaceSDK.xcframework${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

PROJECT_FILE="SmartBracelet.xcodeproj/project.pbxproj"
BACKUP_FILE="SmartBracelet.xcodeproj/project.pbxproj.backup.$(date +%Y%m%d_%H%M%S)"

# 检查项目文件
if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}❌ 错误: 找不到项目文件 $PROJECT_FILE${NC}"
    exit 1
fi

# 备份项目文件
echo -e "${GREEN}💾 备份项目文件...${NC}"
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo -e "   备份到: $BACKUP_FILE"
echo ""

# 要移除的源文件 ID
echo -e "${GREEN}🔍 检测需要移除的 WatchFaceSDK 源文件...${NC}"

FILES_TO_REMOVE=(
    "9A18248A2F03B5B70010B5B3"  # WatchFaceManager.swift in Sources
    "9A18248B2F03B5B70010B5B3"  # WatchFaceTransferEngine.swift in Sources
    "9A18248F2F03B5B70010B5B3"  # WatchFaceInfo.swift in Sources
    "9A1824932F03B5B70010B5B3"  # WatchFaceSDK.swift in Sources
)

# 检查是否存在这些引用
echo -e "${YELLOW}检查当前状态:${NC}"
for file_id in "${FILES_TO_REMOVE[@]}"; do
    if grep -q "$file_id" "$PROJECT_FILE"; then
        echo -e "   ✅ 找到引用: $file_id"
    else
        echo -e "   ⚠️  未找到: $file_id"
    fi
done
echo ""

# 询问用户确认
echo -e "${YELLOW}⚠️  警告: 此操作将修改 Xcode 项目文件${NC}"
echo -e "${YELLOW}   以下源文件将从编译中移除:${NC}"
echo -e "   • WatchFaceManager.swift"
echo -e "   • WatchFaceTransferEngine.swift"
echo -e "   • WatchFaceInfo.swift"
echo -e "   • WatchFaceSDK.swift"
echo ""
echo -e "${YELLOW}   项目将改为使用 WatchFaceSDK.xcframework${NC}"
echo ""

read -p "是否继续? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ 操作已取消${NC}"
    rm "$BACKUP_FILE"
    exit 1
fi

echo ""
echo -e "${GREEN}🔧 开始清理...${NC}"

# 创建临时文件
TEMP_FILE=$(mktemp)

# 移除源文件编译引用
echo -e "${BLUE}步骤 1: 移除源文件编译引用...${NC}"

# 使用 sed 删除包含这些 ID 的行
for file_id in "${FILES_TO_REMOVE[@]}"; do
    grep -v "$file_id" "$PROJECT_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$PROJECT_FILE"
    echo -e "   ✅ 已移除: $file_id"
done

# 移除 WatchFaceSDK 源代码组引用
echo ""
echo -e "${BLUE}步骤 2: 移除源代码目录引用...${NC}"

# 这需要更复杂的处理,先标记需要手动处理
echo -e "${YELLOW}   ⚠️  注意: 源代码目录引用需要在 Xcode 中手动移除${NC}"
echo -e "${YELLOW}      请在 Xcode 中:${NC}"
echo -e "${YELLOW}      1. 找到项目导航器中的 'WatchFaceSDK' 文件夹${NC}"
echo -e "${YELLOW}      2. 右键点击 -> Remove Reference${NC}"
echo ""

# 验证 xcframework 引用
echo -e "${BLUE}步骤 3: 验证 xcframework 引用...${NC}"
if grep -q "WatchFaceSDK.xcframework in Frameworks" "$PROJECT_FILE"; then
    echo -e "   ✅ WatchFaceSDK.xcframework 已正确引用"
else
    echo -e "${RED}   ❌ 警告: 未找到 WatchFaceSDK.xcframework 引用${NC}"
fi
echo ""

# 完成
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ 清理完成!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}📋 后续步骤:${NC}"
echo -e "1. 在 Xcode 中打开项目"
echo -e "2. 在项目导航器中,右键点击 'WatchFaceSDK' 源代码文件夹"
echo -e "3. 选择 'Delete' -> 'Remove Reference'"
echo -e "4. 确认项目中只有 WatchFaceSDK.xcframework"
echo -e "5. Clean Build Folder (⌘⇧K)"
echo -e "6. 重新编译项目"
echo ""

echo -e "${GREEN}📍 备份文件位置:${NC}"
echo -e "   $BACKUP_FILE"
echo ""

echo -e "${YELLOW}💡 如果遇到问题,可以恢复备份:${NC}"
echo -e "   cp \"$BACKUP_FILE\" \"$PROJECT_FILE\""
echo ""
