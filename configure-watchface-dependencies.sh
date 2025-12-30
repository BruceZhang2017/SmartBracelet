#!/bin/bash

# 自动配置 WatchFaceSDK 依赖

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  WatchFaceSDK 依赖配置工具${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 检查依赖
echo -e "${GREEN}🔍 检查依赖 frameworks...${NC}"

WATCH_PROTOCOL_SDK="build/WatchProtocolSDK-Release/WatchProtocolSDK.xcframework"
ABPAR_TOOL="ABParTool.xcframework"

if [ ! -d "$WATCH_PROTOCOL_SDK" ]; then
    echo -e "${YELLOW}⚠️  WatchProtocolSDK.xcframework 不存在${NC}"
    echo -e "${YELLOW}   正在编译 WatchProtocolSDK...${NC}"
    ./build_sdk.sh
fi

if [ ! -d "$ABPAR_TOOL" ]; then
    echo -e "${RED}❌ ABParTool.xcframework 不存在: $ABPAR_TOOL${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 所有依赖 frameworks 已准备就绪${NC}"
echo ""

# 打开 Xcode 并显示配置步骤
echo -e "${BLUE}📝 接下来需要在 Xcode 中手动配置：${NC}"
echo ""
echo -e "1. 正在打开 Xcode..."
open SmartBracelet.xcworkspace

echo ""
echo -e "2. ${YELLOW}请按以下步骤操作:${NC}"
echo ""
echo -e "   ${GREEN}步骤 1:${NC} 选择 SmartBracelet 项目 → TARGETS → WatchFaceSDK"
echo ""
echo -e "   ${GREEN}步骤 2:${NC} General 标签 → Frameworks, Libraries, and Embedded Content"
echo -e "           点击 + 号，添加:"
echo -e "           • WatchProtocolSDK.framework（从项目中选择）"
echo -e "           • ABParTool.xcframework（点击 Add Other → Add Files）"
echo -e "             路径: $(pwd)/ABParTool.xcframework"
echo ""
echo -e "   ${GREEN}步骤 3:${NC} 两个 frameworks 都设置为 ${YELLOW}Embed & Sign${NC}"
echo ""
echo -e "   ${GREEN}步骤 4:${NC} Build Settings → 搜索 \"Build Libraries for Distribution\""
echo -e "           设置为 ${YELLOW}YES${NC}"
echo ""
echo -e "   ${GREEN}步骤 5:${NC} Build Phases → Dependencies"
echo -e "           点击 + 号，添加 ${YELLOW}WatchProtocolSDK${NC} target"
echo ""
echo -e "3. ${GREEN}配置完成后${NC}，运行编译脚本:"
echo -e "   ${BLUE}./build_watchface_sdk.sh${NC}"
echo ""
echo -e "${BLUE}================================${NC}"
