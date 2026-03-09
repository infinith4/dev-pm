# Software Requirements Specification (SRS)
## ShopHub SaaS ─ Azure Entra ID マルチテナント EC プラットフォーム（夜間バッチ・工場連携対応）, Release 1.0

> **参考**: Karl Wiegers "Software Requirements 3rd Edition" Chapter 10

## ドキュメント情報

| 項目 | 内容 |
|------|------|
| プロダクト名 | ShopHub SaaS |
| リリース | Release 1.0 |
| バージョン | 1.3 approved |
| 作成日 | 2026-03-08 |
| 最終更新日 | 2026-03-09 |
| ステータス | Approved |
| 作成者 | 佐藤 花子（BA）、田中 誠（Architect） |
| 承認者 | 山田 太郎（PM） |

---

## 1. Introduction

### 1.1 Purpose

本 SRS は ShopHub SaaS Release 1.0 のソフトウェア機能要件・非機能要件を定義する。設計・実装・テスト・保守を担当するプロジェクトチームが使用する。特に断りのない限り、すべての要件は Release 1.0 にコミットされている。

### 1.2 Document Conventions

#### 要件 ID 規約（階層テキストタグ形式）

```
Feature.SubFeature: 機能グループの説明
.Item:              個別要件（"システムは〜しなければならない" で記述）
```

例:
```
Batch.Parallel:   夜間バッチ並列処理
.Queue:           システムはテナントごとのジョブを Azure Service Bus キューに投入しなければならない
.Node:            システムは Azure Batch ノードでテナントごとに独立したジョブを実行しなければならない
```

#### 優先度

- **Must**: Release 1.0 に必須
- **Should**: 重要だが Release 2 への移動可
- **Could**: あれば望ましい
- **Won't**: Release 1.0 のスコープ外

#### TBD 規約

```
[TBD-nnn: 説明, 担当者, 期限]
```

未解決 TBD は Appendix C に一覧化し、実装開始前に解決する。

### 1.3 Project Scope

本プロジェクトは Azure 上のマルチテナント EC SaaS プラットフォームを構築し、複数の小売事業者（テナント）が同一アプリケーション基盤を共有しながらデータを完全に隔離して利用できるようにする。日次 1,000 万件の注文データをキュー駆動バッチで並列処理し、工場ごとに定められた CSV フォーマットで自動配布する機能を含む。

参照: [vision-and-scope.md](vision-and-scope.md)

### 1.4 References

| 文書名 | バージョン | 場所 |
|-------|---------|------|
| Vision & Scope Document | 1.0 | `docs/pm/example_multitenant_ec/vision-and-scope.md` |
| 機能一覧 | 1.0 | `docs/pm/example_multitenant_ec/functional/functional-list.md` |
| 機能要件: EC サイト | 1.0 | `docs/pm/example_multitenant_ec/functional/FR-001-ECサイト.md` |
| 機能要件: テナント管理 | 1.0 | `docs/pm/example_multitenant_ec/functional/FR-010-テナント管理.md` |
| 機能要件: テナントデータ分離 | 1.0 | `docs/pm/example_multitenant_ec/functional/FR-011-テナントデータ分離.md` |
| 機能要件: 夜間バッチ処理 | 1.0 | `docs/pm/example_multitenant_ec/functional/FR-020-夜間バッチ処理.md` |
| 機能要件: 工場データ連携 | 1.0 | `docs/pm/example_multitenant_ec/functional/FR-021-工場データ連携.md` |
| 機能要件: 工場出荷完了通知受信 | 1.1 | `docs/pm/example_multitenant_ec/functional/FR-022-工場出荷完了通知受信.md` |
| 非機能要件 | 1.0 | `docs/pm/example_multitenant_ec/non-functional/NFR.md` |
| 業務ルールカタログ | 1.0 | `docs/pm/example_multitenant_ec/business-rules-catalog.md` |
| Microsoft Azure マルチテナントアーキテクチャガイド | — | https://learn.microsoft.com/ja-jp/azure/architecture/guide/multitenant/overview |
| Azure Batch ドキュメント | — | https://learn.microsoft.com/ja-jp/azure/batch/ |

---

## 2. Overall Description

### 2.1 Product Perspective

ShopHub SaaS は中小規模小売事業者向けの個別 EC 構築・保守サービスの後継として、複数企業が共通の Azure インフラを利用するマルチテナント EC SaaS プラットフォームへ転換する。

**テナント分離モデル**: **Bridge モデル（共有アプリ + テナント別 Entra ID テナント + テナント別 DB）**

```
┌─────────────────────────────────────────────────────────────────────┐
│ 共有レイヤー（Azure Container Apps / Azure Front Door / Azure Batch） │
│  React EC サイト  │  管理サイト  │  FastAPI アプリ  │  バッチ処理   │
└────────────────────────────┬────────────────────────────────────────┘
                              │ テナント ID でルーティング
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ テナント A       │ │ テナント B       │ │ テナント C       │
│─────────────────│ │─────────────────│ │─────────────────│
│ Entra ID テナント│ │ Entra ID テナント│ │ Entra ID テナント│
│ CIAM（消費者）  │ │ CIAM（消費者）  │ │ CIAM（消費者）  │
│ PostgreSQL DB   │ │ PostgreSQL DB   │ │ PostgreSQL DB   │
│ Blob コンテナ   │ │ Blob コンテナ   │ │ Blob コンテナ   │
│ Batch ジョブ    │ │ Batch ジョブ    │ │ Batch ジョブ    │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

外部エンティティ（コンテキスト図）:
- **Microsoft Entra ID**: テナントごとの Entra ID テナント（Microsoft Graph API で自動作成）
- **Azure AD External Identities（CIAM）**: EC サイトの消費者認証（テナント別設定）
- **Azure Batch**: 夜間バッチの並列処理基盤（テナントごとに独立したジョブ）
- **Azure Service Bus**: 注文イベントキュー（`order-batch-queue`）・工場転送ジョブキュー（`factory-transfer-queue`）・デッドレターキュー管理
- **Azure Blob Storage**: バッチ中間ファイル・工場向けファイル配布・テナント別コンテナ
- **Azure Cognitive Search**: EC サイトの商品検索（テナント別インデックス）
- **Azure Front Door + WAF**: テナントルーティング・グローバル CDN・DDoS 対策
- **Stripe**: EC サイトの消費者決済 + SaaS サブスクリプション課金
- **SFTP サーバー（工場）**: 工場ごとの外部 SFTP サーバー
- **Azure Monitor**: バッチ処理状況・テナント別ログ・メトリクス収集
- **Azure Key Vault**: テナント別接続文字列・SFTP 認証キー・シークレット管理

### 2.2 User Classes and Characteristics

| ユーザークラス | 説明 | 利用頻度 | 技術レベル | 優先度 |
|-------------|------|---------|---------|-------|
| **プラットフォーム管理者** | SaaS 事業者のインフラ・運用担当者。全テナント・バッチ監視を担当。約 3 名。 | 日次 | 高 | Favored |
| **テナント管理者** | 契約企業の IT 担当者。ユーザー管理・工場設定・課金・バッチ状況確認を担当。テナントあたり 1〜3 名。 | 週次 | 中〜高 | Favored |
| **店舗スタッフ** | テナント内の商品・在庫・注文管理を担当。Entra ID SSO でログイン。テナントあたり 1〜50 名。 | 日次 | 低〜中 | Favored |
| **消費者** | EC サイトで商品を購入するエンドユーザー。CIAM（Azure AD External Identities）で認証。テナントあたり〜10 万名。 | 随時 | 低 | Favored |
| **工場システム（外部）** | 夜間バッチで生成された CSV ファイルを SFTP/Blob から受け取り、出荷完了後に ShopHub へ出荷完了通知（Webhook POST）を送信するシステム。テナントあたり 1〜10 工場。 | 日次（自動） | — | Favored |

### 2.3 Operating Environment

| 項目 | 内容 |
|------|------|
| クラウド | Microsoft Azure（Japan East リージョン、DR: Japan West） |
| フロントエンド | Azure Static Web Apps（React + TypeScript） |
| バックエンド | Azure Container Apps（FastAPI / Python） |
| データベース | Azure Database for PostgreSQL Flexible Server（テナントごとに 1 インスタンス） |
| 認証（テナント管理者・店舗スタッフ） | Microsoft Entra ID（テナントごとに専用テナント・OIDC） |
| 認証（消費者） | Azure AD External Identities（CIAM）（テナントごとに専用設定） |
| バッチ処理 | Azure Batch（動的スケール Pool、複数ノード） |
| メッセージング | Azure Service Bus（バッチジョブキュー） |
| ストレージ | Azure Blob Storage（テナントごとにコンテナ分離） |
| 検索 | Azure Cognitive Search（テナント別インデックス） |
| CDN / ルーティング | Azure Front Door + WAF |
| キャッシュ | Azure Cache for Redis（セッション・カートデータ） |
| 決済 | Stripe（EC 消費者決済 + SaaS 課金） |
| ファイル転送 | SFTP（工場ごとの外部サーバー）・Azure Blob（SAS URL） |
| 監視 | Azure Monitor + Application Insights |
| シークレット管理 | Azure Key Vault（テナント別シークレット） |
| クライアント | Chrome / Firefox / Edge / Safari（最新 2 バージョン）。レスポンシブ対応（デスクトップ・タブレット） |

### 2.4 Design and Implementation Constraints

| ID | 制約 | 理由 |
|----|------|------|
| CO-1 | テナント識別子はすべての API リクエスト・DB クエリ・バッチジョブで検証しなければならない | テナント間データ漏洩を防止するため |
| CO-2 | テナントデータは論理的にも物理的にも他テナントから隔離しなければならない（Bridge モデル） | セキュリティ審査要件 |
| CO-3 | フロントエンド: React (TypeScript)、バックエンド: FastAPI (Python)、DB: PostgreSQL 15 以上 | 既存開発資産の継承 |
| CO-4 | すべての通信は TLS 1.3 以上で暗号化しなければならない | セキュリティポリシー |
| CO-5 | テナントのデータは日本国内 Azure リージョン（Japan East / Japan West）のみに保存しなければならない | 個人情報保護法・顧客要件 |
| CO-6 | 各 API エンドポイントにテナントコンテキスト検証ミドルウェアを適用しなければならない | 横断的な分離保証 |
| CO-7 | バッチジョブはテナントごとに独立した Azure Batch ジョブとして実行しなければならない | バッチ処理のテナント分離 |
| CO-8 | 工場への CSV ファイルにはテナント ID を埋め込み、誤配布を検知できるようにしなければならない | 工場データの誤混入防止 |
| CO-9 | SFTP 接続は SSH キー認証を使用しなければならない（パスワード認証禁止） | セキュリティポリシー |

### 2.5 Assumptions and Dependencies

- AS-1: テナントは Entra ID テナントの管理権限を SaaS プラットフォームに委任できる。
- AS-2: テナントあたりの日次注文数は最大 100 万件（全テナント合計日次 1,000 万件）を上限として設計する。
- AS-3: 工場は SFTP サーバーまたは Azure Blob へのアクセス環境を保有している。
- DE-1: Azure Batch の動的スケール機能が正常に動作することに依存する。
- DE-2: Microsoft Graph API を利用した Entra ID テナント作成が可能なことに依存する。
- DE-3: Stripe API を利用した課金処理が正常に動作することに依存する。

---

## 3. System Features

### 3.1 テナント管理・Entra ID プロビジョニング（FE-1）

**説明**: プラットフォーム管理者がテナントのライフサイクルを管理し、Entra ID テナントを自動プロビジョニングする。Priority = **Must**。

**機能要件**: 詳細は [FR-010-テナント管理.md](functional/FR-010-テナント管理.md) を参照。

主要要件サマリー:
- Tenant.Provision: Microsoft Graph API で Entra ID テナント・CIAM 設定・管理サイト OIDC アプリ登録・DB・Blob コンテナ・カスタムドメインを 20 分以内に自動プロビジョニングする
- Tenant.FactoryConfig: テナントが利用する工場の設定（工場コード・フォーマット定義・転送先 SFTP/Blob）を管理する
- Tenant.Config: テナント設定（スラッグ・カスタムドメイン・タイムゾーン・スタッフロール）を管理する
- Tenant.Lifecycle: 停止・再開・解約・物理削除を管理する
- Tenant.Billing: Starter/Professional/Enterprise プランを管理する（夜間バッチ機能は Professional 以上）

### 3.2 テナントデータ分離（FE-2）

**説明**: テナントごとに Entra ID テナント・PostgreSQL データベース・Blob ストレージ・バッチジョブを分離し、他テナントのデータへのアクセスを物理的・論理的に防止する。Priority = **Must**。

**機能要件**: 詳細は [FR-011-テナントデータ分離.md](functional/FR-011-テナントデータ分離.md) を参照。

主要要件サマリー:
- Isolation.Identity: Entra ID テナント分離（JWT iss クレーム検証）
- Isolation.Database: テナント専用 PostgreSQL DB（Bridge モデル）
- Isolation.Storage: テナント専用 Blob コンテナ + SAS トークン
- **Isolation.Batch**: バッチジョブのテナント分離（テナントごとに独立したジョブ、他テナントのデータが混入しないことを保証）

### 3.3 EC サイト（FE-3）

**説明**: 消費者向けの EC サイト（商品カタログ・カート・Stripe 決済・注文管理）を提供する。日次 1,000 万件規模の注文（全テナント合計）に対応する。Priority = **Must**。

**機能要件**: 詳細は [FR-001-ECサイト.md](functional/FR-001-ECサイト.md) を参照。

主要要件サマリー:
- Shop.Auth: CIAM 認証（Azure AD External Identities）
- Shop.Browse: 商品カタログ・検索（Azure Cognitive Search）
- Shop.Cart: カート管理（Redis キャッシュ for セッション管理）
- Shop.Checkout: チェックアウト・Stripe 決済
- Shop.Order: 注文管理・注文履歴
- 性能要件: ピーク時 10,000 req/sec に対応

### 3.4 管理サイト・Entra ID SSO（FE-4）

**説明**: 店舗スタッフ向けの管理サイト（商品・在庫・注文・顧客管理）を Entra ID SSO で提供する。Priority = **Must**。

**機能要件**:

**Admin.Auth: 認証**

**.SSO**: システムは、テナント専用 Entra ID テナントによる OIDC SSO をサポートしなければならない。

**.JwtValidation**: システムは、JWT の `iss` クレームがテナントの Entra ID テナント ID と一致することを検証しなければならない。（BR-MT-22 参照）

**.MFA**: システムは、テナントの Entra ID 条件付きアクセスポリシーに基づいて MFA を要求しなければならない。

**Admin.Product: 商品管理**

**.Create**: システムは、店舗スタッフが商品（名称・価格・在庫数・画像・カテゴリ）を登録・更新・削除できなければならない。

**.Stock**: システムは、在庫数の更新と在庫切れアラートを管理しなければならない。

**Admin.Order: 注文管理**

**.List**: システムは、注文一覧（日付・消費者・金額・ステータス）を表示しなければならない。

**.Detail**: システムは、注文明細（商品・数量・配送先・決済情報）を表示しなければならない。

**.Status**: システムは、注文ステータス（受付・処理中・出荷・完了・キャンセル）を更新できなければならない。

**.BatchStatus**: システムは、当日・前日の夜間バッチ実行状況（処理件数・進捗率・完了時刻・エラー件数）を表示しなければならない。

### 3.5 課金管理（FE-5）

**説明**: Stripe と連携してプラン選択・クレジットカード決済・請求書発行を管理する。Priority = **Must**。

**機能要件**:

**Billing.Plan: プラン管理**

**.Select**: テナント管理者は、Starter / Professional / Enterprise の 3 プランから選択できなければならない。（BR-MT-31 参照）

**.Batch**: Professional 以上のプランでのみ夜間バッチ処理機能（FE-6）を利用できなければならない。（BR-MT-31 参照）

**.Upgrade**: テナント管理者はプランをアップグレードでき、差額は日割り計算されなければならない。

**Billing.Payment: 決済処理**

**.Card**: システムは Stripe を介してクレジットカード情報を登録・更新できなければならない。カード番号はシステム内に保存してはならない。

**.Invoice**: システムは月次で請求書を自動生成し、テナント管理者にメール送信しなければならない。

### 3.6 注文キュー駆動バッチ処理（FE-6）

**説明**: 注文が確定するたびにキューに投入し、常時稼働の Azure Batch ワーカーがキューから注文を集約・CSV に変換して工場へ継続的に送信する。固定の 22:00 スケジュール一斉送信ではなく、件数（1,000 件: SizeFlush）または時間（30 分: TimeFlush）のしきい値に基づいてバッチを随時生成する。Priority = **Must**。

**機能要件**: 詳細は [FR-020-夜間バッチ処理.md](functional/FR-020-夜間バッチ処理.md) を参照。

主要要件サマリー:
- Batch.Enqueue: 注文確定時に `order-batch-queue` へ注文イベントを自動投入（重複排除付き）
- Batch.Aggregate: バッチワーカーが (tenant_id, factory_id) 単位でメッセージを集約。SizeFlush（1,000 件）/ TimeFlush（30 分）でフラッシュ
- Batch.Extract: テナント専用 DB から集約バッファの order_id 一覧で注文データを抽出
- Batch.Transform: 工場マスタに基づいて CSV フォーマットに変換
- Batch.Validate: 変換後データのバリデーション（必須項目・型・件数）
- Batch.Load: Azure Blob へ一時保存し、`factory-transfer-queue` 経由で工場データ連携（FE-7）へ引き渡す
- Batch.Monitor: キュー深度・処理件数を Azure Monitor に随時送信。滞留 10,000 件超でアラート
- Batch.Retry: 失敗時は 3 回自動リトライ後にデッドレターキューへ移動・アラート発報

### 3.7 工場データ連携（FE-7）

**説明**: バッチ処理後のデータを工場ごとの CSV フォーマットに変換し、SFTP または Azure Blob で配布する。Priority = **Must**。

**機能要件**: 詳細は [FR-021-工場データ連携.md](functional/FR-021-工場データ連携.md) を参照。

主要要件サマリー:
- Factory.FormatMaster: 工場マスタ（工場コード・フォーマット定義・転送方式・接続情報）を管理
- Factory.FormatDef: フォーマット定義（列名・型・マッピングルール・エンコーディング・区切り文字）を管理
- Factory.Generate: 注文データをフォーマット定義に基づいて CSV/TSV に変換
- Factory.Encrypt: 必要に応じて PGP 暗号化
- Factory.Transfer.SFTP: SFTP サーバーへのファイル転送（SSH キー認証）
- Factory.Transfer.Blob: Azure Blob への配置（SAS URL 通知）
- Factory.TransferLog: 転送結果（成功/失敗・件数・ファイルサイズ・完了時刻）を記録
- Factory.Notify: 転送完了後の工場システムへの通知（Webhook / メール）
- Factory.Retry: 転送失敗時は 3 回リトライ後にアラート発報

### 3.8 工場出荷完了通知受信（FE-7 逆フロー）

**説明**: 工場が CSV データを受け取り数時間後に出荷を完了したら、Webhook で ShopHub に通知を送信する。ShopHub は通知を受信・検証し、注文ステータスを `shipped` に更新し、消費者に発送通知メールを送信する。Priority = **Must**。

**機能要件**: 詳細は [FR-022-工場出荷完了通知受信.md](functional/FR-022-工場出荷完了通知受信.md) を参照。

主要要件サマリー:
- ShipNotify.Endpoint: 工場ごとの出荷完了通知受信エンドポイント（HTTPS POST・HMAC-SHA256 署名認証）
- ShipNotify.Receive: スキーマ検証・HMAC 署名検証・テナント分離確認・冪等性チェック
- ShipNotify.Update: 注文ステータスを `shipped` に更新し、追跡番号・配送業者を記録
- ShipNotify.ConsumerAlert: 消費者への発送通知メール送信（1 分以内）
- ShipNotify.StaffAlert: 管理サイトへのリアルタイム反映・通知バナー表示
- ShipNotify.Log: 通知受信ログ（件数・成功/スキップ/エラー件数）を記録
- ShipNotify.Retry: エラー時の工場への再送指示（`Retry-After` ヘッダー）

---

## 4. Data Requirements

### 4.1 Logical Data Model（マルチテナント EC + バッチ）

```
┌──────────────────────┐       ┌─────────────────────────────────────┐
│ Platform DB          │       │ Tenant DB（テナントごと）             │
│──────────────────────│       │─────────────────────────────────────│
│ tenants              │  1:1  │ consumers（消費者）                  │
│  tenant_id PK        │──────▶│  consumer_id PK                     │
│  name                │       │  email                              │
│  slug                │       │  ciam_object_id                     │
│  entra_tenant_id     │       │  created_at                         │
│  plan_id FK          │       │                                     │
│  status              │       │ products（商品）                     │
│  db_connection       │       │  product_id PK                      │
│  blob_container      │       │  name, price, stock_qty             │
│  ciam_config         │       │                                     │
│  custom_domain       │       │ orders（注文）※バッチ対象            │
│  created_at          │       │  order_id PK                        │
│                      │       │  consumer_id FK                     │
│ factory_masters      │       │  status（pending/locked/confirmed/  │
│  factory_id PK       │       │    shipped/cancelled/capture_failed)│
│  tenant_id FK        │       │  ordered_at, cancellation_cutoff_at │
│                      │       │  locked_at, batch_processed_at      │
│                      │       │  stripe_payment_intent_id           │
│                      │       │  stripe_capture_status              │
│  factory_code        │       │                                     │
│  factory_name        │       │ order_items（注文明細）              │
│  format_def_id FK    │       │  item_id PK                         │
│  transfer_type       │       │  order_id FK                        │
│  sftp_host           │       │  product_id FK                      │
│  sftp_user           │       │  quantity, unit_price               │
│  sftp_key_vault_ref  │       │                                     │
│  blob_uri            │       │ factory_order_data（工場送信データ）  │
│  notify_type         │       │  factory_order_data_id PK           │
│  notify_endpoint     │       │  order_id FK                        │
│  use_pgp             │       │  factory_id FK                      │
│                      │       │  product_code, product_name         │
│  pgp_key_vault_ref   │       │  quantity, unit_price               │
│  ship_notify_enabled │       │  shipping_name, shipping_address    │
│  ship_notify_hmac_   │       │  created_at, batch_sent_at          │
│    key_vault_ref     │       │                                     │
│                      │       │ batch_logs（バッチ実行ログ）          │
│  notify_type         │       │  log_id PK                          │
│  notify_endpoint     │       │  batch_date                         │
│  use_pgp             │       │  tenant_id, factory_id              │
│                      │       │  total_records, processed_records   │
│ format_definitions   │       │  started_at, completed_at           │
│  format_def_id PK    │       │  status, error_message              │
│  name                │       │                                     │
│  encoding            │       │ transfer_logs（転送ログ）            │
│  delimiter           │       │  transfer_id PK                     │
│  has_header          │       │  factory_id FK                      │
│  columns (JSONB)     │       │  file_name, file_size_bytes         │
│  file_extension      │       │  transfer_type, destination         │
│                      │       │  status, completed_at               │
│ plans                │       │                                     │
│  plan_id PK          │       │ order_shipping_info（出荷情報）      │
│  ...                 │       │  shipping_id PK                     │
│                      │       │  order_id FK                        │
│                      │       │  factory_id FK                      │
│                      │       │  tracking_number, carrier           │
│                      │       │  notified_at                        │
│                      │       │                                     │
│                      │       │ ship_notify_logs（通知受信ログ）     │
│                      │       │  notify_log_id PK                   │
│                      │       │  factory_id FK                      │
│                      │       │  tenant_id                          │
│                      │       │  received_at                        │
│                      │       │  total/success/skip/error_count     │
│                      │       │  http_status, error_message         │
│ plans                │       └─────────────────────────────────────┘
│  plan_id PK          │
│  name                │
│  price_monthly       │
│  batch_enabled       │
│  max_factories       │
└──────────────────────┘
```

**分離方式**: Platform DB（全テナント共通のメタデータ・工場マスタ・フォーマット定義）と Tenant DB（テナントごとの業務データ・注文・バッチログ）を物理的に分離する。

### 4.2 注文テーブル（Tenant DB）

| フィールド | 型 | 制約 | 説明 |
|---------|----|----|------|
| order_id | UUID | PK, NOT NULL | 注文一意識別子 |
| consumer_id | UUID | FK, NOT NULL | 消費者 ID（Tenant DB の consumers テーブル） |
| status | ENUM | NOT NULL | `pending`（オーソリ済み・キャンセル可） / `locked`（キャンセル期限到達・工場送信待ち） / `confirmed`（工場送信完了・決済確定） / `shipped`（出荷済み） / `completed`（受取完了） / `cancelled`（キャンセル済み） / `capture_failed`（キャプチャ失敗・要対応） |
| total_amount | NUMERIC(12,0) | NOT NULL | 注文合計金額（円） |
| ordered_at | TIMESTAMPTZ | NOT NULL | 注文日時（JST） |
| cancellation_cutoff_at | TIMESTAMPTZ | NOT NULL | キャンセル期限（ordered_at + テナント設定時間、デフォルト 60 分） |
| locked_at | TIMESTAMPTZ | NULL 可 | `locked` 遷移日時 |
| batch_processed_at | TIMESTAMPTZ | NULL 可 | バッチ処理完了・`confirmed` 遷移日時 |
| stripe_payment_intent_id | VARCHAR(255) | UNIQUE | Stripe PaymentIntent ID（オーソリ時に取得） |
| stripe_capture_status | ENUM | NOT NULL | `authorized`（オーソリ済み） / `captured`（キャプチャ済み） / `voided`（void済み） / `failed`（キャプチャ失敗） |

### 4.2b 工場注文データテーブル factory_order_data（Tenant DB）

注文受付時に作成される工場送信用データ。バッチ処理（FR-020）のデータソース。注文後の商品・価格変更から独立した不変データとして保持する。

| フィールド | 型 | 制約 | 説明 |
|---------|----|----|------|
| factory_order_data_id | UUID | PK, NOT NULL | 一意識別子 |
| order_id | UUID | FK, NOT NULL | 注文 ID（orders テーブル） |
| factory_id | UUID | FK, NOT NULL | 工場 ID（Platform DB の factory_masters） |
| product_code | VARCHAR(100) | NOT NULL | 商品コード（注文時点の値を保持） |
| product_name | VARCHAR(500) | NOT NULL | 商品名（注文時点の値を保持） |
| quantity | INTEGER | NOT NULL | 数量 |
| unit_price | NUMERIC(12,0) | NOT NULL | 単価（注文時点の値を保持） |
| shipping_name | VARCHAR(200) | NOT NULL | 配送先氏名 |
| shipping_zip | VARCHAR(10) | NOT NULL | 配送先郵便番号 |
| shipping_address | VARCHAR(500) | NOT NULL | 配送先住所（都道府県〜番地・建物名） |
| created_at | TIMESTAMPTZ | NOT NULL | レコード作成日時（注文受付時） |
| batch_sent_at | TIMESTAMPTZ | NULL 可 | バッチにより工場に送信された日時 |

### 4.3 工場マスタ（Platform DB）

| フィールド | 型 | 制約 | 説明 |
|---------|----|----|------|
| factory_id | UUID | PK, NOT NULL | 工場一意識別子 |
| tenant_id | UUID | FK, NOT NULL | テナント ID |
| factory_code | VARCHAR(20) | UNIQUE（テナント内）, NOT NULL | 工場コード（ファイル名に使用） |
| factory_name | VARCHAR(200) | NOT NULL | 工場名 |
| format_def_id | UUID | FK, NOT NULL | フォーマット定義 ID |
| transfer_type | ENUM | NOT NULL | sftp / blob |
| sftp_host | VARCHAR(255) | NULL 可 | SFTP ホスト名（transfer_type=sftp の場合必須） |
| sftp_user | VARCHAR(100) | NULL 可 | SFTP ユーザー名 |
| sftp_key_vault_ref | VARCHAR(500) | NULL 可 | Azure Key Vault のシークレット参照名（SSH 秘密鍵） |
| blob_uri | VARCHAR(500) | NULL 可 | Azure Blob URI（transfer_type=blob の場合必須） |
| notify_type | ENUM | NOT NULL | webhook / email / none |
| notify_endpoint | VARCHAR(500) | NULL 可 | 通知先 URL またはメールアドレス |
| use_pgp | BOOLEAN | NOT NULL, DEFAULT false | PGP 暗号化の要否 |
| pgp_key_vault_ref | VARCHAR(500) | NULL 可 | PGP 公開鍵の Key Vault 参照名 |

### 4.4 フォーマット定義テーブル（Platform DB）

| フィールド | 型 | 制約 | 説明 |
|---------|----|----|------|
| format_def_id | UUID | PK, NOT NULL | フォーマット定義一意識別子 |
| name | VARCHAR(100) | NOT NULL | フォーマット定義名（例: "工場A標準フォーマット v2"） |
| encoding | VARCHAR(20) | NOT NULL | ファイルエンコーディング（例: UTF-8, Shift_JIS） |
| delimiter | CHAR(1) | NOT NULL | 区切り文字（例: `,` / `\t`） |
| has_header | BOOLEAN | NOT NULL | ヘッダー行の有無 |
| file_extension | VARCHAR(10) | NOT NULL | ファイル拡張子（例: csv, tsv） |
| columns | JSONB | NOT NULL | 列定義配列（列名・型・必須・マッピングルール） |

columns JSONB 例:
```json
[
  {"col_index": 1, "col_name": "受注番号",   "type": "string", "required": true,  "source": "order_id"},
  {"col_index": 2, "col_name": "受注日",     "type": "date",   "required": true,  "source": "ordered_at", "format": "yyyyMMdd"},
  {"col_index": 3, "col_name": "商品コード", "type": "string", "required": true,  "source": "product_code"},
  {"col_index": 4, "col_name": "数量",       "type": "integer","required": true,  "source": "quantity"},
  {"col_index": 5, "col_name": "単価",       "type": "decimal","required": false, "source": "unit_price", "decimal_places": 0}
]
```

### 4.5 Data Integrity, Retention, and Disposal

- **整合性**: Tenant DB への接続は Platform DB の `db_connection` を経由し、直接アクセスは禁止する。バッチジョブはテナント ID を常に検証してから DB に接続する。
- **保持**: テナントデータはサービス解約後 90 日間保持し、その後物理削除する。（BR-MT-40 参照）バッチログ・転送ログは 2 年間保持する。
- **廃棄**: テナント削除時に DB インスタンスを削除し、Blob ストレージコンテナを完全消去する。削除ログを監査証跡として 7 年間保持する。

---

## 5. External Interface Requirements

### 5.1 User Interfaces

- Azure Front Door 経由で `https://shop.{テナントドメイン}` (EC サイト) および `https://admin.{テナントドメイン}` (管理サイト) にアクセスする。
- 管理サイトにはバッチ実行状況ダッシュボード（処理件数・進捗率・完了時刻・アラート）を含める。
- 対応ブラウザ: Chrome / Firefox / Edge / Safari（最新 2 バージョン）。
- レスポンシブ対応: デスクトップ（1920px〜）・タブレット（768px〜）。

### 5.2 Software Interfaces

| IF-ID | 接続先 | バージョン | 目的 | データ形式 | プロトコル |
|-------|-------|---------|------|---------|---------|
| SI-1 | Microsoft Entra ID（Graph API） | v1.0 | テナント Entra ID テナント自動作成・CIAM 設定 | JSON | REST / HTTPS |
| SI-2 | Azure AD External Identities | — | EC サイト消費者認証（CIAM） | JWT | OIDC |
| SI-3 | Azure Batch | — | 夜間バッチ並列処理ジョブ管理 | JSON | Azure SDK |
| SI-4 | Azure Service Bus | — | バッチジョブキュー | JSON | AMQP |
| SI-5 | Azure Blob Storage | — | バッチ中間ファイル・工場向けファイル保存 | Binary | Azure SDK |
| SI-6 | Azure Cognitive Search | — | EC サイト商品検索（テナント別インデックス） | JSON | REST / HTTPS |
| SI-7 | Azure Cache for Redis | — | EC サイトセッション・カートデータキャッシュ | Binary | Redis Protocol |
| SI-8 | Stripe | 2024-09-30 | EC 消費者決済 + SaaS サブスクリプション課金 | JSON | REST / HTTPS |
| SI-9 | SFTP（工場） | SSH v2 | 工場ごとの CSV ファイル転送 | Binary | SFTP |
| SI-10 | Azure Monitor | — | バッチ処理状況・テナント別ログ・メトリクス収集 | JSON | Azure SDK |
| SI-11 | Azure Key Vault | — | テナント別接続文字列・SFTP 認証キー管理 | — | Azure SDK |
| SI-12 | 工場 Webhook / メール | — | ファイル転送完了通知（ShopHub→工場） | JSON / テキスト | HTTPS / SMTP |
| SI-13 | 工場システム（Inbound Webhook） | — | 工場からの出荷完了通知受信（HMAC-SHA256 署名） | JSON | HTTPS POST |
| SI-14 | Azure Communication Services / SendGrid | — | 消費者への発送通知メール送信 | HTML / テキスト | SMTP / REST |

### 5.3 Hardware Interfaces

本システムにハードウェアインターフェースはない。すべてクラウドサービスとして提供する。

### 5.4 Communications Interfaces

- **全通信**: TLS 1.3 以上で暗号化する。
- **SFTP 通信**: SSH v2 + SSH キー認証（パスワード認証禁止）。
- **テナント間通信**: 存在しない。テナントは完全に独立して動作する。
- **Webhook（送信）**: Stripe からの課金イベント通知・工場システムへの転送完了通知に使用する。
- **Webhook（受信）**: 工場システムからの出荷完了通知受信に使用する。HMAC-SHA256 署名で認証する。

---

## 6. Quality Attributes

詳細は [non-functional/NFR.md](non-functional/NFR.md) を参照。

### 6.1 品質属性優先順位

1. **セキュリティ** - テナント間データ漏洩・バッチデータ混入防止
2. **可用性** - SLA 99.9%・バッチ処理の継続性
3. **スループット（バッチ）** - 1,000 万件/日（全テナント合計）をキュー駆動で継続処理
4. **スケーラビリティ** - テナント数・バッチノード数の動的スケール
5. **パフォーマンス** - EC サイトのユーザー体験

### 6.2 Security

- テナント分離: Entra ID テナント単位の JWT `iss` クレーム検証・DB 分離・バッチジョブ分離
- SFTP: SSH キー認証・鍵は Azure Key Vault で管理
- PGP 暗号化: 工場マスタの設定で有効化（鍵は Azure Key Vault で管理）

### 6.3 Availability

- SLA: 99.9%（月次ダウンタイム ≤ 43.8 分）。
- RTO ≤ 1 時間、RPO ≤ 5 分。

### 6.4 バッチ処理性能

- NFR-BATCH-01: 注文確定からバッチ生成（最大遅延: TimeFlush 30 分 + 処理時間）までを 60 分以内に完了
- NFR-BATCH-02: テナントあたり最大 100 万件/日に対応（100 テナント想定）
- NFR-BATCH-03: Azure Batch ノード数でキュー深度に応じた動的スケール

### 6.5 工場データ連携性能

- NFR-FACTORY-01: ファイル転送完了率 99.9%（月次）
- NFR-FACTORY-02: SFTP 転送速度 ≥ 10MB/s
- NFR-FACTORY-03: ファイル生成から転送完了まで 30 分以内
- NFR-FACTORY-04: 出荷完了通知受信から注文ステータス更新完了まで 5 秒以内
- NFR-FACTORY-05: 消費者発送通知メール送信完了まで通知受信から 1 分以内
- NFR-FACTORY-06: 出荷完了通知エンドポイント可用性 99.9% 以上

### 6.6 EC サイト性能

- API レスポンスタイム（P95） ≤ 200ms
- ピーク時 10,000 req/sec に対応（Azure Front Door + Auto Scaling）

### 6.7 Scalability

- テナント数 200 以上に対応
- バッチ処理ノード数の動的スケールで注文数増加に対応

### 6.8 Maintainability

- バッチ処理の手動再実行機能を提供する（テナント・日付指定）
- フォーマット定義の管理画面から変更可能にする
- テナント別ログを Azure Monitor でフィルタリングできること

---

## Appendix A: テナント分離モデルの比較検討

| モデル | 説明 | 隔離度 | コスト | 採用判断 |
|-------|------|-------|-------|---------|
| Silo（専有） | テナントごとに全リソースを分離 | 最高 | 高 | インフラコスト削減目標（BO-1）を達成できないため不採用 |
| **Bridge（DB 分離）** | **共有アプリ + テナント別 Entra ID + テナント別 DB** | **高** | **中** | **Release 1 採用** |
| Pool（共有） | 全テナントが同一 DB を共有（tenant_id で分離） | 低〜中 | 低 | Release 2 以降の廉価プラン向けに検討 |

---

## Appendix B: テナントプロビジョニングフロー

```
テナント管理者が登録フォームを送信
    │
    ▼
[1] メールアドレス確認
    │
    ▼
[2] Platform DB にテナントレコード作成（status = provisioning）
    │
    ▼
[3] Microsoft Graph API: Entra ID テナント自動作成
    │
    ▼
[4] Azure AD External Identities（CIAM）設定・管理サイト OIDC アプリ登録
    │
    ▼
[5] Azure Database for PostgreSQL: テナント専用 DB 作成・スキーマ初期化
    │
    ▼
[6] Azure Blob Storage: テナント専用コンテナ作成
    │
    ▼
[7] Azure Front Door: カスタムドメイン設定
    │
    ▼
[8] Azure Key Vault: 接続文字列・API キーを登録
    │
    ▼
[9] Stripe: トライアルサブスクリプション作成
    │
    ▼
[10] Platform DB: status = active に更新
    │
    ▼
[11] 管理者にオンボーディング完了メールを送信
```

---

## Appendix C: 注文キュー駆動バッチ処理フロー（概要）

```
消費者が注文受付（EC サイト）
    │ Stripe オーソリ完了 → 注文ステータス: pending
    │ factory_order_data テーブルに工場送信用データ作成
    │ cancellation_cutoff_at 設定
    ▼
キャンセル期限スケジューラー（1 分ごとに pending 注文をチェック）
    │ cancellation_cutoff_at 到達 → 注文ステータス: pending → locked
    ▼
Batch.Enqueue: order-batch-queue に注文イベント投入（自動・locked 遷移時）
    │ メッセージ: { tenant_id, order_id, status: "locked", locked_at, enqueued_at }
    ▼
Azure Batch Pool（常時稼働ワーカー）がキューをポーリング
    │ (tenant_id, factory_id) 単位で集約バッファに追加
    │
    ├─ SizeFlush（1,000 件達成）または TimeFlush（30 分経過）で発動
    │
    ▼
フラッシュ発動 → バッチ処理開始
    │
    ├─ テナント A / 工場 A: factory_order_data 抽出 → CSV 変換 → Blob 保存 → factory-transfer-queue 投入
    ├─ テナント A / 工場 B: （独立して同様に処理）
    └─ テナント B / 工場 X: （独立して同様に処理）
    │
    ▼
FR-021（工場データ連携）が factory-transfer-queue から転送ジョブを受け取り
    │ SFTP/Blob 転送 → 転送完了通知（Webhook/メール）
    ▼
Batch.Capture: 転送完了通知を受信
    │ → Stripe PaymentIntent キャプチャ（決済確定）
    │ → 注文ステータス: locked → confirmed
    │ → 消費者に注文確定メール送信
    ▼
Azure Monitor にキュー深度・処理状況を随時送信
    │
    失敗の場合 ──→ 3 回自動リトライ ──→ Dead Letter キュー ──→ アラート発報
```

---

## Appendix D: TBD 一覧

| TBD-ID | 内容 | 担当者 | 期限 | ステータス |
|-------|------|-------|------|---------|
| TBD-SRS-01 | テナント DB のインスタンスサイズ（Flexible Server SKU）の決定 | Architect | 2026-04-30 | Open |
| TBD-SRS-02 | Azure Batch Pool のノード数・VM サイズの最終決定（負荷テスト後） | Architect | 2026-10-31 | Open |
| TBD-SRS-03 | 工場 SFTP サーバーへの接続要件詳細（工場ごとのヒアリング結果） | BA | 2026-04-30 | Open |
| TBD-SRS-04 | 工場出荷完了通知のメール送信サービス選定（Azure Communication Services vs SendGrid） | Architect | 2026-04-30 | Open |
| TBD-SRS-05 | 管理サイトへのリアルタイム反映の実装方式（WebSocket vs SSE）の最終決定 | Architect | 2026-05-31 | Open |

---

## 変更履歴

| バージョン | 日付 | 変更者 | 変更内容 |
|---------|------|-------|---------|
| 1.0 draft 1 | 2026-03-08 | 佐藤 花子 | 初版作成（ShopHub SaaS EC + Entra ID + 夜間バッチ + 工場連携ユースケースに合わせて全面作成） |
| 1.0 approved | 2026-03-08 | 山田 太郎 | 承認 |
| 1.1 draft 1 | 2026-03-09 | 佐藤 花子 | FR-022（工場出荷完了通知受信）を追加。3.8節・SI-13/SI-14・NFR-FACTORY-04〜06・データモデル（order_shipping_info・ship_notify_logs）・TBD-SRS-04/05 を追記 |
| 1.1 approved | 2026-03-09 | 山田 太郎 | 承認 |
| 1.2 draft 1 | 2026-03-09 | 佐藤 花子 | FR-020 アーキテクチャ変更に伴い Section 3.6・Appendix C を更新。「22:00 固定スケジュール」→「常時キュー駆動バッチ（SizeFlush/TimeFlush）」に改訂。Azure Service Bus キュー構成（order-batch-queue・factory-transfer-queue）を明記。NFR-BATCH-01 を更新 |
| 1.2 approved | 2026-03-09 | 山田 太郎 | 承認 |
| 1.3 draft 1 | 2026-03-09 | 佐藤 花子 | 注文ライフサイクル変更: Section 4.2 orders テーブルを更新（status ENUM に `locked`/`capture_failed` 追加、`cancellation_cutoff_at`/`locked_at`/`stripe_capture_status` カラム追加）。Section 4.2b `factory_order_data` テーブル新設。Stripe オーソリ→pending→locked→確定（captured）フローを反映 |
| 1.3 approved | 2026-03-09 | 山田 太郎 | 承認 |
