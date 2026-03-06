#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_RIME="${RIME_USER_DIR:-$HOME/Library/Rime}"

mkdir -p "$REPO_DIR/rime/cn_dicts"

copy_file() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    cp -f "$src" "$dst"
  else
    echo "Skip missing: $src"
  fi
}

copy_file "$LOCAL_RIME/default.custom.yaml" "$REPO_DIR/rime/default.custom.yaml"
copy_file "$LOCAL_RIME/rime_ice.custom.yaml" "$REPO_DIR/rime/rime_ice.custom.yaml"
copy_file "$LOCAL_RIME/rime_ice.dict.yaml" "$REPO_DIR/rime/rime_ice.dict.yaml"
copy_file "$LOCAL_RIME/rime_ice.schema.yaml" "$REPO_DIR/rime/rime_ice.schema.yaml"
copy_file "$LOCAL_RIME/squirrel.custom.yaml" "$REPO_DIR/rime/squirrel.custom.yaml"
copy_file "$LOCAL_RIME/symbols_v.yaml" "$REPO_DIR/rime/symbols_v.yaml"
copy_file "$LOCAL_RIME/custom_phrase.txt" "$REPO_DIR/rime/custom_phrase.txt"
copy_file "$LOCAL_RIME/cn_dicts/8105.dict.yaml" "$REPO_DIR/rime/cn_dicts/8105.dict.yaml"
copy_file "$LOCAL_RIME/cn_dicts/base.dict.yaml" "$REPO_DIR/rime/cn_dicts/base.dict.yaml"
copy_file "$LOCAL_RIME/cn_dicts/ext.dict.yaml" "$REPO_DIR/rime/cn_dicts/ext.dict.yaml"
copy_file "$LOCAL_RIME/cn_dicts/others.dict.yaml" "$REPO_DIR/rime/cn_dicts/others.dict.yaml"

echo "Synced local Rime config into repo/rime"
