# セキュリティ設計ポートフォリオ

> OpenClaw Stack のセキュリティ設計における技術的判断と実装内容をまとめたポートフォリオ文書。
> Defense in Depth（多層防御）の実践例として参照可能。

---

## プロジェクト概要

| 項目 | 内容 |
|------|------|
| **プロジェクト名** | OpenClaw Stack |
| **概要** | AIエージェントプラットフォーム（OpenClaw）をVPS上で安全にホストするインフラ構成 |
| **要件** | 外部からのAIエージェントへの不正アクセスを防止しつつ、正規ユーザーはどこからでも利用可能 |
| **脅威モデル** | ポートスキャン、通信傍受、URL漏洩、認証突破、デバイス乗っ取り |

---

## 設計判断: Defense in Depth（多層防御）

AIエージェントはユーザーの権限で動作するため、乗っ取られると重大な被害が発生する：
- 勝手なメール送信・SNS投稿
- ファイルの読み取り・削除
- 外部APIの不正呼び出し（決済を含む）
- 機密情報の漏洩

単一のセキュリティ対策では不十分であり、各層が独立して機能する多重防御を採用した。

---

## 実装した4層防御

### レイヤー1: ネットワーク層（UFW ファイアウォール）

**脅威**: ポートスキャンによるサービス発見、直接攻撃

**実装**:
```
# UFW ルール
ufw default deny incoming
ufw allow 80/tcp      # HTTP（Caddy用）
ufw allow 443/tcp     # HTTPS（Caddy用）
ufw limit 22/tcp      # SSH（レート制限付き）
ufw deny 18789        # Gateway ポート（明示的拒否）
```

**設計判断**:
- Gateway（18789）をループバック（127.0.0.1）のみにバインド
- 外部からの直接アクセスをネットワーク層で遮断
- Dockerのポートマッピングも `127.0.0.1:18789:18789` で内部のみ

---

### レイヤー2: トランスポート層（TLS/HTTPS暗号化）

**脅威**: 通信傍受、中間者攻撃（MITM）、データ漏洩

**実装**:
```caddyfile
fopenclaw.com {
    encode gzip
    # CaddyがLet's Encryptから自動で証明書を取得・更新
    # 明示的なTLS設定不要（Auto HTTPS）
}
```

**設計判断**:
- リバースプロキシにCaddyを採用（Auto HTTPSで運用コストゼロ）
- Let's Encryptによる無料証明書を自動取得・自動更新
- HTTP→HTTPSリダイレクトもCaddyが自動処理

---

### レイヤー3: アプリケーション層（HTTP BasicAuth）

**脅威**: URL漏洩による不正アクセス

**実装**:
```bash
# パスワードハッシュの生成
echo "$PASSWORD" | docker run -i --rm caddy:2 hash-password
```
```caddyfile
fopenclaw.com {
    basicauth {
        deployer $HASHED_PASSWORD
    }
}
```

**設計判断**:
- アプリケーションレベルでのアクセス制御
- CaddyのBasicAuth機能を使用（追加ミドルウェア不要）
- パスワードはbcryptハッシュで保存

---

### レイヤー4: サービス層（Gateway Token + デバイスペアリング）

**脅威**: 認証突破後の不正操作、端末の乗っ取り

**実装**:
```json
{
  "gateway": {
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN}"
    }
  },
  "plugins": {
    "device-pair": {
      "config": {
        "publicUrl": "https://fopenclaw.com"
      }
    }
  }
}
```

**設計判断**:
- トークンベース認証（環境変数で管理、Gitには含めない）
- デバイスペアリングで許可された端末のみ接続可能
- トークンの定期ローテーションを推奨

---

## アーキテクチャ図

```
インターネット
    |
    v
[UFW] ポート80/443のみ許可（レイヤー1）
    |
    v
[Caddy] TLS終端 + Auto HTTPS（レイヤー2）
    |
    v
[Caddy] BasicAuth認証（レイヤー3）
    |
    v
[Docker Network] openclaw-net (172.30.0.0/24)
    |
    v
[OpenClaw Gateway] Token + デバイスペアリング（レイヤー4）
    |
    v
[LLM API] openai/gpt-5.1-codex
```

---

## 運用上の考慮事項

| 項目 | 対応 |
|------|------|
| **証明書更新** | Caddyが自動更新（手動対応不要） |
| **パスワード変更** | Caddyのhash-passwordで再生成 → Caddyfile更新 → reload |
| **トークンローテーション** | .envのGATEWAY_TOKEN変更 → コンテナ再起動 |
| **ログ監視** | Caddyアクセスログ + healthcheck.shで定期確認 |
| **インシデント対応** | トークン無効化 → コンテナ停止 → 原因調査 → 再構築 |

---

## 使用技術スタック

| 技術 | 用途 | 選定理由 |
|------|------|----------|
| **UFW** | ホストファイアウォール | Ubuntu標準、シンプルなルール定義 |
| **Caddy** | リバースプロキシ + TLS終端 | Auto HTTPS（Let's Encrypt自動管理）、設定ファイルが最小 |
| **Docker Compose** | コンテナオーケストレーション | ネットワーク分離、ポートマッピング制御 |
| **OpenClaw** | AIエージェントプラットフォーム | Token認証 + デバイスペアリング機能が内蔵 |

---

## 参考文献

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Defense in Depth - NIST](https://www.nist.gov/publications/defense-depth-security)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [OpenClaw Documentation](https://docs.openclaw.ai)

---

作成日: 2026-04-17
