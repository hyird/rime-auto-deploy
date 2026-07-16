#!/usr/bin/env bash
set -euo pipefail

REPO_SLUG="${RIME_DEPLOY_REPO:-hyird/rime-auto-deploy}"
REPO_REF="${RIME_DEPLOY_REF:-main}"
SQUIRREL="/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel"
TEMP_ROOT=""
STATE_STASH=""

cleanup() {
  if [[ -n "$TEMP_ROOT" && -d "$TEMP_ROOT" ]]; then
    find "$TEMP_ROOT" -depth -delete
  fi
}
trap cleanup EXIT INT TERM

die() {
  echo "错误：$*" >&2
  exit 1
}

ensure_temp_root() {
  if [[ -z "$TEMP_ROOT" ]]; then
    TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/rime-auto-deploy.XXXXXX")"
  fi
}

prepare_source() {
  local script_path script_dir archive_root
  script_path="${BASH_SOURCE[0]:-}"
  script_dir=""
  if [[ -n "$script_path" ]]; then
    script_dir="$(cd "$(dirname "$script_path")" 2>/dev/null && pwd || true)"
  fi

  if [[ -n "$script_dir" && -f "$script_dir/rime/wanxiang.schema.yaml" ]]; then
    SRC_DIR="$script_dir/rime"
    return
  fi

  command -v curl >/dev/null 2>&1 || die "缺少 curl"
  command -v tar >/dev/null 2>&1 || die "缺少 tar"

  TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/rime-auto-deploy.XXXXXX")"
  echo "下载 $REPO_SLUG@$REPO_REF…"
  curl -fsSL "https://github.com/$REPO_SLUG/archive/$REPO_REF.tar.gz" |
    tar -xzf - -C "$TEMP_ROOT"
  archive_root="$(find "$TEMP_ROOT" -mindepth 1 -maxdepth 1 -type d -print | head -n 1)"
  [[ -n "$archive_root" && -f "$archive_root/rime/wanxiang.schema.yaml" ]] ||
    die "下载内容缺少万象配置"
  SRC_DIR="$archive_root/rime"
}

ensure_frontend() {
  if [[ "${RIME_SKIP_FRONTEND_INSTALL:-0}" == "1" ]]; then
    return
  fi
  [[ "$(uname -s)" == "Darwin" ]] || die "此一键脚本仅支持 macOS"
  if [[ -x "$SQUIRREL" ]]; then
    return
  fi
  command -v brew >/dev/null 2>&1 ||
    die "未安装鼠须管或 Homebrew；请先安装 Homebrew"
  echo "安装鼠须管…"
  brew install --cask squirrel
  [[ -x "$SQUIRREL" ]] || die "鼠须管安装失败"
}

validate_source() {
  local required
  for required in \
    default.yaml squirrel.yaml wanxiang.schema.yaml wanxiang.dict.yaml \
    wanxiang_english.schema.yaml wanxiang_english.dict.yaml \
    wanxiang_mixedcode.schema.yaml wanxiang_mixedcode.dict.yaml \
    wanxiang_reverse.schema.yaml wanxiang_reverse.dict.yaml \
    wanxiang_algebra.yaml wanxiang_symbols.yaml version.txt; do
    [[ -s "$SRC_DIR/$required" ]] || die "部署源缺少 $required"
  done
  [[ -d "$SRC_DIR/dicts" && -d "$SRC_DIR/lua" ]] || die "部署源缺少词库或 Lua"
  if find "$SRC_DIR" \( -iname '*rime_ice*' -o -iname '*melt_eng*' -o -iname '*backup*' \) -print |
    grep -q .; then
    die "部署源包含雾凇或备份文件"
  fi
}

clean_managed_config() {
  local db dir
  mkdir -p "$TARGET_DIR"

  # 保留 installation.yaml、user.yaml 以及万象用户词频数据库，只替换配置源和编译产物。
  find "$TARGET_DIR" -maxdepth 1 -type f \
    \( -name '*.yaml' -o -name '*.txt' \) \
    ! -name 'installation.yaml' ! -name 'user.yaml' -delete

  # 万象的预测、手动调序、提示等用户数据库位于 lua/*.userdb。
  # 在临时目录托管，复制新 Lua 后原位恢复；退出时临时目录自动清理。
  if [[ -d "$TARGET_DIR/lua" ]]; then
    ensure_temp_root
    STATE_STASH="$TEMP_ROOT/user-state"
    mkdir -p "$STATE_STASH/lua"
    while IFS= read -r -d '' db; do
      cp -R "$db" "$STATE_STASH/lua/"
    done < <(find "$TARGET_DIR/lua" -maxdepth 1 -type d -name '*.userdb' -print0)
  fi

  for dir in build dicts lua cn_dicts en_dicts opencc; do
    if [[ -d "$TARGET_DIR/$dir" ]]; then
      find "$TARGET_DIR/$dir" -depth -delete
    fi
  done

  # 旧方案学习数据不再使用，避免留下雾凇残余。
  for dir in rime_ice.userdb melt_eng.userdb; do
    if [[ -d "$TARGET_DIR/$dir" ]]; then
      find "$TARGET_DIR/$dir" -depth -delete
    fi
  done
}

restore_user_state() {
  if [[ -n "$STATE_STASH" && -d "$STATE_STASH/lua" ]]; then
    mkdir -p "$TARGET_DIR/lua"
    cp -R "$STATE_STASH/lua/." "$TARGET_DIR/lua/"
  fi
}

reload_and_verify() {
  local attempt
  if [[ "${RIME_SKIP_RELOAD:-0}" == "1" ]]; then
    echo "已跳过重新部署（RIME_SKIP_RELOAD=1）"
    return
  fi

  [[ -x "$SQUIRREL" ]] || die "找不到鼠须管可执行文件"
  echo "重新部署鼠须管…"
  "$SQUIRREL" --reload

  for attempt in $(seq 1 30); do
    if build_complete; then
      break
    fi
    sleep 1
  done

  build_complete || die "万象或依赖词库编译失败"
  grep -q 'schema: wanxiang' "$TARGET_DIR/build/default.yaml" || die "万象未进入方案列表"
  if grep -q 'rime_ice\|melt_eng' "$TARGET_DIR/build/default.yaml"; then
    die "编译结果仍包含旧方案"
  fi
}

build_complete() {
  local artifact
  for artifact in \
    default.yaml squirrel.yaml \
    wanxiang.schema.yaml wanxiang.table.bin \
    wanxiang_english.schema.yaml wanxiang_english.table.bin \
    wanxiang_mixedcode.schema.yaml wanxiang_mixedcode.table.bin \
    wanxiang_reverse.schema.yaml wanxiang_reverse.table.bin; do
    [[ -s "$TARGET_DIR/build/$artifact" ]] || return 1
  done
}

prepare_source
validate_source
ensure_frontend

TARGET_DIR="${RIME_USER_DIR:-$HOME/Library/Rime}"
case "$TARGET_DIR" in
  ""|/|"$HOME") die "拒绝使用危险的目标目录：$TARGET_DIR" ;;
esac

echo "覆盖 Rime 配置：$TARGET_DIR"
clean_managed_config
cp -R "$SRC_DIR/." "$TARGET_DIR/"
restore_user_state
reload_and_verify

echo "完成：万象拼音 $(cat "$TARGET_DIR/version.txt")，皮肤与 Shift 行为已部署。"
