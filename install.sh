#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/rime"
OS="$(uname -s)"

ensure_rime_frontend() {
  case "$OS" in
    Darwin)
      if [[ -x "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel" ]]; then
        return 0
      fi
      echo "Squirrel not found. Trying to install via Homebrew..."
      if command -v brew >/dev/null 2>&1; then
        brew install --cask squirrel
      else
        echo "Homebrew not found. Install Homebrew first, then run: brew install --cask squirrel" >&2
        exit 1
      fi
      if [[ ! -x "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel" ]]; then
        echo "Squirrel install failed. Please install manually and rerun." >&2
        exit 1
      fi
      ;;
    Linux)
      echo "Warning: Linux detected. Please make sure ibus-rime or fcitx5-rime is installed." >&2
      ;;
    *)
      echo "Unsupported OS: $OS (set RIME_USER_DIR manually)" >&2
      exit 1
      ;;
  esac
}

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Missing rime directory: $SRC_DIR" >&2
  exit 1
fi

if [[ "${RIME_USER_DIR:-}" != "" ]]; then
  TARGET_DIR="$RIME_USER_DIR"
else
  case "$OS" in
    Darwin)
      TARGET_DIR="$HOME/Library/Rime"
      ;;
    Linux)
      if [[ -d "$HOME/.local/share/fcitx5/rime" ]]; then
        TARGET_DIR="$HOME/.local/share/fcitx5/rime"
      elif [[ -d "$HOME/.config/ibus/rime" ]]; then
        TARGET_DIR="$HOME/.config/ibus/rime"
      else
        TARGET_DIR="$HOME/.local/share/fcitx5/rime"
      fi
      ;;
    *)
      echo "Unsupported OS: $OS (set RIME_USER_DIR manually)" >&2
      exit 1
      ;;
  esac
fi

ensure_rime_frontend

mkdir -p "$TARGET_DIR"
BACKUP_DIR="$TARGET_DIR.backup.$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backup current target files to: $BACKUP_DIR"
while IFS= read -r -d '' src; do
  rel="${src#$SRC_DIR/}"
  dst="$TARGET_DIR/$rel"
  if [[ -e "$dst" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -a "$dst" "$BACKUP_DIR/$rel"
  fi
done < <(find "$SRC_DIR" -type f -print0)

echo "Deploying files to: $TARGET_DIR"
rsync -a "$SRC_DIR/" "$TARGET_DIR/"

if [[ -x "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel" ]]; then
  echo "Rebuild and reload Squirrel"
  /Library/Input\ Methods/Squirrel.app/Contents/MacOS/Squirrel --build || true
  /Library/Input\ Methods/Squirrel.app/Contents/MacOS/Squirrel --reload || true
fi

echo "Done."
