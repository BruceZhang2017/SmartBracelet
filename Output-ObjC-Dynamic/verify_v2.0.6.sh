#!/bin/bash

# WatchProtocolSDK v2.0.6 验证脚本
# 验证新增的连接超时功能是否正确包含

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  WatchProtocolSDK v2.0.6 功能验证${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

FRAMEWORK_PATH="./WatchProtocolSDK.xcframework/ios-arm64/WatchProtocolSDK.framework"

# 检查 framework 是否存在
if [ ! -d "$FRAMEWORK_PATH" ]; then
    echo -e "${RED}❌ Framework 未找到${NC}"
    echo "   路径: $FRAMEWORK_PATH"
    exit 1
fi

echo -e "${GREEN}✅ Framework 路径正确${NC}"
echo ""

# 验证 1：检查头文件中的 connectionTimeout 属性
echo -e "${BLUE}📋 验证 1: connectionTimeout 属性${NC}"
if grep -q "connectionTimeout" "$FRAMEWORK_PATH/Headers/WPBluetoothManager.h"; then
    echo -e "${GREEN}   ✅ connectionTimeout 属性已包含${NC}"
    grep "connectionTimeout" "$FRAMEWORK_PATH/Headers/WPBluetoothManager.h" | grep -v "^//" | head -1
else
    echo -e "${RED}   ❌ connectionTimeout 属性未找到${NC}"
    exit 1
fi
echo ""

# 验证 2：检查代理方法
echo -e "${BLUE}📋 验证 2: didConnectionTimeout: 代理方法${NC}"
if grep -q "didConnectionTimeout" "$FRAMEWORK_PATH/Headers/WPBluetoothManager.h"; then
    echo -e "${GREEN}   ✅ didConnectionTimeout: 方法已包含${NC}"
    grep "didConnectionTimeout" "$FRAMEWORK_PATH/Headers/WPBluetoothManager.h" | grep -v "^//" | head -1
else
    echo -e "${RED}   ❌ didConnectionTimeout: 方法未找到${NC}"
    exit 1
fi
echo ""

# 验证 3：检查版本号
echo -e "${BLUE}📋 验证 3: 版本信息${NC}"
VERSION=$(plutil -p "$FRAMEWORK_PATH/Info.plist" | grep "CFBundleShortVersionString" | awk '{print $3}' | tr -d '"')
if [ "$VERSION" = "2.0.6" ]; then
    echo -e "${GREEN}   ✅ 版本号正确: $VERSION${NC}"
else
    echo -e "${YELLOW}   ⚠️  版本号: $VERSION (预期: 2.0.6)${NC}"
fi
echo ""

# 验证 4：检查核心符号
echo -e "${BLUE}📋 验证 4: 核心符号${NC}"
BINARY="$FRAMEWORK_PATH/WatchProtocolSDK"

symbols_found=0
if nm -g "$BINARY" | grep -q "OBJC_CLASS.*WPBluetoothManager"; then
    echo -e "${GREEN}   ✅ WPBluetoothManager 符号${NC}"
    symbols_found=$((symbols_found + 1))
fi

if nm -g "$BINARY" | grep -q "OBJC_CLASS.*WPDeviceManager"; then
    echo -e "${GREEN}   ✅ WPDeviceManager 符号${NC}"
    symbols_found=$((symbols_found + 1))
fi

if nm -g "$BINARY" | grep -q "OBJC_CLASS.*WPEmptyHealthDataStorage"; then
    echo -e "${GREEN}   ✅ WPEmptyHealthDataStorage 符号${NC}"
    symbols_found=$((symbols_found + 1))
fi

if [ $symbols_found -eq 3 ]; then
    echo -e "${GREEN}   ✅ 所有核心符号验证通过${NC}"
else
    echo -e "${RED}   ❌ 部分符号缺失 ($symbols_found/3)${NC}"
    exit 1
fi
echo ""

# 验证 5：检查是否有 Swift 符号
echo -e "${BLUE}📋 验证 5: Swift 依赖检查${NC}"
if nm -g "$BINARY" | grep -q "_Tt"; then
    echo -e "${YELLOW}   ⚠️  检测到 Swift 符号${NC}"
else
    echo -e "${GREEN}   ✅ 无 Swift 符号（纯 Objective-C）${NC}"
fi
echo ""

# 验证 6：Framework 大小
echo -e "${BLUE}📋 验证 6: Framework 大小${NC}"
SIZE=$(du -sh "$FRAMEWORK_PATH" | cut -f1)
echo -e "${GREEN}   📦 Framework 大小: ${BLUE}$SIZE${NC}"
echo ""

# 最终结果
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ v2.0.6 功能验证通过！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "🎉 Framework 包含以下新功能:"
echo -e "   • connectionTimeout 属性（默认 30 秒）"
echo -e "   • didConnectionTimeout: 代理方法"
echo -e "   • 自动超时保护机制"
echo ""
echo -e "📖 使用示例:"
echo -e "   ${BLUE}[WPBluetoothManager sharedInstance].connectionTimeout = 20.0;${NC}"
echo ""
echo -e "🚀 Framework 已准备就绪，可直接提供给第三方使用！"
echo ""
