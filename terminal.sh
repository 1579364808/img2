#!/usr/bin/env bash
# terminal.sh — 图床仓库管理工具
#
# 用途说明 (What this script does):
#   该脚本是本图床仓库（img2）的终端管理工具。
#   本仓库用于配合 PicGo 存储截图/图片文件，
#   terminal.sh 提供以下功能：
#
#   1. 统计仓库中的图片总数及总占用空间
#   2. 列出最近上传的图片（默认 10 张）
#   3. 按日期过滤查找图片
#   4. 显示帮助信息
#
# 用法 (Usage):
#   ./terminal.sh             — 显示图片统计摘要
#   ./terminal.sh list [N]    — 列出最近 N 张图片（默认 10）
#   ./terminal.sh find <日期> — 按日期前缀查找图片，例如: ./terminal.sh find 20240407
#   ./terminal.sh help        — 显示此帮助信息

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_TYPES=( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.webp" )

show_summary() {
    local total size_kb size_human
    total=$(find "$REPO_DIR" -maxdepth 1 -type f \( "${IMAGE_TYPES[@]}" \) | wc -l)
    size_kb=$(find "$REPO_DIR" -maxdepth 1 -type f \( "${IMAGE_TYPES[@]}" \) -exec du -k {} + 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    if [ "$size_kb" -ge 1048576 ]; then
        size_human="$(awk "BEGIN {printf \"%.1fG\", $size_kb/1048576}")"
    elif [ "$size_kb" -ge 1024 ]; then
        size_human="$(awk "BEGIN {printf \"%.1fM\", $size_kb/1024}")"
    else
        size_human="${size_kb}K"
    fi
    echo "=== img2 图床仓库统计 ==="
    echo "图片总数: $total"
    echo "占用空间: $size_human"
    echo "仓库路径: $REPO_DIR"
    echo ""
    echo "最近上传的 5 张图片:"
    find "$REPO_DIR" -maxdepth 1 -type f \( "${IMAGE_TYPES[@]}" \) -printf '%T@ %p\n' \
        | sort -n | tail -5 | awk '{print $2}' | while read -r f; do
        echo "  $(basename "$f")"
    done
}

list_images() {
    local n="${1:-10}"
    echo "=== 最近上传的 $n 张图片 ==="
    find "$REPO_DIR" -maxdepth 1 -type f \( "${IMAGE_TYPES[@]}" \) -printf '%T@ %p\n' \
        | sort -n | tail -"$n" | awk '{print $2}' | while read -r f; do
        echo "  $(basename "$f")"
    done
}

find_images() {
    local prefix="${1:-}"
    if [ -z "$prefix" ]; then
        echo "请提供日期前缀，例如: ./terminal.sh find 20240407" >&2
        exit 1
    fi
    echo "=== 匹配 '$prefix' 的图片 ==="
    find "$REPO_DIR" -maxdepth 1 -type f -name "${prefix}*" | sort | while read -r f; do
        echo "  $(basename "$f")"
    done
}

show_help() {
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
    list)   list_images "${2:-10}" ;;
    find)   find_images "${2:-}" ;;
    help|-h|--help) show_help ;;
    "")     show_summary ;;
    *)
        echo "未知命令: $1" >&2
        echo "运行 './terminal.sh help' 查看用法。" >&2
        exit 1
        ;;
esac
