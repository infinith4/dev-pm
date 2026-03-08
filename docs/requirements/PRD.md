# Product Requirements Document (PRD)

## ドキュメント情報

| 項目 | 内容 |
|------|------|
| プロダクト名 | [プロダクト名] |
| バージョン | 1.0 |
| 作成日 | YYYY-MM-DD |
| 最終更新日 | YYYY-MM-DD |
| ステータス | Draft / Review / Approved |
| 作成者 | [BA/PO氏名] |
| 承認者 | [承認者氏名・役職] |

関連文書:
- Vision & Scope: [vision-and-scope.md](templates/vision-and-scope.md)
- SRS: [SRS.md](SRS.md)
- 非機能要件: [non-functional/NFR.md](templates/non-functional/NFR.md)
- トレーサビリティ: [traceability.md](templates/traceability.md)

---

## 1. プロダクト概要

### 1.1 背景・目的

[このプロダクトを作る背景・解決したい課題・目的を記述する。]

### 1.2 ターゲットユーザー

| ユーザー種別 | 説明 | 主な利用シーン |
|-----------|------|-------------|
| [ユーザー種別1] | [説明] | [利用シーン] |
| [ユーザー種別2] | [説明] | [利用シーン] |

### 1.3 ビジネス目標との対応

| ビジネス目標ID | 内容 | 本PRDでの対応機能 |
|-------------|------|----------------|
| BO-F01 | [目標] | [対応する機能ID] |
| BO-N01 | [目標] | [対応する機能ID] |

---

## 2. 機能要件サマリー

> 詳細は `templates/functional/FR-XXX-*.md` および `templates/use-cases/UC-XXX-*.md` を参照。

| 機能ID | 機能名 | 概要 | 優先度 | 詳細ファイル |
|-------|-------|------|-------|-----------|
| FR-001 | [機能名] | [概要] | Must | [templates/functional/FR-001-機能名.md](templates/functional/FR-001-機能名.md) |
| FR-002 | [機能名] | [概要] | Should | [templates/functional/FR-002-機能名.md](templates/functional/FR-002-機能名.md) |
| FR-003 | [機能名] | [概要] | Could | [templates/functional/FR-003-機能名.md](templates/functional/FR-003-機能名.md) |

優先度定義:
- **Must**: リリースに必須。欠けるとビジネス目標を達成できない
- **Should**: 重要だが必須ではない
- **Could**: あれば望ましい。スケジュール次第で延期可
- **Won't**: 今回のスコープ外

---

## 3. ユーザーストーリーサマリー

> 詳細は `user-stories/US-XXX-*.md` を参照。

| US-ID | ユーザー種別 | ストーリー概要 | 優先度 | 関連FR |
|-------|-----------|-------------|-------|-------|
| US-001 | [種別] | As a [ユーザー], I want to [アクション] so that [価値] | Must | FR-001 |
| US-002 | [種別] | As a [ユーザー], I want to [アクション] so that [価値] | Should | FR-002 |

---

## 4. スコープ

### 4.1 In Scope（対象範囲）

- [含まれる機能・画面・統合先 1]
- [含まれる機能・画面・統合先 2]

### 4.2 Out of Scope（対象外）

- [対象外 1: 理由]
- [対象外 2: 理由]

---

## 5. 制約条件・前提条件

| 区分 | 内容 |
|------|------|
| 技術制約 | [例: フロントエンドは React、バックエンドは FastAPI に限定] |
| 期限制約 | [例: YYYY-MM-DD までにリリース必須] |
| 予算制約 | [例: 開発費用 ¥X万円以内] |
| 前提条件 | [例: 認証基盤は既存のAzure ADを利用] |

---

## 6. 未決事項（TBD）

| TBD-ID | 内容 | 担当者 | 期限 | ステータス |
|-------|------|-------|------|---------|
| TBD-001 | [未確定事項] | [担当者] | YYYY-MM-DD | Open |

---

## 変更履歴

| バージョン | 日付 | 変更者 | 変更内容 |
|---------|------|-------|---------|
| 1.0 | YYYY-MM-DD | [氏名] | 初版作成 |
