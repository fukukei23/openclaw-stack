# ローカルPC環境構築手順（Surface Go / よつば）

## 概要

Surface Go（Ubuntu 24.04 LTS）上でOpenClawを構築する手順。
この手順は [yotsuba/handover/README_HANDOVER.md](https://github.com/fukukei23/openclaw-workspace/blob/master/yotsuba/handover/README_HANDOVER.md) を基に作成している。

---

## 前提条件

| 項目 | 説明 |
|------|------|
| **マシン** | Surface Go 第1世代 / Pentium 4415Y / RAM 8GB |
| **OS** | Ubuntu 24.04 LTS（CUI環境） |
| **Docker** | v29.x 以上（docker-ce、apt版ではないこと） |
| **APIキー** | z.ai（GLM-5用）、MiniMax、Discord Bot Token |

---

## 手順1: Ubuntu初期セットアップ

```bash
# スリープ無効化（常時稼働のため）
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Docker公式リポジトリからインストール
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# ログアウト → 再ログイン
```

---

## 手順2: ディレクトリとファイルの準備

```bash
mkdir -p ~/nemoclaw-dev ~/.openclaw
```

### テンプレートから設定ファイルを作成

```bash
# このリポジトリの surface-go/ からコピー
cp surface-go/Dockerfile ~/nemoclaw-dev/
cp surface-go/docker-compose.yml.template ~/nemoclaw-dev/docker-compose.yml
cp surface-go/.env.template ~/nemoclaw-dev/.env
cp surface-go/openclaw.json.template ~/.openclaw/openclaw.json
```

### 各ファイルに実際の値を設定

- **`.env`**: APIキー（`GLM_API_KEY`, `MINIMAX_API_KEY`, `DISCORD_BOT_TOKEN`）
- **`openclaw.json`**: `<GUILD_ID>`, `<YOUR_USER_ID>`, `<CHANNEL_ID>`, `<BOT_NAME>` を実際の値に置換

---

## 手順3: Dockerイメージをビルド

```bash
cd ~/nemoclaw-dev
docker build -t openclaw-surface:local .
```

- **所要時間**: 5〜15分
- **ベース**: `ghcr.io/openclaw/openclaw:latest`（公式イメージ）
- **追加パッケージ**: Chromium、ffmpeg、git、jq、python3、ripgrep 等（Dockerfile参照）

---

## 手順4: コンテナを起動

```bash
cd ~/nemoclaw-dev
docker compose up -d
```

---

## 手順5: 動作確認

```bash
# コンテナ状態
docker compose ps
# → openclaw-gateway が Up (healthy) であること

# ログ確認
docker compose logs -f --tail 50
# → [discord] logged in to discord as ... (よつば) が出ること

# Gateway応答
curl http://127.0.0.1:18789
```

---

## 手順6: ファイル権限設定

```bash
sudo chown -R 1000:1000 ~/.openclaw/
sudo chmod -R 775 ~/.openclaw/
sudo usermod -aG systemd-journal $USER
```

---

## 手順7: Tailscale VPN設定（外出先からアクセスする場合）

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Surface Go の Tailscale IP で外出先からSSH接続可能。

---

## 手順8: Discord Bot設定

1. [Discord Developer Portal](https://discord.com/developers/applications) でBotを作成
2. 以下のIntentsをONにする:
   - Message Content Intent
   - Server Members Intent
   - Presence Intent
3. Bot Token を `.env` の `DISCORD_BOT_TOKEN` に設定

---

## アップデート手順

```bash
cd ~/nemoclaw-dev

# 1. ベースイメージを最新化
docker pull ghcr.io/openclaw/openclaw:latest

# 2. カスタムイメージを再ビルド
docker build -t openclaw-surface:local .

# 3. コンテナ再作成
docker compose up -d

# 4. 動作確認
docker compose ps
docker compose logs --tail 20
```

> **注意**: `docker compose pull` ではなく `docker pull` + `docker build` を使うこと。
> カスタムDockerfileでビルドしているため、`pull` だけでは反映されない。

---

## 設定変更時の注意

### openclaw.json 編集後

```bash
# 構文チェック
python3 -m json.tool ~/.openclaw/openclaw.json > /dev/null && echo OK || echo ERROR

# 再起動（restart ではなく stop && up）
cd ~/nemoclaw-dev && docker compose stop openclaw-gateway && docker compose up -d openclaw-gateway
```

### .env 編集後

```bash
cd ~/nemoclaw-dev && docker compose stop openclaw-gateway && docker compose up -d openclaw-gateway
```

---

## よく使うコマンド

```bash
cd ~/nemoclaw-dev

docker compose ps                            # 状態確認
docker compose logs -f --tail 50              # ログ確認
docker compose restart openclaw-gateway       # 再起動
docker compose down                           # 停止
docker compose up -d                          # 起動
```

---

## トラブルシューティング

### コンテナが起動しない

```bash
docker compose logs gateway
```

### 権限エラー（ファイルが編集できない）

```bash
sudo chown -R 1000:1000 ~/.openclaw/
```

### Wi-Fiチップ不安定（ath10k AERエラー）

Surface GoのWi-Fiチップ（ath10k）が定期的にエラーを起こしSSHが切断される。
根本解決にはUSB-C有線LANアダプターを推奨。

---

作成日: 2026-04-17
正本: [yotsuba/handover/README_HANDOVER.md](https://github.com/fukukei23/openclaw-workspace/blob/master/yotsuba/handover/README_HANDOVER.md)
