# トレーサビリティマトリクス
## TaskBoard SaaS ─ Azure マルチテナント

> **参考**: Karl Wiegers "Software Requirements 3rd Edition" Chapter 16 "Requirements Traceability"
>
> トレーサビリティは要件の出所（上流）と実装・テスト（下流）の双方向の追跡を可能にする。変更影響分析（Change Impact Analysis）の基盤として機能する。

## ドキュメント情報

| 項目 | 内容 |
|------|------|
| プロダクト名 | TaskBoard SaaS |
| バージョン | 1.0 approved |
| 作成日 | 2026-02-15 |
| 最終更新日 | 2026-03-01 |
| ステータス | Approved |
| 作成者 | 田中 誠（Architect） |

---

## 1. ビジネス目標 → 機能要件 マトリクス（上流トレーサビリティ）

| BO-ID | ビジネス目標 | FR-010 テナント管理 | FR-011 テナントデータ分離 |
|-------|------------|-------------------|----------------------|
| BO-1 | インフラコスト削減（Bridge モデル採用） | Tenant.Provision（共有 App Service） | Isolation.Database（DB 分離） |
| BO-2 | ARR 3,000 万円達成（2026 年度） | Tenant.Config（プラン管理）<br>Tenant.Lifecycle（課金連携） | — |
| BO-3 | オンボーディング 10 分以内 | Tenant.Provision（自動プロビジョニング）<br>Tenant.Onboard | Isolation.Routing（テナントルーティング） |

---

## 2. 機能要件 → ユースケース → ユーザーストーリー マトリクス（下流トレーサビリティ）

### 2.1 FR-010 テナント管理

| FR-ID | 機能要件 | UC | ユースケース名 | US | ユーザーストーリー名 |
|-------|---------|----|--------------|----|------------------|
| Tenant.Provision | テナント専用 PostgreSQL DB を自動作成する | UC-010 | テナントをオンボーディングする | US-010 | テナントを登録する |
| Tenant.Provision | Key Vault に接続文字列を登録する | UC-010 | テナントをオンボーディングする | US-010 | テナントを登録する |
| Tenant.Provision | Blob Storage コンテナを作成する | UC-010 | テナントをオンボーディングする | US-010 | テナントを登録する |
| Tenant.Provision | Stripe トライアルサブスクリプションを作成する | UC-010 | テナントをオンボーディングする | US-010 | テナントを登録する |
| Tenant.Config | プランに基づいてユーザー上限・ストレージ上限を設定する | — | — | — | — |
| Tenant.Lifecycle | 解約後 90 日データ保持→物理削除する | — | — | — | — |
| Tenant.UserManagement | テナントへの招待リンクを管理する（7 日有効） | — | — | — | — |

### 2.2 FR-011 テナントデータ分離

| FR-ID | 機能要件 | UC | ユースケース名 | US | ユーザーストーリー名 |
|-------|---------|----|--------------|----|------------------|
| Isolation.Routing | サブドメインから tenant_id を抽出し X-Tenant-ID ヘッダーを付与する | UC-011 | テナントリソースにアクセスする | US-011 | テナントデータが他テナントから隔離されていることを確認する |
| Isolation.Database | JWT の tenant_id と X-Tenant-ID の一致を検証する | UC-011 | テナントリソースにアクセスする | US-011 | テナントデータが他テナントから隔離されていることを確認する |
| Isolation.Database | テナント専用 DB 接続プールを使用する | UC-011 | テナントリソースにアクセスする | US-011 | テナントデータが他テナントから隔離されていることを確認する |
| Isolation.Storage | SAS トークン（有効期限 ≤ 1 時間）を使用する | UC-011 | テナントリソースにアクセスする | US-011 | テナントデータが他テナントから隔離されていることを確認する |
| Isolation.API | テナント分離違反を HTTP 403 で拒否する | UC-011 | テナントリソースにアクセスする | US-011 | テナントデータが他テナントから隔離されていることを確認する |
| Isolation.Audit | セキュリティインシデントを Azure Monitor に記録する | UC-011 | テナントリソースにアクセスする | US-011 | テナントデータが他テナントから隔離されていることを確認する |

---

## 3. ユーザーストーリー → 受入基準 → テスト マトリクス

### 3.1 US-010: テナントを登録する

| AC-ID | 受入基準 | テスト種別 | テストケース概要 |
|-------|---------|----------|--------------|
| AC-001 | フォーム入力後に確認メールが送信される | E2E | サインアップフォームを入力し、確認メール受信を検証 |
| AC-002 | メール確認後 3 分以内に Azure リソースが作成される | E2E / 統合 | メール確認リンク押下→PostgreSQL DB 作成・Blob コンテナ・Key Vault 登録を確認 |
| AC-003 | オンボーディング全体が 10 分以内に完了する | 性能テスト | フォーム開始〜ダッシュボードログインまでのレスポンスタイム測定 |
| AC-004 | 重複サブドメインはエラーになる | 単体 / E2E | 既存サブドメインと同一の値を入力し、エラーメッセージと代替候補を確認 |
| AC-005 | 予約済みサブドメインはエラーになる | 単体 | `admin`, `www` 等を入力し、使用不可エラーを確認 |
| AC-006 | プロビジョニング失敗時にロールバックされる | 統合 | DB 作成をモックで失敗させ、作成済みリソース削除とアラート送信を確認 |
| AC-007 | トライアル残り 3 日でリマインドメールが届く | 単体 / スケジューラ | 日次バッチを手動実行し、対象テナントへのメール送信を確認 |

### 3.2 US-011: テナントデータが他テナントから隔離されていることを確認する

| AC-ID | 受入基準 | テスト種別 | テストケース概要 |
|-------|---------|----------|--------------|
| AC-001 | テナント A の JWT でテナント B の API にアクセスすると HTTP 403 | セキュリティ / E2E | 2 テナント作成→テナント A の JWT でテナント B のエンドポイントを叩き 403 を確認 |
| AC-002 | テナント A の API レスポンスにテナント B のデータが含まれない | セキュリティ / 統合 | テナント A の JWT でデータ取得し、全件の tenant_id を検証 |
| AC-003 | テナント B の Blob コンテナに直接アクセスできない | セキュリティ | テナント A の SAS でテナント B のコンテナ URL にアクセスし 403/404 を確認 |
| AC-004 | JWT の tenant_id を改ざんしても HTTP 401 | セキュリティ / ペネトレ | 改ざんした JWT を送信し署名検証失敗を確認 |
| AC-005 | テナント A のレート制限超過がテナント B に影響しない | 性能 / E2E | テナント A を 101 req/分 で叩き HTTP 429 を確認、テナント B のレスポンスが正常であることを確認 |
| AC-006 | テナント分離違反時に 5 分以内にアラートが届く | 統合 / 監視 | tenant_id 不一致リクエストを送信し、Azure Monitor アラートの受信を確認 |

---

## 4. 業務ルール → 機能要件 マトリクス

| BR-ID | 分類 | 業務ルール概要 | 関連 FR | 関連 UC | 関連 US |
|-------|------|-------------|--------|--------|--------|
| BR-MT-01 | Fact | 1 テナント = 1 PostgreSQL DB（Bridge モデル） | FR-010 Tenant.Provision | UC-010 | US-010 |
| BR-MT-02 | Constraint | DB 接続文字列は Key Vault 参照 URI のみ保存 | FR-010 Tenant.Provision | UC-010 | US-010 |
| BR-MT-03 | Action Enabler | メール確認後 3 分以内にプロビジョニング完了 | FR-010 Tenant.Provision | UC-010 | US-010 AC-002 |
| BR-MT-04 | Constraint | DB は Azure Private Endpoint 経由のみアクセス | FR-011 Isolation.Database | UC-011 | US-011 |
| BR-MT-05 | Constraint | Blob Storage へのアクセスは SAS トークン（≤ 1h） | FR-011 Isolation.Storage | UC-011 | US-011 AC-003 |
| BR-MT-10 | Constraint | サブドメインは作成後に変更不可 | FR-010 Tenant.Config | UC-010 | US-010 |
| BR-MT-11 | Constraint | 予約済みサブドメインは使用禁止 | FR-010 Tenant.Provision | UC-010 | US-010 AC-005 |
| BR-MT-12 | Inference | プランに基づくアクティブユーザー上限 | FR-010 Tenant.Config | — | — |
| BR-MT-20 | Fact | JWT 有効期限 1 時間 / リフレッシュトークン 30 日 | FR-011 Isolation.API | UC-011 | US-011 |
| BR-MT-21 | Action Enabler | ログイン失敗 5 回でアカウント 30 分ロック | FR-010 Tenant.UserManagement | UC-011 E2 | — |
| BR-MT-23 | Constraint | テナント A はいかなる手段でもテナント B のリソースへアクセス不可 | FR-011（全サブ機能） | UC-011 | US-011 AC-001〜AC-004 |
| BR-MT-30 | Fact | 新規テナントに 14 日間無料トライアル | FR-010 Tenant.Lifecycle | UC-010 | US-010 AC-007 |
| BR-MT-33 | Action Enabler | 課金失敗時リトライ（翌日・3日・7日）→suspended | FR-010 Tenant.Lifecycle | — | — |
| BR-MT-40 | Constraint | 解約後 90 日データ保持→物理削除 | FR-010 Tenant.Lifecycle | — | — |
| BR-MT-41 | Constraint | 監査ログ 2 年保持（Immutable モード） | FR-011 Isolation.Audit | UC-011 | US-011 AC-006 |
| BR-MT-50 | Constraint | プランごとのレート制限（APIM） | FR-011 Isolation.API | UC-011 E1 | US-011 AC-005 |
| BR-MT-51 | Constraint | レート制限はテナント単位で独立 | FR-011 Isolation.API | UC-011 E1 | US-011 AC-005 |

---

## 5. 非機能要件 → 設計・テスト マトリクス

| NFR-ID | 分類 | 要件概要 | 関連 FR | 設計への影響 | テスト種別 |
|--------|------|---------|--------|------------|----------|
| NFR-SEC-01 | セキュリティ | テナントデータ完全分離（ペネトレテスト必須） | FR-011（全サブ機能） | 多層防御（APIM→MW→DB→Storage） | ペネトレーションテスト（外部業者） |
| NFR-SEC-02 | セキュリティ | シークレットは Key Vault のみ | FR-010 Tenant.Provision | Key Vault 参照 URI をコード/環境変数に含めない | セキュリティレビュー / SAST |
| NFR-AVL-01 | 可用性 | SLA 99.9%（月次停止 ≤ 43 分） | FR-010, FR-011 | Azure App Service Premium / 多リージョン展開 | 可用性テスト / SLA モニタリング |
| NFR-AVL-06 | 可用性 | Noisy Neighbor 対策 | FR-011 Isolation.API | APIM テナント別レート制限 | 負荷テスト（複数テナント同時） |
| NFR-PRF-01 | 性能 | API P95 レスポンスタイム ≤ 500ms | FR-011 Isolation.Database | 接続プールキャッシュ / Key Vault 5 分キャッシュ | 負荷テスト |
| NFR-PRF-03 | 性能 | プロビジョニング完了 ≤ 3 分 | FR-010 Tenant.Provision | 非同期バックグラウンドジョブ | E2E テスト（時間測定） |
| NFR-SCL-01 | スケーラビリティ | 同時 500 テナントのリクエスト処理 | FR-011 Isolation.Database | コネクションプール上限設計（テナントあたり 10 接続） | スケーラビリティテスト |
| NFR-SEC-22 | セキュリティ | Key Vault シークレット 90 日自動ローテーション | FR-010 Tenant.Provision | Azure Key Vault ローテーションポリシー設定 | 自動テスト（ローテーション後の接続確認） |

---

## 6. 変更影響分析（Change Impact Analysis）

変更要求が発生した際に本マトリクスを参照し、影響範囲を特定する。

### 6.1 影響分析テンプレート

| 変更 ID | 変更内容 | 変更対象 BR/FR | 影響する UC | 影響する US | 影響する AC | 設計変更 | テスト再実施 |
|--------|---------|-------------|-----------|-----------|-----------|---------|-----------|
| （記入欄） | | | | | | | |

### 6.2 想定変更シナリオと影響範囲

#### シナリオ A: テナント分離モデルを Bridge → Pool に変更（Release 3 計画）

| 影響項目 | 変更内容 |
|---------|---------|
| BR-MT-01 | 「1 テナント = 1 DB」→「共有 DB + Row-Level Security」に改訂 |
| FR-010 Tenant.Provision | DB 作成ステップの削除、RLS ポリシー設定ステップの追加 |
| FR-011 Isolation.Database | テナント DB 接続プール → RLS フィルタ検証ロジックに変更 |
| UC-010 ステップ 8 | 「PostgreSQL DB を作成」→「RLS ポリシーをテナント DB に追加」 |
| US-011 AC-001〜AC-002 | テナント分離テストシナリオの更新（DB レベル分離 → RLS レベル分離） |
| NFR-SEC-01 | ペネトレーションテストに RLS バイパステストを追加 |

#### シナリオ B: Key Vault シークレットローテーション周期を 90 日 → 30 日に短縮

| 影響項目 | 変更内容 |
|---------|---------|
| BR-MT-24 | ローテーション周期 90 日 → 30 日に改訂 |
| NFR-SEC-22 | ローテーション周期の要件値を更新 |
| UC-011 ステップ 6 | Key Vault キャッシュ有効期間（5 分）の妥当性確認 |
| テスト | ローテーション後の接続断なし確認テストの頻度見直し |

#### シナリオ C: API レート制限値の変更（Starter: 100 → 200 req/分）

| 影響項目 | 変更内容 |
|---------|---------|
| BR-MT-50 | Starter プランのレート制限値を改訂 |
| US-011 AC-005 | テストシナリオの 101 件目 → 201 件目に変更 |
| APIM ポリシー設定 | Starter プロダクトポリシーの rate-limit 値変更 |

#### シナリオ D: トライアル期間を 14 日 → 30 日に延長

| 影響項目 | 変更内容 |
|---------|---------|
| BR-MT-30 | トライアル期間 14 日 → 30 日に改訂 |
| UC-010 ステップ 12 | Stripe トライアルサブスクリプションの trial_end 値変更 |
| US-010 AC-007 | 「残り 3 日」リマインドのトリガー日の再検討 |
| Stripe 設定 | デフォルト trial_period_days の変更 |

---

## 7. ドキュメント間リンク

| ドキュメント | パス |
|------------|------|
| Vision & Scope | `docs/requirements/multitenant/vision-and-scope.md` |
| SRS | `docs/requirements/multitenant/SRS.md` |
| FR-010 テナント管理 | `docs/requirements/multitenant/functional/FR-010-テナント管理.md` |
| FR-011 テナントデータ分離 | `docs/requirements/multitenant/functional/FR-011-テナントデータ分離.md` |
| NFR | `docs/requirements/multitenant/non-functional/NFR.md` |
| UC-010 テナントをオンボーディングする | `docs/requirements/multitenant/use-cases/UC-010-テナントをオンボーディングする.md` |
| UC-011 テナントリソースにアクセスする | `docs/requirements/multitenant/use-cases/UC-011-テナントリソースにアクセスする.md` |
| US-010 テナントを登録する | `docs/requirements/multitenant/user-stories/US-010-テナントを登録する.md` |
| US-011 テナントデータが他テナントから隔離されていることを確認する | `docs/requirements/multitenant/user-stories/US-011-テナントデータが他テナントから隔離されていることを確認する.md` |
| 業務ルールカタログ | `docs/requirements/multitenant/business-rules-catalog.md` |

---

## 変更履歴

| バージョン | 日付 | 変更者 | 変更内容 |
|---------|------|-------|------------|
| 1.0 draft 1 | 2026-02-15 | 田中 誠 | 初版作成 |
| 1.0 approved | 2026-03-01 | 田中 誠 | セクション 6（変更影響分析）追加後ベースライン化 |
