# ローカルPC環境でのOpenClaw構築手順

## 概要

VPSではなく、ローカルPC（またはコンテナ）でOpenClawを構築する手順。
この手順に従えば、いつでも同じ環境を再現できる。

構築済みのワークスペース設定は [openclaw-workspace](https://github.com/fukukei23/openclaw-workspace) に格納されている。

---

## 前提条件

| 項目 | 説明 |
|------|------|
| Docker | コンテナ仮想化プラットフォーム |
| Docker Compose | 複数コンテナの一括管理 |
| OpenClawソース | `https://github.com/openclaw/openclaw.git` |
| APIキー | z.ai（GLM-5用）、OpenAI（GPT-5用）、Brave（Web検索用）等 |

---

## 手順1: OpenClawカスタムイメージをビルド

Chromium（ブラウザ自動操作）と inotify-tools（ファイル監視）を含めたイメージを作成する。

```bash
cd /home/op
git clone https://github.com/openclaw/openclaw.git openclaw-src
cd openclaw-src

docker build \
  --build-arg OPENCLAW_INSTALL_BROWSER=1 \
  --build-arg OPENCLAW_DOCKER_APT_PACKAGES="inotify-tools" \
  -t openclaw-custom:latest .
```

- **所要時間**: 5〜10分
- **イメージサイズ**: +300MB程度

OpenClaw更新時は `git pull` 後に同じビルドコマンドを実行する（月1〜2回程度）。

---

## 手順2: docker-compose.yml を修正

`image:` をカスタムイメージに変更する。

```yaml
services:
  openclaw-gateway:
    image: openclaw-custom:latest  # カスタムイメージに変更
```

---

## 手順3: ワークスペースを取得

```bash
git clone https://github.com/fukukei23/openclaw-workspace.git
```

### ワークスペースの構成

```
openclaw-workspace/
├── AGENTS.md          # エージェントの動作ルール
├── SOUL.md            # エージェントの性格定義
├── USER.md            # ユーザー情報（ふくけい）
├── MEMORY.md          # 長期記憶
├── HEARTBEAT.md       # 定期タスク設定
├── TOOLS.md           # ツール固有設定
├── IDENTITY.md        # エージェントID（フクロウ）
├── config/
│   └── openclaw.json  # OpenClaw本体の設定ファイル
├── docs/              # 運用ドキュメント
├── memory/            # 記憶・ログ
│   ├── SHARED.md      # 全チャンネル共通の重要事項
│   └── channels/      # チャンネル別アーカイブ
├── scripts/           # 自動化スクリプト（18本）
├── skills/            # スキル定義
└── tools/             # ツール設定
```

---

## 手順4: openclaw.json を配置

`config/openclaw.json` をコンテナから読める場所に配置する。

```bash
# コンテナのボリュームマウント先にコピー
cp openclaw-workspace/config/openclaw.json /path/to/config/
```

### openclaw.json の主な設定項目

#### AIモデル構成

| エイリアス | モデル | 用途 |
|-----------|--------|------|
| 賢者 | zai/glm-5 | プライマリ（メイン） |
| 忍者 | zai/glm-4.7 | 低コスト版 |
| 錬金術師 | openai/gpt-5.1-codex | OpenAI上位 |
| 見習い | openai/gpt-5-mini | フォールバック |
| - | openai/gpt-5.2 | OpenAI最新 |

フォールバック順: `zai/glm-5` → `openai/gpt-5-mini` → `openai/gpt-5.1-codex`

#### ブラウザ設定

```json
"browser": {
  "executablePath": "/usr/bin/chromium",
  "headless": true,
  "noSandbox": true
}
```

#### Discord連携

- メインチャンネルで @なし応答
- ボットは拒否
- テキストチャンク: 2000文字

#### Web検索

- プロバイダー: Brave Search

---

## 手順5: 環境変数を設定

`.env` ファイルに以下を設定する。

```bash
# 必須
GLM_API_KEY=           # z.ai APIキー（GLM-5用）
OPENAI_API_KEY=        # OpenAI APIキー（GPT-5用）
DISCORD_BOT_TOKEN=     # Discord Bot トークン
BRAVE_API_KEY=         # Brave Search APIキー

# Gateway設定
OPENCLAW_GATEWAY_TOKEN=  # Gateway認証トークン

# パス設定
OPENCLAW_CONFIG_DIR=     # configディレクトリのパス
OPENCLAW_WORKSPACE_DIR=  # workspaceディレクトリのパス
```

---

## 手順6: コンテナを起動

```bash
cd /home/op/openclaw-stack
docker compose down
docker compose up -d
```

---

## 手順7: 動作確認

```bash
# Chromiumが入っているか
docker compose exec openclaw-gateway which chromium
# → /usr/bin/chromium

# inotify-toolsが入っているか
docker compose exec openclaw-gateway which inotifywait
# → /usr/bin/inotifywait

# 環境変数が反映されているか
docker compose exec openclaw-gateway env | grep -E "GLM|OPENAI|DISCORD|BRAVE"
```

---

## 自動化スクリプト一覧

ワークスペースの `scripts/` に含まれるスクリプト。

| スクリプト | 機能 |
|-----------|------|
| `ai_news_digest.py` | AIニュース収集（v1/v2/v3） |
| `ai_youtube_digest.py` | YouTube動画要約 |
| `discord_context_scan.py` | Discord定期スキャン |
| `openclaw_health_check.py` | ヘルスチェック |
| `morning_weather.py` | 天気情報 |
| `daily_summary.py` | 日次サマリー |
| `backup_workspace.sh` | ワークスペースバックアップ |
| `check_file_changes.sh` | ファイル変更監視 |
| `update_daily_note.py` | 日次ノート更新 |
| `channel_archive_auto.py` | チャンネル自動アーカイブ |

---

## Browser Relay（Surface Go連携）

2FA必須サイトや既存ログインが必要な場合、Surface GoのChromeをVPSから操作できる。

### 使い分け

| 用途 | 使用ツール |
|------|----------|
| 情報収集・スクレイピング | コンテナ内Chromium |
| ログイン不要の操作 | コンテナ内Chromium |
| 2FA必須サイト | Surface Go + Browser Relay |
| 既存ログイン状態維持 | Surface Go + Browser Relay |

詳細: [docs/browser-relay-setup.md](https://github.com/fukukei23/openclaw-workspace/blob/main/docs/browser-relay-setup.md)

---

## トラブルシューティング

### 設定変更が反映されない

`restart` ではなく `stop && up -d` を使う。

```bash
docker compose stop openclaw-gateway && docker compose up -d openclaw-gateway
```

### OpenClawを更新する

```bash
cd /home/op/openclaw-src
git pull
docker build \
  --build-arg OPENCLAW_INSTALL_BROWSER=1 \
  --build-arg OPENCLAW_DOCKER_APT_PACKAGES="inotify-tools" \
  -t openclaw-custom:latest .
cd /home/op/openclaw-stack
docker compose down && docker compose up -d
```

---

作成日: 2026-04-16
