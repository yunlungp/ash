import re

# 读取 pubspec.yaml
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

# 匹配 version: 1.0.0+1 格式
match = re.search(r'version:\s*([^\+\r\n]+)\+(\d+)', content)
if match:
    version_name = match.group(1).strip()
    old_build = int(match.group(2))
    new_build = old_build + 1

    new_version_line = f'version: {version_name}+{new_build}'
    content = content.replace(match.group(0), new_version_line)

    # 写回 pubspec.yaml
    with open('pubspec.yaml', 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Successfully updated version to {version_name}+{new_build}")
else:
    print("Version pattern not found in pubspec.yaml")
