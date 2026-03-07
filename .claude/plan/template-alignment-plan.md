# テンプレート整備計画: Software Requirements 3rd Edition 準拠

## Context

現在の要件定義・基本設計テンプレート（SKILL.md）は実用的だが、Karl Wiegers著「Software Requirements 3rd Edition」が推奨する重要なドキュメント体系がカバーされていない。特に以下が欠落している:

- **Vision & Scope Document** (Ch.5) - ビジネス要件の基盤文書
- **SRS の体系的構成** (Ch.10) - データ要件、外部インターフェース、品質属性
- **Business Rules Catalog** (Ch.9) - エンタープライズレベルの資産
- **Context Diagram** - システム境界の可視化
- 要件IDの階層的命名規則 (`AUTH.LOGIN.001` 形式)
- TBD管理の仕組み

既存のPRDテンプレートは残しつつ、書籍に準拠した文書体系を追加する。

---

## 実装ステップ

### Step 1-3: 新規テンプレートファイル作成（並列実行可能）

#### Step 1: Vision & Scope Document

- **ファイル**: `docs/requirements/vision-and-scope.md`
- **内容**: Ch.5準拠
  - 1. Business Requirements (背景/ビジネス機会/ビジネス目標/成功指標/ビジョンステートメント/ビジネスリスク/前提・依存)
  - 1. Scope and Limitations (主要機能/リリース計画/対象外事項)
  - 1. Business Context (ステークホルダー/プロジェクト優先度/デプロイメント)
- ビジョンステートメントはWiegers形式: "For [顧客] Who [ニーズ] The [製品] Is [カテゴリ] That [利点] Unlike [代替] Our product [差別化]"
- Project PrioritiesはConstraints/Drivers/Degrees of Freedom マトリクス

#### Step 2: Business Rules Catalog

- **ファイル**: `docs/requirements/business-rules-catalog.md`
- **内容**: Ch.9準拠
  - ルール種別: Fact / Constraint / Action Enabler / Inference / Computation
  - 各ルールから派生する機能要件へのトレーサビリティ

#### Step 3: Context Diagram

- **ファイル**: `docs/requirements/context-diagram.md`
- **内容**: Mermaidによるコンテキスト図テンプレート + 外部エンティティ一覧表 + エコシステムマップ

### Step 4: SRS テンプレート作成

- **ファイル**: `docs/requirements/SRS.md`
- **依存**: Step 1-3（参照リンク）
- **内容**: Ch.10準拠
  - 1. Introduction (目的/規約/スコープ/参考文献)
  - 1. Overall Description (製品の位置付け/ユーザークラス/動作環境/制約/前提)
  - 1. System Features (機能別に繰り返し: 説明+機能要件)
  - 1. Data Requirements (論理データモデル/データ辞書/レポート/データライフサイクル)
  - 1. External Interface Requirements (UI/ソフトウェア/ハードウェア/通信)
  - 1. Quality Attributes (ユーザビリティ/パフォーマンス/セキュリティ/安全性/可用性/信頼性/スケーラビリティ/保守性)
  - 1. 国際化・ローカリゼーション
  - 1. その他の要件
  - Appendix: 用語集 / 分析モデル / TBD一覧
- 要件IDは階層的テキストタグ推奨: `Feature.SubFeature.Sequence`
- TBD記法: `[TBD-nnn: 説明, 担当者, 期限]`

### Step 5: Requirements SKILL.md 更新

- **ファイル**: `.claude/skills/requirements/SKILL.md`
- 変更内容:
  1. ディレクトリ構成に新ファイル4件を追加
  1. ドキュメント階層の説明追加 (Vision & Scope -> SRS -> FR/UC/US 詳細)
  1. 要件IDの階層的命名規則ガイダンス追加
  1. TBD管理の説明追加
  1. Business Rules への参照追加
  1. トレーサビリティマトリクスに列追加 (Business Rule, V&S Feature)
  1. Context Diagram作成ガイダンス追加
  1. 出力成果物リスト更新

### Step 6-7: Basic Design 拡張（並列実行可能）

#### Step 6: 外部インターフェース設計テンプレート

- `06-external-interface.md` のテンプレート内容をSKILL.mdに追加
- ソフトウェアIF/ハードウェアIF/通信IF/SRSセクション5との対応

#### Step 7: データモデル設計テンプレート

- `07-data-model.md` をディレクトリ構成に追加
- 論理データモデル(Mermaid ER図)/エンティティ一覧/データ量見積もり

### Step 8: Basic Design SKILL.md 更新

- **ファイル**: `.claude/skills/basic-design/SKILL.md`
- 変更内容:
  1. ディレクトリに `07-data-model.md` 追加
  1. `06-external-interface.md` のテンプレート内容追加
  1. `07-data-model.md` のテンプレート内容追加
  1. `00-overview.md` に要件トレーサビリティセクション追加
  1. アーキテクチャ図にContext Diagram参照を追加

### Step 9: PM 成果物一覧更新

- **ファイル**: `docs/pm/requirements-definition-deliverables.md`
- Vision & Scope / SRS / Business Rules Catalog / Context Diagram の4行追加

---

## 変更対象ファイル一覧

| ファイル | 操作 |
| --- | --- |
| `docs/requirements/vision-and-scope.md` | 新規作成 |
| `docs/requirements/business-rules-catalog.md` | 新規作成 |
| `docs/requirements/context-diagram.md` | 新規作成 |
| `docs/requirements/SRS.md` | 新規作成 |
| `.claude/skills/requirements/SKILL.md` | 更新 |
| `.claude/skills/basic-design/SKILL.md` | 更新 |
| `docs/pm/requirements-definition-deliverables.md` | 更新 |

## 設計判断

- **既存PRDテンプレートは維持**: PRDはプロダクトマネジメント視点、Vision & Scopeはソフトウェア工学視点。用途に応じて選択
- **SRS.md + 個別FR/UCファイル併用**: SRSはマスター構成、個別ファイルは詳細。Git管理と並行編集に有利
- **要件ID**: 階層的テキストタグを推奨、FR-XXX も許容（シンプルなプロジェクト向け）
- **Business Rules分離**: 書籍の強い推奨に従い、プロジェクト横断の資産として管理

## 検証方法

1. 各テンプレートファイルが正しいMarkdown構文であることを確認
1. SKILL.mdのディレクトリ構成と実ファイル配置の整合性確認
1. ドキュメント間の参照リンクが正しいことを確認
1. `/requirements` スキルと `/basic-design` スキルを呼び出して、新テンプレートが適切に案内されることを確認
