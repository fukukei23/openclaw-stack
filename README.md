# OpenClaw Stack

<p align="center">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/Caddy-6DB33F?style=for-the-badge&logo=caddy&logoColor=white" alt="Caddy">
  <img src="https://img.shields.io/badge/AI-Agent-FF6B6B?style=for-the-badge" alt="AI Agent">
</p>

> OpenClaw（AIエージェントプラットフォーム）を安全かつシンプルにVPSでホスティングするためのインフラ構成管理リポジトリ

---

## リポジトリ構成

OpenClawの運用は2つのリポジトリで構成されています。

| リポジトリ | 役割 | 公開設定 |
|-----------|------|----------|
| **openclaw-stack**（ここ） | VPSインフラ構成・デプロイ・セキュリティ設定 | Public |
| [openclaw-workspace](https://github.com/fukukei23/openclaw-workspace) | エージェント設定・自動化スクリプト・記憶・運用ワークスペース | Private |

### 関係図

```
openclaw-stack（インフラ層）
├── docker-compose.yml       # 3サービス定義
├── caddy/Caddyfile          # リバースプロキシ設定
├── healthcheck.sh           # システム診断
└── docs/                    # デプロイ・運用手順
        ↓ マウント
openclaw-workspace（運用層）
├── config/openclaw.json     # OpenClaw本体設定
├── AGENTS.md / SOUL.md      # エージェントの性格・ルール
├── HEARTBEAT.md             # 定期タスク（ニュース収集・要約等）
├── scripts/                 # 自動化スクリプト（18本）
├── memory/                  # 長期記憶・ログ
└── skills/                  # スキル定義
```

---

## プロジェクト概要

**OpenClaw Stack** は、AIエージェントプラットフォーム「OpenClaw」を、VPS（Virtual Private Server：仮想専用サーバー）に安全にデプロイするための Docker Compose 構成です。

### 主な特徴

- **セキュリティ重視**: 4層防御（ファイアウォール、HTTPS、認証、デバイストークン）で外部からの不正アクセスを防止
- **快速セットアップ**: Docker Compose により数分で稼働可能
- **自動HTTPS**: Let's Encrypt（無料SSL証明書発行サービス）による自動SSL/TLS暗号化
- **状態監視**: healthcheck.sh でシステム全体を一括診断

---

## クイックスタート

### VPS運用の場合

```bash
# 1. リポジトリをクローン
git clone https://github.com/fukukei23/openclaw-stack.git
cd openclaw-stack

# 2. 環境設定ファイルを作成
cp .env.example .env
# .envファイルを編集して、Gateway Token や APIキーを設定

# 3. Dockerコンテナを起動
docker compose up -d

# 4. 動作確認
curl -u deployer: https://fopenclaw.com/status
```

### ローカル環境構築の場合

ローカルPCでOpenClawを構築する手順は [docs/05-LOCAL-SETUP.md](docs/05-LOCAL-SETUP.md) を参照。

---

## アーキテクチャ

### システム構成図

```
                            インターネット
                                 |
                                 v
                    +-----------------------------+
                    |      fopenclaw.com          |
                    |        (ドメイン)             |
                    +--------------+--------------+
                                   |
                                   v
                    +-----------------------------+
                    |   UFW ファイアウォール         |
                    |  (ポート80/443のみ許可)        |
                    +--------------+--------------+
                                   |
                                   v
                    +-----------------------------+
                    |  Caddy (リバースプロキシ)       |
                    |  IP: 172.30.0.10             |
                    |  - HTTPS化                   |
                    |  - BasicAuth認証              |
                    |  ポート: 80, 443              |
                    +--------------+--------------+
                                   |
                                   v
                    +-----------------------------+
                    |  OpenClaw Gateway             |
                    |  IP: 172.30.0.20              |
                    |  内部ポート: 18789              |
                    |  (外部直接アクセス不可)          |
                    +--------------+--------------+
                                   |
                                   v
                    +-----------------------------+
                    |   OpenClaw CLI                |
                    |   (ローカル操作用)              |
                    +-----------------------------+
```

### コンポーネント詳細

| コンポーネント | 役割 | IPアドレス | ポート |
|----------------|------|------------|--------|
| **Caddy** | 外部からのアクセスを受け付け、HTTPS化とBasicAuth認証を担当するリバースプロキシ | 172.30.0.10 | 80, 443 |
| **openclaw-gateway** | OpenClawのメインサービス。AIエージェントの管理・実行 | 172.30.0.20 | 18789 (内部のみ) |
| **openclaw-cli** | ターミナルからOpenClawを操作するコマンドラインクライアント | - | - |

---

## セキュリティ（4層防御）

```
  【レイヤー1】UFW ファイアウォール
  - ポート80(HTTP) と 443(HTTPS) のみ公開
  - ポート18789（Gateway）は完全にブロック
  - SSH は制限付きで許可
          |
          v
  【レイヤー2】Caddy TLS (HTTPS暗号化)
  - Let's Encryptによる自動SSL証明書発行
  - すべての通信を暗号化
          |
          v
  【レイヤー3】HTTP BasicAuth (ID/パスワード認証)
  - 事前に設定したユーザー名/パスワードでアクセス制御
  - 未認証者のアクセスを排除
          |
          v
  【レイヤー4】Gateway Token + デバイスペアリング
  - OpenClaw独自の認証トークン
  - 許可されたデバイスのみ接続可能
```

---

## ファイル構成

```
openclaw-stack/
├── docker-compose.yml           # インフラ定義（3サービスの設定）
├── docker-compose.override.yml  # 環境変数読み込み設定
├── healthcheck.sh               # システム診断スクリプト
├── caddy/
│   └── Caddyfile               # Caddy設定ファイル
└── docs/                        # 詳細ドキュメント
    ├── 00-README.md             # 環境サマリー
    ├── 01-ARCHITECTURE.md       # アーキテクチャの詳細説明
    ├── 02-NETWORK.md            # ネットワーク構成詳細
    ├── 03-SECURITY.md           # セキュリティ設定詳細
    ├── 04-DEPLOYMENT.md         # デプロイ手順詳細
    └── 05-LOCAL-SETUP.md        # ローカル環境構築手順
```

---

## 前提条件

| 項目 | 説明 | 推奨 |
|------|------|------|
| **VPS** | 仮想専用サーバー | Ubuntu 22.04 LTS |
| **Docker** | コンテナ仮想化プラットフォーム | 最新安定版 |
| **Docker Compose** | 複数コンテナの一括管理ツール | v2.x 以上 |
| **ドメイン** | Webサイトのアドレス（例: fopenclaw.com） | DNS Aレコード設定済み |
| **OpenAI APIキー** | AIモデルへのアクセス権 | 有効なキー |

---

## 設定方法

### 1. 環境変数の設定

`.env` ファイルを作成し、以下の項目を設定します：

```bash
# .env ファイルの例
OPENCLAW_GATEWAY_TOKEN=your_secure_token_here
OPENCLAW_CONFIG_DIR=/path/to/config
OPENCLAW_WORKSPACE_DIR=/path/to/workspace
```

### 2. BasicAuth パスワードの生成

```bash
# Caddy用のハッシュパスワードを生成
echo "Your password" | docker run -i --rm caddy:2 hash-password
# 出力されたハッシュ値をCaddyfileに記述
```

### 3. DNS設定

ドメインのAレコードでVPSのIPアドレスを指定：

```
A record: fopenclaw.com -> 162.43.17.111
```

---

## 運用コマンド

### サービスの起動・停止

```bash
# 起動
docker compose up -d

# 停止
docker compose down

# 再起動
docker compose restart

# ログ確認
docker compose logs -f
```

### ヘルスチェック（システム診断）

```bash
# 全項目チェック
./healthcheck.sh
```

healthcheck.sh で確認できる項目：
- システム時刻・ディスク容量
- Docker コンテナの稼働状況
- Caddy 設定の妥当性検証
- 各サービスのログ

---

## ネットワーク構成

| ネットワーク名 | サブネット | 用途 |
|---------------|-----------|------|
| `openclaw-net` | 172.30.0.0/24 | 全サービス間通信用 |

| サービス | IPアドレス | 備考 |
|---------|-----------|------|
| Caddy | 172.30.0.10 | 外部公開エントリーポイント |
| openclaw-gateway | 172.30.0.20 | 内部サービスのみ |
| openclaw-cli | 自動割り当て | クライアント用 |

> Gatewayは **127.0.0.1:18789**（自分自身からのみアクセス可能）でリッスンし、
> 外部からの直接アクセスを拒否します。

---

## トラブルシューティング

### Dockerコンテナが起動しない

```bash
docker compose logs gateway   # ゲートウェイのログ確認
docker info                    # Dockerの状態確認
```

### HTTPS証明書のエラー

```bash
docker compose logs caddy     # Caddyのログ確認
docker exec caddy caddy reload --config /etc/caddy/Caddyfile  # 設定再読み込み
```

### ネットワーク接続の問題

```bash
docker network inspect openclaw-net   # ネットワーク確認
ping fopenclaw.com                     # DNS確認
```

---

## ドキュメント

| ファイル | 内容 |
|---------|------|
| [docs/00-README.md](docs/00-README.md) | 環境サマリー |
| [docs/01-ARCHITECTURE.md](docs/01-ARCHITECTURE.md) | アーキテクチャ詳細 |
| [docs/02-NETWORK.md](docs/02-NETWORK.md) | ネットワーク構成詳細 |
| [docs/03-SECURITY.md](docs/03-SECURITY.md) | セキュリティ設定詳細 |
| [docs/04-DEPLOYMENT.md](docs/04-DEPLOYMENT.md) | VPSデプロイ手順詳細 |
| [docs/05-LOCAL-SETUP.md](docs/05-LOCAL-SETUP.md) | ローカル環境構築手順 |

---

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) をご覧ください。

---

<p align="center">
  <sub>Built for OpenClaw Community</sub>
</p>
