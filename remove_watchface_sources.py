#!/usr/bin/env python3
"""
移除 SmartBracelet 项目中的 WatchFaceSDK 源文件引用
使其只使用 WatchFaceSDK.xcframework
"""

import sys
import shutil
from datetime import datetime
from pathlib import Path

# 颜色输出
class Colors:
    BLUE = '\033[0;34m'
    GREEN = '\033[0;32m'
    RED = '\033[0;31m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'

def print_colored(text, color):
    print(f"{color}{text}{Colors.NC}")

def main():
    print_colored("========================================", Colors.BLUE)
    print_colored("  移除 WatchFaceSDK 源代码引用", Colors.BLUE)
    print_colored("  改为使用 WatchFaceSDK.xcframework", Colors.BLUE)
    print_colored("========================================", Colors.BLUE)
    print()

    project_file = Path("SmartBracelet.xcodeproj/project.pbxproj")

    # 检查项目文件
    if not project_file.exists():
        print_colored(f"❌ 错误: 找不到项目文件 {project_file}", Colors.RED)
        sys.exit(1)

    # 备份
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = project_file.parent / f"project.pbxproj.backup.{timestamp}"

    print_colored("💾 备份项目文件...", Colors.GREEN)
    shutil.copy2(project_file, backup_file)
    print(f"   备份到: {backup_file}")
    print()

    # 读取项目文件
    with open(project_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # 要移除的行的 ID 列表
    ids_to_remove = [
        "9A18248A2F03B5B70010B5B3",  # WatchFaceManager.swift in Sources
        "9A18248B2F03B5B70010B5B3",  # WatchFaceTransferEngine.swift in Sources
        "9A18248F2F03B5B70010B5B3",  # WatchFaceInfo.swift in Sources
        "9A1824932F03B5B70010B5B3",  # WatchFaceSDK.swift in Sources
    ]

    print_colored("🔍 检测需要移除的引用...", Colors.GREEN)
    removed_count = 0

    lines = content.split('\n')
    new_lines = []

    for line in lines:
        should_remove = False
        for id_to_remove in ids_to_remove:
            if id_to_remove in line:
                should_remove = True
                removed_count += 1
                print(f"   ✅ 移除: {line.strip()[:80]}...")
                break

        if not should_remove:
            new_lines.append(line)

    print()

    if removed_count == 0:
        print_colored("✅ 没有找到需要移除的引用", Colors.GREEN)
        print_colored("   项目可能已经清理完毕", Colors.YELLOW)
    else:
        # 写回文件
        with open(project_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_lines))

        print_colored(f"✅ 成功移除 {removed_count} 个引用", Colors.GREEN)

    print()
    print_colored("========================================", Colors.BLUE)
    print_colored("✅ 清理完成!", Colors.GREEN)
    print_colored("========================================", Colors.BLUE)
    print()

    print_colored("📋 后续步骤:", Colors.YELLOW)
    print("1. 在 Xcode 中打开项目")
    print("2. 在项目导航器中删除 'WatchFaceSDK' 源代码文件夹引用")
    print("   (右键 -> Delete -> Remove Reference)")
    print("3. Clean Build Folder (⌘⇧K)")
    print("4. 重新编译项目")
    print()

    print_colored("📍 备份文件位置:", Colors.GREEN)
    print(f"   {backup_file}")
    print()

    print_colored("💡 如果遇到问题,可以恢复备份:", Colors.YELLOW)
    print(f"   cp {backup_file} {project_file}")
    print()

if __name__ == "__main__":
    main()
