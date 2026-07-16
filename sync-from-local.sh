#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_RIME="${RIME_USER_DIR:-$HOME/Library/Rime}"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rime-sync.XXXXXX")"

cleanup() {
  if [[ -d "$TEMP_DIR" ]]; then
    find "$TEMP_DIR" -depth -delete
  fi
}
trap cleanup EXIT INT TERM

[[ -f "$LOCAL_RIME/wanxiang.schema.yaml" ]] || {
  echo "当前 Rime 目录不是万象方案：$LOCAL_RIME" >&2
  exit 1
}

rsync -a \
  --exclude 'build/' \
  --exclude '*.userdb/' \
  --exclude 'installation.yaml' \
  --exclude 'user.yaml' \
  --exclude '.DS_Store' \
  "$LOCAL_RIME/" "$TEMP_DIR/rime/"

"$REPO_DIR/scripts/validate.sh" "$TEMP_DIR/rime"

if [[ -d "$REPO_DIR/rime" ]]; then
  find "$REPO_DIR/rime" -depth -delete
fi
mkdir -p "$REPO_DIR/rime"
cp -R "$TEMP_DIR/rime/." "$REPO_DIR/rime/"

echo "已同步当前万象配置；用户词频、编译缓存和备份未写入仓库。"
