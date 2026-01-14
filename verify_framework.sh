#!/bin/bash

echo "🔍 验证 WatchProtocolSDK.xcframework..."

# 检查1: Headers 目录结构
echo ""
echo "📋 检查1: 头文件结构"
HEADER_COUNT=$(ls Output-ObjC/WatchProtocolSDK.xcframework/ios-arm64/Headers/*.h 2>/dev/null | wc -l | tr -d ' ')
if [ $HEADER_COUNT -eq 7 ]; then
    echo "✅ 找到 7 个头文件"
else
    echo "❌ 头文件数量不正确: $HEADER_COUNT (应该是7个)"
    exit 1
fi

# 检查2: WPHealthDataModels.h 存在
echo ""
echo "📋 检查2: WPHealthDataModels.h 是否存在"
if [ -f "Output-ObjC/WatchProtocolSDK.xcframework/ios-arm64/Headers/WPHealthDataModels.h" ]; then
    echo "✅ WPHealthDataModels.h 存在"
else
    echo "❌ WPHealthDataModels.h 不存在!"
    exit 1
fi

# 检查3: 没有子目录
echo ""
echo "📋 检查3: 检查是否有子目录"
SUBDIR_COUNT=$(find Output-ObjC/WatchProtocolSDK.xcframework/ios-arm64/Headers -mindepth 1 -type d | wc -l | tr -d ' ')
if [ $SUBDIR_COUNT -eq 0 ]; then
    echo "✅ Headers 目录是扁平化的,没有子目录"
else
    echo "❌ 发现 $SUBDIR_COUNT 个子目录,Headers应该是扁平化的"
    find Output-ObjC/WatchProtocolSDK.xcframework/ios-arm64/Headers -mindepth 1 -type d
    exit 1
fi

# 检查4: 没有.m文件
echo ""
echo "📋 检查4: 检查是否有.m文件"
M_FILE_COUNT=$(find Output-ObjC/WatchProtocolSDK.xcframework -name "*.m" | wc -l | tr -d ' ')
if [ $M_FILE_COUNT -eq 0 ]; then
    echo "✅ 没有.m实现文件"
else
    echo "❌ 发现 $M_FILE_COUNT 个.m文件,不应该在 Headers 中"
    find Output-ObjC/WatchProtocolSDK.xcframework -name "*.m"
    exit 1
fi

# 检查5: module.modulemap 存在
echo ""
echo "📋 检查5: module.modulemap 是否存在"
if [ -f "Output-ObjC/WatchProtocolSDK.xcframework/ios-arm64/Headers/module.modulemap" ]; then
    echo "✅ module.modulemap 存在"
else
    echo "❌ module.modulemap 不存在"
    exit 1
fi

# 检查6: 主头文件导入正确
echo ""
echo "📋 检查6: 验证主头文件导入"
if grep -q "WPHealthDataModels.h" "Output-ObjC/WatchProtocolSDK.xcframework/ios-arm64/Headers/WatchProtocolSDK.h"; then
    echo "✅ 主头文件包含 WPHealthDataModels.h 导入"
else
    echo "❌ 主头文件缺少 WPHealthDataModels.h 导入"
    exit 1
fi

# 检查7: 模拟器版本一致性
echo ""
echo "📋 检查7: 验证模拟器版本"
SIM_HEADER_COUNT=$(ls Output-ObjC/WatchProtocolSDK.xcframework/ios-arm64_x86_64-simulator/Headers/*.h 2>/dev/null | wc -l | tr -d ' ')
if [ $SIM_HEADER_COUNT -eq 7 ]; then
    echo "✅ 模拟器版本头文件数量正确"
else
    echo "❌ 模拟器版本头文件数量不正确: $SIM_HEADER_COUNT"
    exit 1
fi

echo ""
echo "=========================================="
echo "🎉 所有检查通过! Framework 结构正确!"
echo "=========================================="
echo ""
echo "📋 文件列表:"
ls -lh Output-ObjC/WatchProtocolSDK.xcframework/ios-arm64/Headers/
echo ""
echo "✅ 第三方应用现在可以正常使用:"
echo "   #import <WatchProtocolSDK/WatchProtocolSDK.h>"
echo "   #import <WatchProtocolSDK/WPHealthDataModels.h>"
echo ""
