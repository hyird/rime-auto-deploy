# Rime 万象拼音一键部署

这是我的 macOS 鼠须管配置，基于万象拼音标准版 `16.1.2`。仓库只保留一套输入方案，并固化当前使用习惯：

- 微信浅色 / 深色皮肤；
- 新输入框默认中文；
- 单按 `Shift` 在 Rime 内部切换“中 / 英”；
- 中文模式下 `Shift + 字母` 直接输入大写英文，不进入中文候选；
- 自动词频学习、英文混输和拆字反查；
- 不包含雾凇、九宫格、编译缓存、用户词频或备份。

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/hyird/rime-auto-deploy/35ba2dc/install.sh | bash
```

脚本会在缺少鼠须管时尝试通过 Homebrew 安装，然后覆盖 `~/Library/Rime` 中的配置源、清除旧方案并重新部署。

安装过程不会创建持久备份。以下个人状态会保留：

- `installation.yaml` 和 `user.yaml`；
- 当前万象中文、英文和手动调序用户数据库。

雾凇和 `melt_eng` 的旧用户数据库会随旧方案一起删除。

## 从本地仓库安装

```bash
git clone https://github.com/hyird/rime-auto-deploy.git
cd rime-auto-deploy
./install.sh
```

可使用自定义目标目录进行测试：

```bash
RIME_USER_DIR=/tmp/Rime RIME_SKIP_FRONTEND_INSTALL=1 RIME_SKIP_RELOAD=1 ./install.sh
```

## 同步本机配置

```bash
./sync-from-local.sh
```

同步脚本只复制可部署配置，不会提交 `build/`、`*.userdb/`、本机身份文件或备份。

## 校验

```bash
bash -n install.sh sync-from-local.sh scripts/validate.sh
./scripts/validate.sh rime
```

## 上游与许可

词库和方案来自 [amzxyz/rime_wanxiang](https://github.com/amzxyz/rime_wanxiang)，按其 CC BY 4.0 许可分发；许可文本见 `LICENSES/WANXIANG-CC-BY-4.0.txt`。
