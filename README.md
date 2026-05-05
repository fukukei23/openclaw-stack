# OpenClaw Stack

> Infrastructure-as-code repository for deploying and operating OpenClaw (AI agent platform) on both VPS (production with Caddy reverse proxy + HTTPS) and local PC (Surface Go development environment).

<p align="center">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/Caddy-6DB33F?style=for-the-badge&logo=caddy&logoColor=white" alt="Caddy">
  <img src="https://img.shields.io/badge/AI-Agent-FF6B6B?style=for-the-badge" alt="AI Agent">
</p>

> OpenClaw（AIエージェントプラットフォーム）をVPS・ローカルPCで構築・運用するためのインフラ構成管理リポジトリ

---

## 2つの構成環境

本リポジトリは、OpenClawを **2つの異なる環境** で構築するための構成を管理している。

| 項目 | VPS（フクロウ） | ローカルPC（よつば） |
|------|---------------|-------------------|
| **用途** | 本番・常時稼働 | ローカル開発・実験 |
| **マシン** | VPS（Ubuntu） | Surface Go 第1世代 |
| **IP** | `${VPS_IP}` | `${LOCAL_IP}` / `${TAILSCALE_IP}` |
| **外部公開** | あり（HTTPS） | なし（ローカルのみ） |
| **コンテナ数** | 2（Caddy + Gateway） | 1（Gatewayのみ） |
| **リバースプロキシ** | Caddy（TLS終端） | なし |
| **ディレクトリ** | `./`（ルート） | `./surface-go/` |
| **Bot名** | フクロウ | よつば |

### アーキテクチャ比較

```
■ VPS（フクロウ）
  インターネット
       |
       v
  UFW ファイアウォール（80/443のみ）
       |
       v
  Caddy（リバースプロキシ）:80,:443
       | - HTTPS化（Let's Encrypt）
       | - BasicAuth認証
       v
  OpenClaw Gateway :18789（内部のみ）
       |
       v
  OpenAI API

■ ローカルPC（よつば）
  ローカルネットワーク / Tailscale VPN
       |
       v
  SSH（認証鍵必須）
       |
       v
  OpenClaw Gateway :18789（ループバックのみ）
       |
       v
  z.ai GLM-5 API / MiniMax API
```

---

## リポジトリ構成

```
openclaw-stack/
├── docker-compose.yml           # VPS用: Caddy + Gateway
├── docker-compose.override.yml  # VPS用: 環境変数
├── caddy/
│   └── Caddyfile               # VPS用: リバースプロキシ設定
├── healthcheck.sh              # VPS用: システム診断
├── surface-go/                  # ローカルPC用
│   ├── Dockerfile              # カスタムイメージ（公式ベース + 追加パッケージ）
│   ├── docker-compose.yml.template
│   ├── .env.template
│   └── openclaw.json.template
└── docs/                        # 共通ドキュメント
    ├── 00-README.md            # 環境サマリー
    ├── 01-ARCHITECTURE.md      # アーキテクチャ詳細
    ├── 02-NETWORK.md           # ネットワーク構成
    ├── 03-SECURITY.md          # セキュリティ設定
    ├── 04-DEPLOYMENT.md        # VPSデプロイ手順
    └── 05-LOCAL-SETUP.md       # ローカルPC構築手順
```

### 関連リポジトリ

| リポジトリ | 役割 | 公開設定 |
|-----------|------|----------|
| **openclaw-stack**（ここ） | VPS + ローカルPCのインフラ構成 | Public |
| [openclaw-workspace](https://github.com/fukukei23/openclaw-workspace) | エージェント設定・自動化スクリプト・記憶（実行時ワークスペース） | Private |

```
openclaw-stack（インフラ層）
  VPS: docker-compose / Caddyfile / healthcheck
  Surface Go: Dockerfile / docker-compose / openclaw.json
        ↓ マウント
openclaw-workspace（運用層）
  config/openclaw.json     # OpenClaw本体設定
  AGENTS.md / SOUL.md     # エージェントの性格・ルール
  HEARTBEAT.md            # 定期タスク
  scripts/                # 自動化スクリプト（18本）
  fukurou/                # フクロウ(VPS)の引き継ぎ資料
  yotsuba/                # よつば(Surface Go)の引き継ぎ資料
```

---

## クイックスタート

### VPS運用の場合

```bash
git clone https://github.com/fukukei23/openclaw-stack.git
cd openclaw-stack
cp .env.example .env
# .env を編集
docker compose up -d
```

詳細: [docs/04-DEPLOYMENT.md](docs/04-DEPLOYMENT.md)

### ローカルPC（Surface Go）構築の場合

```bash
git clone https://github.com/fukukei23/openclaw-stack.git
cd openclaw-stack/surface-go

cp .env.template .env && cp docker-compose.yml.template docker-compose.yml
cp openclaw.json.template ~/.openclaw/openclaw.json
# .env と openclaw.json を編集
docker build -t openclaw-surface:local . && docker compose up -d
```

詳細: [docs/05-LOCAL-SETUP.md](docs/05-LOCAL-SETUP.md)

---

## 運用コマンド

### 共通

```bash
docker compose ps                    # 状態確認
docker compose logs -f --tail 50     # ログ確認
docker compose restart openclaw-gateway  # 再起動
```

### VPS: ヘルスチェック

```bash
./healthcheck.sh
```

### ローカルPC: アップデート

```bash
cd ~/nemoclaw-dev
docker pull ghcr.io/openclaw/openclaw:latest   # ベースイメージ最新化
docker build -t openclaw-surface:local .         # カスタムイメージ再ビルド
docker compose up -d                             # コンテナ再作成
```

---

## セキュリティ（VPS: 4層防御）

```
【レイヤー1】UFW ファイアウォール（80/443のみ公開）
【レイヤー2】Caddy TLS（Let's Encrypt自動HTTPS）
【レイヤー3】HTTP BasicAuth（ID/パスワード認証）
【レイヤー4】Gateway Token + デバイスペアリング
```

---

## ドキュメント

| ファイル | 内容 |
|---------|------|
| [docs/00-README.md](docs/00-README.md) | 環境サマリー |
| [docs/01-ARCHITECTURE.md](docs/01-ARCHITECTURE.md) | アーキテクチャ詳細 |
| [docs/02-NETWORK.md](docs/02-NETWORK.md) | ネットワーク構成 |
| [docs/03-SECURITY.md](docs/03-SECURITY.md) | セキュリティ設定 |
| [docs/04-DEPLOYMENT.md](docs/04-DEPLOYMENT.md) | VPSデプロイ手順 |
| [docs/05-LOCAL-SETUP.md](docs/05-LOCAL-SETUP.md) | ローカルPC構築手順 |

---

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) をご覧ください。
