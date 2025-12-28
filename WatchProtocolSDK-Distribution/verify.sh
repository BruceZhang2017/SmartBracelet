#!/bin/bash

echo "🔍 WatchProtocolSDK Verification Script"
echo "========================================"
echo ""

# Check Debug XCFramework
echo "📦 Checking Debug XCFramework..."
if [ -d "Debug/WatchProtocolSDK.xcframework" ]; then
    echo "✅ Debug XCFramework exists"
    
    # Check device binary
    DEBUG_DEVICE="Debug/WatchProtocolSDK.xcframework/ios-arm64/WatchProtocolSDK.framework/WatchProtocolSDK"
    if [ -f "$DEBUG_DEVICE" ]; then
        SIZE=$(ls -lh "$DEBUG_DEVICE" | awk '{print $5}')
        ARCH=$(file "$DEBUG_DEVICE" | grep -o "arm64")
        echo "   ├─ Device binary: $SIZE ($ARCH)"
    else
        echo "   ├─ ❌ Device binary missing"
    fi
    
    # Check simulator binary
    DEBUG_SIM="Debug/WatchProtocolSDK.xcframework/ios-arm64_x86_64-simulator/WatchProtocolSDK.framework/WatchProtocolSDK"
    if [ -f "$DEBUG_SIM" ]; then
        SIZE=$(ls -lh "$DEBUG_SIM" | awk '{print $5}')
        echo "   └─ Simulator binary: $SIZE"
    else
        echo "   └─ ❌ Simulator binary missing"
    fi
else
    echo "❌ Debug XCFramework not found"
fi

echo ""

# Check Release XCFramework
echo "📦 Checking Release XCFramework..."
if [ -d "Release/WatchProtocolSDK.xcframework" ]; then
    echo "✅ Release XCFramework exists"
    
    # Check device binary
    RELEASE_DEVICE="Release/WatchProtocolSDK.xcframework/ios-arm64/WatchProtocolSDK.framework/WatchProtocolSDK"
    if [ -f "$RELEASE_DEVICE" ]; then
        SIZE=$(ls -lh "$RELEASE_DEVICE" | awk '{print $5}')
        ARCH=$(file "$RELEASE_DEVICE" | grep -o "arm64")
        echo "   ├─ Device binary: $SIZE ($ARCH)"
    else
        echo "   ├─ ❌ Device binary missing"
    fi
    
    # Check simulator binary
    RELEASE_SIM="Release/WatchProtocolSDK.xcframework/ios-arm64_x86_64-simulator/WatchProtocolSDK.framework/WatchProtocolSDK"
    if [ -f "$RELEASE_SIM" ]; then
        SIZE=$(ls -lh "$RELEASE_SIM" | awk '{print $5}')
        echo "   └─ Simulator binary: $SIZE"
    else
        echo "   └─ ❌ Simulator binary missing"
    fi
else
    echo "❌ Release XCFramework not found"
fi

echo ""

# Check documentation
echo "📚 Checking Documentation..."
if [ -f "README.md" ]; then
    echo "✅ README.md"
fi
if [ -f "接入说明文档.md" ]; then
    echo "✅ 接入说明文档.md (Chinese guide)"
fi
if [ -f "Integration Guide.md" ]; then
    echo "✅ Integration Guide.md (English guide)"
fi

echo ""
echo "✨ Verification complete!"
