# generate_filelist.py
import os
import argparse

def generate_file_list(repo_path, output_file="filelist.txt", exclude_dirs=None, exclude_files=None):
    """
    遍历指定仓库路径，生成包含所有文件相对路径的列表文件。

    Args:
        repo_path (str): 本地仓库的根目录路径。
        output_file (str): 输出的文件列表文件名 (例如 "filelist.txt")。
        exclude_dirs (list): 需要排除的目录名列表 (例如 [".git", ".vscode"])。
        exclude_files (list): 需要排除的文件名列表 (例如 ["generate_filelist.py", "README.md"])。
    """
    if exclude_dirs is None:
        exclude_dirs = [".git",".vscode"] # 默认排除 .git 目录
    if exclude_files is None:
        exclude_files = [os.path.basename(__file__), output_file] # 默认排除脚本自身和输出文件

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
                dirs[:] = [d for d in dirs if d not in exclude_dirs]

                # --- 处理文件 ---
                for filename in files:
                    # 排除指定文件
                    if filename in exclude_files:
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
    parser.add_argument("--exclude-dir", action="append", default=[".git",".vscode"], # 默认排除 .git
                        help="要排除的目录名 (可多次使用, 例如 --exclude-dir .vscode)。")
    parser.add_argument("--exclude-file", action="append", default=["README.md"],
                        help="要排除的文件名 (可多次使用, 例如 --exclude-file README.md)。")

    args = parser.parse_args()

    # 将脚本自身和输出文件名也加入排除列表，避免重复添加
    args.exclude_file.append(os.path.basename(__file__))
    args.exclude_file.append(args.output)
    # 去重
    args.exclude_file = list(set(args.exclude_file))

    generate_file_list(args.repo_path, args.output, args.exclude_dir, args.exclude_file)
    print("请检查filelist.txt是否符合要求")
