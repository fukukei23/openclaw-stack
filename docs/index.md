---
title: 概要
nav_order: 1
---

# OpenClaw Stack

> 📂 **[GitHub リポジトリ →](https://github.com/fukukei23/openclaw-stack)**{: .btn .btn-blue } — インフラ構成・設定ファイル詳細はこちらから

AIエージェントプラットフォーム「OpenClaw」を、VPSとローカルPCの両方で構築・運用するためのインフラ構成管理リポジトリ。

## 2つの構成環境

| 項目 | VPS（本番） | ローカルPC |
|------|------------|-----------|
| **用途** | 本番・常時稼働 | 開発・実験 |
| **マシン** | VPS(Ubuntu) | Surface Go |
| **外部公開** | HTTPS有 | ローカルのみ |
| **リバースプロキシ** | Caddy | なし |
| **Bot名** | フクロウ | よつば |

## VPSアーキテクチャ（本番）

```
インターネット → UFW(80/443) → Caddy(HTTPS) → OpenClaw Gateway:18789 → OpenAI API
```

## ローカルPCアーキテクチャ

```
ローカル/Tailscale VPN → SSH(鍵認証) → OpenClaw Gateway:18789 → GLM-5/MiniMax API
```

## 技術スタック

| カテゴリ | 技術 |
|---|---|
| コンテナ | Docker / Docker Compose |
| リバースプロキシ | Caddy |
| ファイアウォール | UFW |
| VPN | Tailscale |
| AI API | OpenAI / GLM / MiniMax |

---

> 👉 各環境の詳細はサイドバーの **docs** をご覧ください。
