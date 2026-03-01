#!/usr/bin/env bash
# 根据 src/ script/ test/ 里的 import 自动安装依赖
# 用法：在项目根目录执行 ./scripts/sync-deps.sh
# 流程：先写 import → 跑本脚本 → forge build（不打断写代码思路）

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

# 只扫描项目代码，不扫描 lib/
scan_imports() {
  for dir in src script test; do
    [ -d "$ROOT/$dir" ] || continue
    grep -rh 'import ["\x27].*["\x27]' "$ROOT/$dir" 2>/dev/null || true
  done | sed -E 's/.*import ["\x27]([^"\x27]+)["\x27].*/\1/' | sed 's|/[^/]*$||' | sort -u
}

# import 路径前缀 -> org/repo（新增依赖时在此追加并保持 remappings 在 foundry.toml）
get_repo_for_import() {
  local imp="$1"
  [[ "$imp" == @openzeppelin* ]]          && echo "OpenZeppelin/openzeppelin-contracts" && return
  [[ "$imp" == forge-std* ]]               && echo "foundry-rs/forge-std" && return
  [[ "$imp" == @openzeppelin-contracts* ]] && echo "OpenZeppelin/openzeppelin-contracts" && return
  [[ "$imp" == @solady* ]]                 && echo "Vectorized/solady" && return
  [[ "$imp" == @solmate* ]]                && echo "transmissions11/solmate" && return
  echo ""
}

echo "[sync-deps] 扫描 src/ script/ test/ 中的 import..."
IMPORTS=$(scan_imports)
[ -z "$IMPORTS" ] && echo "[sync-deps] 未发现外部 import。" && forge remappings && exit 0

TMP=$(mktemp)
trap "rm -f $TMP" EXIT
for imp in $IMPORTS; do
  repo=$(get_repo_for_import "$imp")
  [ -z "$repo" ] && continue
  lib_dir="lib/$(basename "$repo")"
  [ -d "$ROOT/$lib_dir" ] && continue
  echo "$repo" >> "$TMP"
done
sort -u "$TMP" -o "$TMP"

if [ ! -s "$TMP" ]; then
  echo "[sync-deps] 所需依赖均已存在。"
  forge remappings
  exit 0
fi

while read -r repo; do
  echo "[sync-deps] 安装 $repo"
  forge install "$repo"
done < "$TMP"

echo "[sync-deps] 当前 remappings:"
forge remappings
echo "[sync-deps] 完成。可执行 forge build 验证。"