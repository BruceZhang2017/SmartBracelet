#!/bin/bash

# 验证 SmartBracelet 项目迁移状态
# 检查是否正确使用 WatchFaceSDK.xcframework

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  SmartBracelet 迁移验证${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

PROJECT_FILE="SmartBracelet.xcodeproj/project.pbxproj"
XCFRAMEWORK="Output2/WatchFaceSDK.xcframework"

# 检查项目文件
if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}❌ 错误: 找不到项目文件${NC}"
    exit 1
fi

echo -e "${GREEN}🔍 检查项目配置...${NC}"
echo ""

# 1. 检查源文件引用
echo -e "${YELLOW}1. 检查 WatchFaceSDK 源文件引用...${NC}"
SOURCE_REFS=$(grep "WatchFace.*\.swift in Sources" "$PROJECT_FILE" | wc -l | tr -d ' ')
if [ "$SOURCE_REFS" -eq "0" ]; then
    echo -e "   ${GREEN}✅ 无源文件编译引用${NC}"
else
    echo -e "   ${RED}❌ 发现 $SOURCE_REFS 个源文件引用${NC}"
    echo -e "   ${RED}   需要运行: python3 remove_watchface_sources.py${NC}"
fi

# 2. 检查 xcframework 引用
echo ""
echo -e "${YELLOW}2. 检查 WatchFaceSDK.xcframework 引用...${NC}"
FRAMEWORK_REFS=$(grep "WatchFaceSDK.xcframework in Frameworks" "$PROJECT_FILE" | wc -l | tr -d ' ')
EMBED_REFS=$(grep "WatchFaceSDK.xcframework in Embed Frameworks" "$PROJECT_FILE" | wc -l | tr -d ' ')

if [ "$FRAMEWORK_REFS" -gt "0" ]; then
    echo -e "   ${GREEN}✅ Framework 已链接${NC}"
else
    echo -e "   ${RED}❌ Framework 未链接${NC}"
fi

if [ "$EMBED_REFS" -gt "0" ]; then
    echo -e "   ${GREEN}✅ Framework 已嵌入${NC}"
else
    echo -e "   ${RED}❌ Framework 未嵌入${NC}"
fi

# 3. 检查 xcframework 文件
echo ""
echo -e "${YELLOW}3. 检查 xcframework 文件...${NC}"
if [ -d "$XCFRAMEWORK" ]; then
    echo -e "   ${GREEN}✅ WatchFaceSDK.xcframework 存在${NC}"

    # 检查版本
    if [ -f "Output2/VERSION.txt" ]; then
        VERSION=$(grep "^Version:" Output2/VERSION.txt | cut -d' ' -f2)
        echo -e "   ${GREEN}✅ 版本: $VERSION${NC}"

        if [ "$VERSION" = "1.0.3" ]; then
            echo -e "   ${GREEN}✅ 使用修复版本 (v1.0.3)${NC}"
        else
            echo -e "   ${YELLOW}⚠️  版本: $VERSION (建议升级到 v1.0.3)${NC}"
        fi
    fi
else
    echo -e "   ${RED}❌ xcframework 不存在${NC}"
fi

# 4. 检查备份
echo ""
echo -e "${YELLOW}4. 检查项目备份...${NC}"
BACKUPS=$(ls SmartBracelet.xcodeproj/project.pbxproj.backup.* 2>/dev/null | wc -l | tr -d ' ')
if [ "$BACKUPS" -gt "0" ]; then
    echo -e "   ${GREEN}✅ 找到 $BACKUPS 个备份文件${NC}"
    LATEST_BACKUP=$(ls -t SmartBracelet.xcodeproj/project.pbxproj.backup.* 2>/dev/null | head -1)
    echo -e "   ${GREEN}   最新备份: $(basename "$LATEST_BACKUP")${NC}"
else
    echo -e "   ${YELLOW}⚠️  无备份文件${NC}"
fi

# 5. 总结
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}📊 验证总结${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

ISSUES=0

if [ "$SOURCE_REFS" -ne "0" ]; then
    echo -e "${RED}❌ 源文件引用未清理${NC}"
    ((ISSUES++))
fi

if [ "$FRAMEWORK_REFS" -eq "0" ] || [ "$EMBED_REFS" -eq "0" ]; then
    echo -e "${RED}❌ xcframework 未正确配置${NC}"
    ((ISSUES++))
fi

if [ ! -d "$XCFRAMEWORK" ]; then
    echo -e "${RED}❌ xcframework 文件缺失${NC}"
    ((ISSUES++))
fi

if [ "$ISSUES" -eq "0" ]; then
    echo -e "${GREEN}✅ 迁移验证通过!${NC}"
    echo ""
    echo -e "${YELLOW}📋 后续步骤:${NC}"
    echo -e "1. 在 Xcode 中删除 WatchFaceSDK 源代码文件夹引用"
    echo -e "2. Clean Build Folder (⌘⇧K)"
    echo -e "3. 重新编译项目"
    echo ""
else
    echo -e "${RED}⚠️  发现 $ISSUES 个问题${NC}"
    echo ""
    echo -e "${YELLOW}建议操作:${NC}"
    if [ "$SOURCE_REFS" -ne "0" ]; then
        echo -e "• 运行: python3 remove_watchface_sources.py"
    fi
    if [ "$FRAMEWORK_REFS" -eq "0" ] || [ "$EMBED_REFS" -eq "0" ]; then
        echo -e "• 在 Xcode 中添加 WatchFaceSDK.xcframework"
    fi
    if [ ! -d "$XCFRAMEWORK" ]; then
        echo -e "• 重新编译: ./rebuild_watchface_sdk_simple.sh"
    fi
    echo ""
fi
