# generate_filelist.py
import os
import argparse
import fnmatch

def parse_ignore_file(ignore_file_path):
    """
    解析.ignore文件，获取需要排除的文件和目录规则

    Args:
        ignore_file_path (str): .ignore文件的路径

    Returns:
        tuple: (exclude_dirs, exclude_files) 两个列表，分别包含排除的目录和文件规则
    """
    if not os.path.exists(ignore_file_path):
        print(f"警告：找不到指定的.ignore文件 '{ignore_file_path}'，将使用默认排除规则")
        return [], []

    exclude_dirs = []
    exclude_files = []
    
    try:
        with open(ignore_file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                # 跳过空行和注释行
                if not line or line.startswith('#'):
                    continue
                
                # 如果规则以/结尾，视为目录
                if line.endswith('/'):
                    exclude_dirs.append(line[:-1])
                else:
                    exclude_files.append(line)
                    
        return exclude_dirs, exclude_files
    except Exception as e:
        print(f"解析.ignore文件时发生错误: {e}")
        return [], []

def should_exclude(path, exclude_dirs, exclude_files):
    """
    检查给定路径是否应该被排除

    Args:
        path (str): 要检查的路径
        exclude_dirs (list): 排除的目录规则列表
        exclude_files (list): 排除的文件规则列表

    Returns:
        bool: 如果应该排除返回True，否则返回False
    """
    # 检查是否为目录
    if os.path.isdir(path):
        for pattern in exclude_dirs:
            if fnmatch.fnmatch(os.path.basename(path), pattern):
                return True
    # 检查是否为文件
    else:
        for pattern in exclude_files:
            if fnmatch.fnmatch(os.path.basename(path), pattern):
                return True
    return False

def generate_file_list(repo_path, output_file="filelist.txt", exclude_dirs=None, exclude_files=None, ignore_file=None):
    """
    遍历指定仓库路径，生成包含所有文件相对路径的列表文件。

    Args:
        repo_path (str): 本地仓库的根目录路径。
        output_file (str): 输出的文件列表文件名 (例如 "filelist.txt")。
        exclude_dirs (list): 需要排除的目录名列表 (例如 [".git", ".vscode"])。
        exclude_files (list): 需要排除的文件名列表 (例如 ["generate_filelist.py", "README.md"])。
        ignore_file (str): .ignore文件的路径，如果提供，将从中读取排除规则。
    """
    if exclude_dirs is None:
        exclude_dirs = [".git",".vscode"] # 默认排除 .git 目录
    if exclude_files is None:
        exclude_files = [os.path.basename(__file__), output_file] # 默认排除脚本自身和输出文件

    # 如果提供了.ignore文件，解析并添加规则
    if ignore_file:
        ignore_file_path = os.path.join(repo_path, ignore_file) if not os.path.isabs(ignore_file) else ignore_file
        ignore_dirs, ignore_files = parse_ignore_file(ignore_file_path)
        exclude_dirs.extend(ignore_dirs)
        exclude_files.extend(ignore_files)
        # 去重
        exclude_dirs = list(set(exclude_dirs))
        exclude_files = list(set(exclude_files))

    count = 0
    output_path = os.path.join(repo_path, output_file) # 输出文件放在仓库根目录

    try:
        with open(output_path, "w", encoding="utf-8") as f:
            print(f"扫描目录: {repo_path}")
            print(f"将把文件列表写入: {output_path}")
            print(f"排除目录: {exclude_dirs}")
            print(f"排除文件: {exclude_files}")

            for root, dirs, files in os.walk(repo_path, topdown=True):
                # --- 排除目录 ---
                # 通过修改 dirs 列表来阻止 os.walk 进入这些目录
                dirs[:] = [d for d in dirs if not any(fnmatch.fnmatch(d, pattern) for pattern in exclude_dirs)]

                # --- 处理文件 ---
                for filename in files:
                    # 排除指定文件
                    if any(fnmatch.fnmatch(filename, pattern) for pattern in exclude_files):
                        continue

                    full_path = os.path.join(root, filename)
                    relative_path = os.path.relpath(full_path, repo_path)

                    # 将 Windows 风格的路径分隔符 \ 替换为 /，以保证 URL 和 CC 兼容性
                    relative_path = relative_path.replace("\\", "/")

                    # 排除输出文件自身（以防万一在循环中遇到）
                    if relative_path == output_file:
                        continue

                    print(f"  找到: {relative_path}")
                    f.write(relative_path + "\n")
                    count += 1

        print(f"\n完成！共找到并记录 {count} 个文件到 {output_path}")

    except FileNotFoundError:
        print(f"错误：找不到指定的仓库路径 '{repo_path}'")
    except Exception as e:
        print(f"生成文件列表时发生错误: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="生成 GitHub 仓库的文件列表供 ComputerCraft 下载器使用。")
    parser.add_argument("repo_path", help="本地 GitHub 仓库的根目录路径。")
    parser.add_argument("-o", "--output", default="filelist.txt",
                        help="输出的文件列表文件名 (默认: filelist.txt)。")
    parser.add_argument("--exclude-dir", action="append", default=[".git",".vscode"], 
                        help="要排除的目录名 (可多次使用, 例如 --exclude-dir .vscode)。")
    parser.add_argument("--exclude-file", action="append", default=["README.md"],
                        help="要排除的文件名 (可多次使用, 例如 --exclude-file README.md)。")
    parser.add_argument("--ignore-file", default=None,
                        help="指定.ignore文件路径，用于读取排除规则 (默认: None)。")

    args = parser.parse_args()

    # 将输出文件名也加入排除列表，避免重复添加
    args.exclude_file.append(args.output)
    # 去重
    args.exclude_file = list(set(args.exclude_file))

    generate_file_list(args.repo_path, args.output, args.exclude_dir, args.exclude_file, args.ignore_file)
    print("请检查filelist.txt是否符合要求")
