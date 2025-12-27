#!/usr/bin/env python3
"""
Fix WatchProtocolSDK Framework Search Paths and Linker Flags
"""

import re

project_file = "SmartBracelet.xcodeproj/project.pbxproj"

with open(project_file, 'r') as f:
    content = f.read()

# Fix FRAMEWORK_SEARCH_PATHS - remove /** suffixes
content = re.sub(
    r'"(\$\(BUILD_DIR\)/\$\(CONFIGURATION\)\$\(EFFECTIVE_PLATFORM_NAME\)/RealmSwift)/\*\*"',
    r'"\1"',
    content
)
content = re.sub(
    r'"(\$\(BUILD_DIR\)/\$\(CONFIGURATION\)\$\(EFFECTIVE_PLATFORM_NAME\)/Realm)/\*\*"',
    r'"\1"',
    content
)
content = re.sub(
    r'"(\$\(inherited\))/\*\*"',
    r'"\1"',
    content
)

# Fix HEADER_SEARCH_PATHS - remove /** suffixes
content = re.sub(
    r'"(\$\(BUILD_DIR\)/\$\(CONFIGURATION\)\$\(EFFECTIVE_PLATFORM_NAME\)/RealmSwift/RealmSwift\.framework/Headers)/\*\*"',
    r'"\1"',
    content
)
content = re.sub(
    r'"(\$\(BUILD_DIR\)/\$\(CONFIGURATION\)\$\(EFFECTIVE_PLATFORM_NAME\)/Realm/Realm\.framework/Headers)/\*\*"',
    r'"\1"',
    content
)

# Fix OTHER_LDFLAGS - remove incorrect escaping
content = re.sub(
    r'"\\\"-framework \\\\\\"RealmSwift\\\\\\"\\\""',
    '"-framework \\"RealmSwift\\""',
    content
)
content = re.sub(
    r'"\\\"-framework \\\\\\"Realm\\\\\\"\\\""',
    '"-framework \\"Realm\\""',
    content
)

with open(project_file, 'w') as f:
    f.write(content)

print("✅ Fixed Framework Search Paths and Linker Flags in project.pbxproj")
print("\nChanges made:")
print("1. Removed /** suffixes from FRAMEWORK_SEARCH_PATHS")
print("2. Removed /** suffixes from HEADER_SEARCH_PATHS")
print("3. Fixed quote escaping in OTHER_LDFLAGS")
print("\nYou should now be able to compile WatchProtocolSDK successfully.")
