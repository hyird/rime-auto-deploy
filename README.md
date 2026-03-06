# My Rime Config

This repo stores my minimal Rime setup (rime_ice + Squirrel theme).

## Structure

- `rime/`: files that will be deployed into your Rime user directory
- `install.sh`: one-click deploy script
- `sync-from-local.sh`: pull current local config into this repo

## One-click deploy

### macOS

```bash
git clone <your-repo-url>
cd <repo-name>
chmod +x install.sh
./install.sh
```

### Custom target dir

```bash
RIME_USER_DIR=/path/to/rime ./install.sh
```

## Update repo from local machine

```bash
chmod +x sync-from-local.sh
./sync-from-local.sh
```

## Notes

- `install.sh` backs up overwritten files to `TARGET_DIR.backup.TIMESTAMP`.
- On macOS, if Squirrel is missing, script tries to install it via `brew install --cask squirrel`.
- On Linux, install `fcitx5-rime` or `ibus-rime` first, then run the script.
- On macOS with Squirrel, script runs `--build` and `--reload` automatically.
