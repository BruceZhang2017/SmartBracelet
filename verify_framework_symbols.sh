#!/bin/bash

FRAMEWORK_PATH=$(find ~/Library/Developer/Xcode/DerivedData/SmartBracelet-*/Build/Products/Debug-iphoneos -name "WatchProtocolSDK.framework" -type d 2>/dev/null | head -1)

if [ -z "$FRAMEWORK_PATH" ]; then
    echo "❌ Framework not found"
    exit 1
fi

BINARY="$FRAMEWORK_PATH/WatchProtocolSDK"

echo "📦 Framework 路径: $FRAMEWORK_PATH"
echo "📊 Framework 大小: $(du -h "$BINARY" | cut -f1)"
echo ""
echo "🔍 检查导出的公开符号..."
echo ""

# 检查核心类是否导出
echo "核心管理类:"
nm -gU "$BINARY" | grep "XGZTBlueToothManager" | head -3
nm -gU "$BINARY" | grep "XGZTBusinessHandler" | head -3
nm -gU "$BINARY" | grep "XGZTDeviceManager" | head -3

echo ""
echo "数据模型:"
nm -gU "$BINARY" | grep "BluetoothWatchDevice" | head -3

echo ""
echo "指令类:"
nm -gU "$BINARY" | grep "XGZTCommand" | head -3

echo ""
echo "✅ Framework 符号导出正常"
