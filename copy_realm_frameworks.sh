#!/bin/bash

# Find the newest DerivedData directory with RealmSwift
SOURCE_DIR=$(ls -t ~/Library/Developer/Xcode/DerivedData/SmartBracelet-*/Build/Products/Debug-iphoneos/RealmSwift/RealmSwift.framework 2>/dev/null | head -1 | xargs dirname | xargs dirname)

if [ -z "$SOURCE_DIR" ]; then
    echo "❌ Could not find RealmSwift framework in DerivedData"
    exit 1
fi

echo "📦 Found RealmSwift frameworks at: $SOURCE_DIR"

# Get the current DerivedData directory
CURRENT_DIR=$(find ~/Library/Developer/Xcode/DerivedData -name "SmartBracelet-*" -type d -mtime -1m | head -1)
TARGET_DIR="$CURRENT_DIR/Build/Products/Debug-iphoneos"

echo "🎯 Target directory: $TARGET_DIR"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Copy RealmSwift and Realm frameworks
if [ -d "$SOURCE_DIR/RealmSwift" ]; then
    cp -R "$SOURCE_DIR/RealmSwift" "$TARGET_DIR/"
    echo "✅ Copied RealmSwift framework"
fi

if [ -d "$SOURCE_DIR/Realm" ]; then
    cp -R "$SOURCE_DIR/Realm" "$TARGET_DIR/"
    echo "✅ Copied Realm framework"
fi

echo "🎉 Done!"
