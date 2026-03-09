# Software Requirements Specification (SRS)
## TaskBoard SaaS ─ Azure マルチテナント プロジェクト管理 SaaS, Release 1.0

> **参考**: Karl Wiegers "Software Requirements 3rd Edition" Chapter 10

## ドキュメント情報

| 項目 | 内容 |
|------|------|
| プロダクト名 | TaskBoard SaaS |
| リリース | Release 1.0 |
| バージョン | 1.0 approved |
| 作成日 | 2026-01-20 |
| 最終更新日 | 2026-03-01 |
| ステータス | Approved |
| 作成者 | 佐藤 花子（BA）、田中 誠（Architect） |
| 承認者 | 山田 太郎（PM） |

---

## 1. Introduction

### 1.1 Purpose

本 SRS は TaskBoard SaaS Release 1.0 のソフトウェア機能要件・非機能要件を定義する。設計・実装・テスト・保守を担当するプロジェクトチームが使用する。特に断りのない限り、すべての要件は Release 1.0 にコミットされている。

### 1.2 Document Conventions

#### 要件 ID 規約（階層テキストタグ形式）

```
Feature.SubFeature: 機能グループの説明
.Item:              個別要件（"システムは〜しなければならない" で記述）
```

例:
```
Tenant.Provision:   テナントプロビジョニング
.Create:            システムはテナントを作成しなければならない
.DB:                システムはテナント専用 PostgreSQL データベースを作成しなければならない
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

本プロジェクトは Azure 上のマルチテナント SaaS プラットフォームを構築し、複数の企業（テナント）が同一アプリケーション基盤を共有しながらデータを完全に隔離して利用できるようにする。

参照: [vision-and-scope.md](vision-and-scope.md)

### 1.4 References

| 文書名 | バージョン | 場所 |
|-------|---------|------|
| Vision & Scope Document | 1.0 | `docs/requirements/multitenant/vision-and-scope.md` |
| 機能一覧 | 1.0 | `docs/requirements/multitenant/functional/functional-list.md` |
| 機能要件: テナント管理 | 1.0 | `docs/requirements/multitenant/functional/FR-010-テナント管理.md` |
| 機能要件: テナントデータ分離 | 1.0 | `docs/requirements/multitenant/functional/FR-011-テナントデータ分離.md` |
| 非機能要件 | 1.0 | `docs/requirements/multitenant/non-functional/NFR.md` |
| 業務ルールカタログ | 1.0 | `docs/requirements/multitenant/business-rules-catalog.md` |
| Microsoft Azure マルチテナントアーキテクチャガイド | — | https://learn.microsoft.com/ja-jp/azure/architecture/guide/multitenant/overview |

---

## 2. Overall Description

### 2.1 Product Perspective

TaskBoard SaaS はシングルテナント版 TaskBoard の後継として、複数企業が共通の Azure インフラを利用するマルチテナント SaaS プラットフォームへ転換する。

**テナント分離モデル**: **Bridge モデル（共有アプリ + テナント別 DB）**

```
┌─────────────────────────────────────────────────┐
│ 共有レイヤー（Azure App Service / Container Apps） │
│  React フロントエンド  │  FastAPI アプリケーション  │
└────────────────┬────────────────────────────────┘
                 │ テナント ID でルーティング
    ┌────────────┼────────────┐
    ▼            ▼            ▼
┌────────┐  ┌────────┐  ┌────────┐
│ DB     │  │ DB     │  │ DB     │
│ (A社)  │  │ (B社)  │  │ (C社)  │
│ PostgreSQL │ │ PostgreSQL │ │ PostgreSQL │
└────────┘  └────────┘  └────────┘
```

外部エンティティ（コンテキスト図）:
- **Stripe**: サブスクリプション課金・請求書発行
- **Azure AD / Azure AD B2C**: テナント別 SSO・ユーザー認証
- **Azure API Management**: テナントルーティング・レート制限・API キー管理
- **SendGrid**: メール通知（オンボーディング・請求書・アラート）
- **Azure Monitor**: テナント別ログ・メトリクス収集

### 2.2 User Classes and Characteristics

| ユーザークラス | 説明 | 利用頻度 | 技術レベル | 優先度 |
|-------------|------|---------|---------|-------|
| **プラットフォーム管理者**（Platform Admin） | SaaS 事業者のインフラ・運用担当者。全テナントを管理する。約 3 名。 | 日次 | 高 | Favored |
| **テナント管理者**（Tenant Admin） | 契約企業の IT 担当者。ユーザー管理・SSO 設定・課金を担当。テナントあたり 1〜3 名。 | 週次 | 中〜高 | Favored |
| **プロジェクトマネージャー** | テナント内のプロジェクト作成・メンバー管理・進捗確認。 | 日次 | 中 | Favored |
| **開発者 / 一般メンバー** | タスク更新・コメント・ステータス変更。テナントあたり 5〜500 名。 | 日次 | 低〜中 | Favored |
| **閲覧者**（Viewer） | 進捗確認のみ。更新権限なし。 | 随時 | 低 | — |

### 2.3 Operating Environment

| 項目 | 内容 |
|------|------|
| クラウド | Microsoft Azure（Japan East リージョン） |
| アプリケーション | Azure App Service（Standard S2 / Premium P2v3） |
| データベース | Azure Database for PostgreSQL Flexible Server（テナントごとに 1 インスタンス） |
| 認証 | Azure AD マルチテナント + Azure AD B2C |
| API ゲートウェイ | Azure API Management（Developer / Standard ティア） |
| ストレージ | Azure Blob Storage（テナントごとにコンテナ分離） |
| 監視 | Azure Monitor + Application Insights |
| クライアント | Chrome / Firefox / Edge / Safari（最新 2 バージョン）。レスポンシブ対応（デスクトップ・タブレット） |

### 2.4 Design and Implementation Constraints

| ID | 制約 | 理由 |
|----|------|------|
| CO-1 | テナント識別子はすべての API リクエスト・DB クエリで検証しなければならない | テナント間データ漏洩を防止するため |
| CO-2 | テナントデータは論理的にも物理的にも他テナントから隔離しなければならない（Bridge モデル） | セキュリティ審査要件 |
| CO-3 | フロントエンド: React (TypeScript)、バックエンド: FastAPI (Python)、DB: PostgreSQL 15 以上 | 既存開発資産の継承 |
| CO-4 | すべての通信は TLS 1.3 以上で暗号化しなければならない | セキュリティポリシー |
| CO-5 | テナントのデータは日本国内 Azure リージョン（Japan East / Japan West）のみに保存しなければならない | 個人情報保護法・顧客要件 |
| CO-6 | 各 API エンドポイントにテナントコンテキスト検証ミドルウェアを適用しなければならない | 横断的な分離保証 |

### 2.5 Assumptions and Dependencies

- AS-1: テナントは Azure AD テナントまたは SAML 2.0 対応 IdP を保有している（Release 1: Azure AD のみ対応）。
- AS-2: テナントあたりのユーザー数の上限は 1,000 名とする。
- DE-1: Stripe API を利用した課金処理が正常に動作することに依存する。
- DE-2: Azure AD マルチテナントアプリケーションの登録が完了していることに依存する。

---

## 3. System Features

### 3.1 テナント管理（FE-1）

**説明**: プラットフォーム管理者およびテナント管理者がテナントのライフサイクルを管理する。Priority = **Must**。

**機能要件**: 詳細は [FR-010-テナント管理.md](functional/FR-010-テナント管理.md) を参照。

主要要件サマリー:
- Tenant.Provision: テナント登録時に DB・ストレージ・API キーを自動プロビジョニングする
- Tenant.Config: テナント設定（ドメイン・SSO・機能フラグ）を管理する
- Tenant.Suspend: テナントの一時停止・再開・削除を管理する
- Tenant.Plan: サブスクリプションプランの変更・ダウングレード・解約を管理する

### 3.2 テナントデータ分離（FE-2）

**説明**: テナントごとに PostgreSQL データベースを分離し、他テナントのデータへのアクセスを物理的・論理的に防止する。Priority = **Must**。

**機能要件**: 詳細は [FR-011-テナントデータ分離.md](functional/FR-011-テナントデータ分離.md) を参照。

### 3.3 テナント認証・SSO（FE-3）

**説明**: テナントごとに Azure AD SSO または独自 IdP を設定し、シングルサインオンを実現する。Priority = **Must**。

**機能要件**:

**Auth.Login: ログイン処理**

**.Email**: システムは、メールアドレスとパスワードによるログインをサポートしなければならない。

**.SSO**: システムは、テナント設定に Azure AD アプリ登録が存在する場合、Azure AD SSO によるログインをサポートしなければならない。

**.TenantRouting**: システムは、ログイン時のドメインまたはサブドメインからテナントを識別し、適切なテナントコンテキストでセッションを確立しなければならない。

**.Session**: システムは、JWT（有効期限 1 時間）とリフレッシュトークン（有効期限 30 日）を発行しなければならない。（BR-MT-20 参照）

**.IsolatedSession**: システムは、セッションが他テナントのリソースにアクセスできないことを保証しなければならない。

### 3.4 セルフサービスオンボーディング（FE-4）

**説明**: テナント管理者がプラットフォーム管理者の介入なしに、Web フォームからテナント登録・設定・ユーザー招待まで完結できる。Priority = **Must**。

**機能要件**:

**Onboard.Register: テナント登録**

**.Form**: システムは、企業名・管理者メールアドレス・パスワード・プラン選択を入力するサインアップフォームを提供しなければならない。

**.Verify**: システムは、登録後に管理者メールアドレスへ確認メールを送信し、リンクのクリックをもって登録を完了しなければならない。

**.Provision**: メール確認完了後、システムは 3 分以内にテナント用データベース・ストレージ・API キーを自動プロビジョニングしなければならない。（BR-MT-01 参照）

**.Trial**: システムは、登録後 14 日間の無料トライアルを自動で付与しなければならない。（BR-MT-30 参照）

**Onboard.InviteUser: ユーザー招待**

**.Invite**: テナント管理者は、メールアドレスを指定してユーザーをテナントに招待できなければならない。

**.Role**: 招待時にロール（テナント管理者 / PM / 開発者 / 閲覧者）を指定できなければならない。

**.Accept**: 招待されたユーザーが 7 日以内に招待リンクを承認することで、テナントメンバーとして登録されなければならない。（BR-MT-25 参照）

### 3.5 サブスクリプション・課金管理（FE-5）

**説明**: Stripe と連携してプラン選択・クレジットカード決済・請求書発行を管理する。Priority = **Must**。

**機能要件**:

**Billing.Plan: プラン管理**

**.Select**: テナント管理者は、Starter / Professional / Enterprise の 3 プランから選択できなければならない。（BR-MT-31 参照）

**.Upgrade**: テナント管理者はプランをアップグレードでき、差額は日割り計算されなければならない。

**.Downgrade**: テナント管理者はプランをダウングレードでき、次の課金サイクル開始時に適用されなければならない。

**Billing.Payment: 決済処理**

**.Card**: システムは Stripe を介してクレジットカード情報を登録・更新できなければならない。カード番号はシステム内に保存してはならない。（BR-MT-32 参照）

**.Invoice**: システムは月次で請求書を自動生成し、テナント管理者にメール送信しなければならない。

**.Failed**: 決済が失敗した場合、システムは 3 日間・3 回リトライし、最終失敗時にテナントを「支払い停止」状態に移行しなければならない。（BR-MT-33 参照）

---

## 4. Data Requirements

### 4.1 Logical Data Model（マルチテナント）

```
┌─────────────────┐       ┌─────────────────────────┐
│ Platform DB     │       │ Tenant DB（テナントごと） │
│─────────────────│       │─────────────────────────│
│ tenants         │  1:1  │ users                   │
│  tenant_id PK   │──────▶│  user_id PK             │
│  name           │       │  tenant_id FK           │
│  subdomain      │       │  email                  │
│  plan_id FK     │       │  role                   │
│  status         │       │  created_at             │
│  db_connection  │       │                         │
│  created_at     │       │ projects                │
│                 │       │  project_id PK          │
│ plans           │       │  name                   │
│  plan_id PK     │       │  created_by FK          │
│  name           │       │                         │
│  max_users      │       │ tasks                   │
│  max_projects   │       │  task_id PK             │
│  price_monthly  │       │  project_id FK          │
│                 │       │  title                  │
│ subscriptions   │       │  assignee_id FK         │
│  subscription_id│       │  status                 │
│  tenant_id FK   │       │  due_date               │
│  plan_id FK     │       │  created_at             │
│  stripe_sub_id  │       └─────────────────────────┘
│  status         │
│  trial_ends_at  │
└─────────────────┘
```

**分離方式**: Platform DB（全テナント共通のメタデータ）と Tenant DB（テナントごとの業務データ）を物理的に分離する。

### 4.2 Data Dictionary（主要エンティティ）

| エンティティ | フィールド | 型 | 制約 | 説明 |
|-----------|---------|----|----|------|
| tenants | tenant_id | UUID | PK, NOT NULL | テナント一意識別子 |
| tenants | subdomain | VARCHAR(63) | UNIQUE, NOT NULL | `{subdomain}.taskboard.jp` 用サブドメイン（BR-MT-10 参照） |
| tenants | status | ENUM | NOT NULL | active / suspended / trial / cancelled |
| tenants | db_connection | VARCHAR(500) | ENCRYPTED, NOT NULL | テナント DB 接続文字列（Azure Key Vault 参照） |
| subscriptions | stripe_sub_id | VARCHAR(255) | UNIQUE | Stripe のサブスクリプション ID |
| subscriptions | trial_ends_at | TIMESTAMP | NULL 可 | トライアル終了日時 |

### 4.3 Data Integrity, Retention, and Disposal

- **整合性**: テナント DB への接続は Platform DB の `db_connection` を経由し、直接アクセスは禁止する。アプリケーション層でテナント ID の一致を検証する。
- **保持**: テナントデータはサービス解約後 90 日間保持し、その後物理削除する。（BR-MT-40 参照）
- **廃棄**: テナント削除時に DB インスタンスを削除し、Blob ストレージコンテナを完全消去する。削除ログを監査証跡として 7 年間保持する。
- **エクスポート**: 解約前にテナント管理者は全データを JSON/CSV でエクスポートできる。（FE-9 参照）

---

## 5. External Interface Requirements

### 5.1 User Interfaces

- Azure Front Door 経由で `https://{tenant}.taskboard.jp` にアクセスする。
- テナント別ブランディング（ロゴ・プライマリカラー）を適用する。（Release 2 以降）
- 対応ブラウザ: Chrome / Firefox / Edge / Safari（最新 2 バージョン）。
- レスポンシブ対応: デスクトップ（1920px〜）・タブレット（768px〜）。

### 5.2 Software Interfaces

| IF-ID | 接続先 | バージョン | 目的 | データ形式 | プロトコル |
|-------|-------|---------|------|---------|---------|
| SI-1 | Azure AD | v2.0 | テナント SSO・ユーザー認証 | JWT | OAuth 2.0 / OIDC |
| SI-2 | Azure AD B2C | — | セルフサービスサインアップ | JWT | OAuth 2.0 |
| SI-3 | Stripe | 2024-09-30 | 課金・サブスクリプション管理 | JSON | REST / HTTPS |
| SI-4 | SendGrid | v3 | トランザクションメール送信 | JSON | REST / HTTPS |
| SI-5 | Azure API Management | — | テナントルーティング・レート制限 | — | HTTPS |
| SI-6 | Azure Monitor | — | ログ・メトリクス収集 | JSON | Azure SDK |
| SI-7 | Azure Key Vault | — | テナント別接続文字列・シークレット管理 | — | Azure SDK |

### 5.3 Hardware Interfaces

本システムにハードウェアインターフェースはない。すべてクラウドサービスとして提供する。

### 5.4 Communications Interfaces

- **全通信**: TLS 1.3 以上で暗号化する。
- **テナント間通信**: 存在しない。テナントは完全に独立して動作する。
- **Webhook**: Stripe からの課金イベント通知を受け取るための Webhook エンドポイントを公開する。署名検証必須（BR-MT-35 参照）。

---

## 6. Quality Attributes

詳細は [non-functional/NFR.md](non-functional/NFR.md) を参照。

### 6.1 Usability

- テナント管理者が初回設定を 10 分以内に完了できること。
- エンドユーザーはシングルテナント版から操作方法の変更を意識せずに移行できること。

### 6.2 Performance

| 指標 | 要件値 | 備考 |
|------|-------|------|
| API レスポンスタイム（95%ile） | ≤ 300ms | テナント DB ルーティング込み |
| テナントプロビジョニング時間 | ≤ 3 分 | サインアップ完了から利用開始まで |
| 同時接続テナント数 | ≥ 100 テナント | Release 1 の目標 |

### 6.3 Security

- テナント分離: テナント A のユーザーがテナント B のデータにアクセスできないこと（ペネトレーションテストで検証）。
- すべての API エンドポイントでテナントコンテキスト検証を実施すること。
- テナント接続文字列は Azure Key Vault に保存し、アプリケーションコード・ログに出力しないこと。

### 6.4 Availability

- SLA: 99.9%（月次ダウンタイム ≤ 43.8 分）。
- RTO ≤ 1 時間、RPO ≤ 5 分。

### 6.5 Scalability

- テナント数が増加してもアプリケーション層は Auto Scaling で対応する（CPU 70% 閾値）。
- テナント DB は独立しているため、特定テナントの高負荷が他テナントに影響しない。

### 6.6 Maintainability

- テナントプロビジョニング・解約はスクリプトで自動化し、手動手順を排除する。
- テナント別ログを Application Insights でフィルタリングできること。

---

## Appendix A: テナント分離モデルの比較検討

| モデル | 説明 | 隔離度 | コスト | 採用判断 |
|-------|------|-------|-------|---------|
| Silo（専有） | テナントごとに全リソースを分離 | 最高 | 高 | インフラコスト削減目標（BO-1）を達成できないため不採用 |
| **Bridge（DB 分離）** | **共有アプリ + テナント別 DB** | **高** | **中** | **Release 1 採用** |
| Pool（共有） | 全テナントが同一 DB を共有（tenant_id で分離） | 低〜中 | 低 | Release 2 以降の廉価プラン向けに検討 |

---

## Appendix B: テナントプロビジョニングフロー

```
ユーザー入力
    │
    ▼
[1] メールアドレス確認
    │
    ▼
[2] Platform DB にテナントレコード作成（status = provisioning）
    │
    ▼
[3] Azure Database for PostgreSQL: テナント専用 DB 作成
    │
    ▼
[4] スキーマ初期化（マイグレーション実行）
    │
    ▼
[5] Azure Blob Storage: テナント専用コンテナ作成
    │
    ▼
[6] Azure Key Vault: 接続文字列・API キーを登録
    │
    ▼
[7] Platform DB: status = active に更新
    │
    ▼
[8] Stripe: トライアルサブスクリプション作成
    │
    ▼
[9] 管理者にオンボーディング完了メールを送信
```

---

## Appendix C: TBD 一覧

| TBD-ID | 内容 | 担当者 | 期限 | ステータス |
|-------|------|-------|------|---------|
| TBD-SRS-01 | テナント DB のインスタンスサイズ（Flexible Server SKU）の決定 | Architect | 2026-02-28 | Resolved: Burstable B2ms |
| TBD-SRS-02 | Pool モデル対応（廉価プラン向け）の Release 2 仕様の確認 | PM/BA | 2026-04-30 | Open |

---

## 変更履歴

| バージョン | 日付 | 変更者 | 変更内容 |
|---------|------|-------|---------|
| 1.0 draft 1 | 2026-01-20 | 佐藤 花子 | 初版作成 |
| 1.0 approved | 2026-03-01 | 佐藤 花子 | セキュリティ・法務レビュー指摘対応後ベースライン化 |
