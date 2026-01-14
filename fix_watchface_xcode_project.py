#!/usr/bin/env python3
"""
修复 WatchFaceSDK_ObjC Xcode 项目
自动添加源文件到编译目标
"""

import os
import glob
import hashlib

def generate_uuid():
    """生成唯一的 24 字符 ID"""
    import uuid
    import random
    base = str(uuid.uuid4()).replace('-', '')[:24].upper()
    return base.ljust(24, str(random.randint(0, 9)))

def main():
    # 项目路径
    project_root = os.path.dirname(os.path.abspath(__file__))
    xcode_project_dir = os.path.join(project_root, "build/WatchFaceObjC-Build")
    sources_dir = os.path.join(xcode_project_dir, "WatchFaceSDK_ObjC")
    pbxproj_file = os.path.join(xcode_project_dir, "WatchFaceSDK_ObjC.xcodeproj/project.pbxproj")

    if not os.path.exists(pbxproj_file):
        print(f"❌ 项目文件不存在: {pbxproj_file}")
        return 1

    print("🔍 收集源文件...")

    # 收集所有需要编译的文件
    objc_m_files = []
    swift_files = []

    # ObjC .m 文件 (排除 Examples)
    for m_file in glob.glob(os.path.join(sources_dir, "**/*.m"), recursive=True):
        if "/Examples/" not in m_file and "/WatchFaceSDK/" not in m_file:
            rel_path = os.path.relpath(m_file, xcode_project_dir)
            objc_m_files.append(rel_path)
            print(f"  ✓ {rel_path}")

    # Swift 文件 (包括桥接层和 WatchFaceSDK)
    for swift_file in glob.glob(os.path.join(sources_dir, "**/*.swift"), recursive=True):
        if "/Examples/" not in swift_file:
            rel_path = os.path.relpath(swift_file, xcode_project_dir)
            swift_files.append(rel_path)
            print(f"  ✓ {rel_path}")

    total_files = len(objc_m_files) + len(swift_files)
    print(f"\n📊 找到 {total_files} 个源文件 ({len(objc_m_files)} ObjC + {len(swift_files)} Swift)")

    if total_files == 0:
        print("❌ 没有找到源文件!")
        return 1

    print("\n🔨 生成 Xcode 项目配置...")

    # 生成文件引用
    file_refs = []
    build_files = []

    for file_path in objc_m_files + swift_files:
        file_uuid = hashlib.md5(file_path.encode()).hexdigest()[:24].upper()
        build_uuid = hashlib.md5((file_path + "_build").encode()).hexdigest()[:24].upper()

        file_name = os.path.basename(file_path)
        file_type = "sourcecode.swift" if file_path.endswith(".swift") else "sourcecode.c.objc"

        file_refs.append(f'\t\t{file_uuid} /* {file_name} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = {file_type}; path = {file_path}; sourceTree = "<group>"; }};')
        build_files.append(f'\t\t\t\t{build_uuid} /* {file_name} in Sources */,')
        build_files.append(f'\t\t{build_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {file_name} */; }};')

    print(f"  ✓ 生成了 {len(file_refs)} 个文件引用")
    print(f"  ✓ 生成了 {len(build_files)} 个构建文件引用")

    # 创建 Sources 编译阶段
    sources_phase_uuid = "A1100000000000000000000A"
    sources_phase = f"""		{sources_phase_uuid} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join([bf for bf in build_files if " in Sources */" in bf])}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};"""

    # 读取原始项目文件
    with open(pbxproj_file, 'r') as f:
        content = f.read()

    # 插入文件引用
    refs_section = '\n'.join(file_refs)
    builds_section = '\n'.join([bf for bf in build_files if " in Sources */ = {" in bf])

    # 在 objects 开始处插入
    content = content.replace(
        '\tobjects = {',
        f'\tobjects = {{\n{refs_section}\n{builds_section}\n{sources_phase}'
    )

    # 修改 buildPhases,添加 Sources 阶段
    content = content.replace(
        '\t\t\tbuildPhases = (\n\t\t\t\tA2000000000000000000000A /* Frameworks */,',
        f'\t\t\tbuildPhases = (\n\t\t\t\t{sources_phase_uuid} /* Sources */,\n\t\t\t\tA2000000000000000000000A /* Frameworks */,'
    )

    # 写回文件
    backup_file = pbxproj_file + ".backup"
    os.rename(pbxproj_file, backup_file)

    with open(pbxproj_file, 'w') as f:
        f.write(content)

    print(f"\n✅ 项目文件已更新!")
    print(f"   备份: {backup_file}")
    print(f"\n🚀 下一步:")
    print(f"   cd {xcode_project_dir}")
    print(f"   xcodebuild -project WatchFaceSDK_ObjC.xcodeproj -scheme WatchFaceSDK_ObjC -configuration Release build")
    print()

    return 0

if __name__ == "__main__":
    exit(main())
