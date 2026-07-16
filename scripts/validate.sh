#!/usr/bin/env bash
set -euo pipefail

RIME_DIR="${1:-rime}"

fail() {
  echo "校验失败：$*" >&2
  exit 1
}

required_files="
default.yaml
squirrel.yaml
wanxiang.schema.yaml
wanxiang.dict.yaml
wanxiang_english.schema.yaml
wanxiang_english.dict.yaml
wanxiang_mixedcode.schema.yaml
wanxiang_mixedcode.dict.yaml
wanxiang_reverse.schema.yaml
wanxiang_reverse.dict.yaml
wanxiang_algebra.yaml
wanxiang_symbols.yaml
version.txt
"

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  [[ -s "$RIME_DIR/$file" ]] || fail "缺少 $file"
done <<< "$required_files"

[[ -d "$RIME_DIR/dicts" ]] || fail "缺少 dicts"
[[ -d "$RIME_DIR/lua/wanxiang" ]] || fail "缺少万象 Lua"

if find "$RIME_DIR" \
  \( -iname '*rime_ice*' -o -iname '*melt_eng*' -o -iname '*wanxiang_t9*' \
     -o -iname '*backup*' -o -iname '*.bak' -o -name 'build' -o -name '*.userdb' \) \
  -print | grep -q .; then
  fail "存在旧方案、备份或用户状态文件"
fi

grep -q '^  - schema: wanxiang$' "$RIME_DIR/default.yaml" || fail "方案列表不是万象"
grep -q 'Shift_L: commit_code' "$RIME_DIR/default.yaml" || fail "左 Shift 切换缺失"
grep -q 'Shift_R: commit_code' "$RIME_DIR/default.yaml" || fail "右 Shift 切换缺失"
grep -q 'reset: 0.*新会话默认中文' "$RIME_DIR/wanxiang.schema.yaml" || fail "默认中文未设置"
grep -q 'states: \[中, 英\]' "$RIME_DIR/wanxiang.schema.yaml" || fail "中英标签不正确"
grep -q '^  alphabet: zyxwvutsrqponmlkjihgfedcba1234567890' "$RIME_DIR/wanxiang.schema.yaml" ||
  fail "大写字母仍在编码表"
grep -q 'color_scheme: wechat_light' "$RIME_DIR/squirrel.yaml" || fail "浅色皮肤缺失"
grep -q 'color_scheme_dark: wechat_dark' "$RIME_DIR/squirrel.yaml" || fail "深色皮肤缺失"
grep -q 'com.openai.codex:' "$RIME_DIR/squirrel.yaml" || fail "Codex 中文规则缺失"
grep -q '^16\.1\.2$' "$RIME_DIR/version.txt" || fail "万象版本不是 16.1.2"

echo "校验通过：万象 16.1.2，一套方案，无备份和用户状态。"
