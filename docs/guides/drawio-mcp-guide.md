# drawio MCP 利用ガイド

## 概要

drawio MCP は、Claude Code から draw.io（diagrams.net）形式の図を作成・編集できる MCP サーバーである。
自然言語の指示で `.drawio` ファイルを生成でき、設計書やドキュメントに添付する図の作成を効率化する。

## 設定

### MCP サーバー設定

`.claude/mcp.json` に以下の設定が定義済み：

```json
{
  "mcpServers": {
    "drawio": {
      "command": "npx",
      "args": ["-y", "drawio-mcp"]
    }
  }
}
```

### 事前キャッシュ

`.devcontainer/postCreate.sh` で初回起動を高速化するためにキャッシュ済み：

```bash
npx -y drawio-mcp --help 2>/dev/null || true
```

## 提供ツール

drawio MCP が接続されると、`mcp__drawio__` プレフィックスのツールが利用可能になる。

| ツール | 説明 |
|--------|------|
| `create_drawio` | 新しい .drawio ファイルを作成する |
| `edit_drawio` | 既存の .drawio ファイルを編集する |
| `list_diagrams` | プロジェクト内の .drawio ファイルを一覧表示する |

※ ツール名はバージョンにより異なる場合がある。

## 使い方

### 基本的な利用フロー

1. Claude Code のセッションを開始する（MCP サーバーが自動接続される）
2. 自然言語で図の作成を指示する
3. 生成された `.drawio` ファイルを確認する
4. 必要に応じて修正を指示する

### 指示例

#### システム構成図の作成

```
「Webアプリケーションのシステム構成図を作成して。
 フロントエンド（React）、APIサーバー（FastAPI）、データベース（PostgreSQL）の3層構成で。
 docs/design/basic/system-architecture.drawio に保存して。」
```

#### シーケンス図の作成

```
「ユーザーログインのシーケンス図を作成して。
 ブラウザ → API Gateway → 認証サービス → DB の流れで。
 docs/design/detailed/login-sequence.drawio に保存して。」
```

#### 画面遷移図の作成

```
「管理画面の画面遷移図を作成して。
 ログイン → ダッシュボード → ユーザー管理 → ユーザー詳細 の遷移で。
 docs/ui-specs/screen-flow.drawio に保存して。」
```

#### 既存の図の編集

```
「docs/design/basic/system-architecture.drawio にキャッシュサーバー（Redis）を追加して。
 APIサーバーとDBの間に配置して。」
```

#### 業務フロー図の作成

```
「受注処理の業務フロー図をスイムレーンで作成して。
 営業部門、受注管理部門、倉庫部門の3レーンで。
 docs/pm/business-flow-order.drawio に保存して。」
```

## 推奨する保存先

| 図の種類 | 保存先 |
|---------|--------|
| システム構成図 | `docs/design/basic/` |
| シーケンス図・クラス図 | `docs/design/detailed/` |
| 画面遷移図・ワイヤーフレーム | `docs/ui-specs/` |
| 業務フロー図 | `docs/pm/` |
| API構成図 | `docs/api/` |
| コンテキスト図 | `docs/requirements/` |

## 図の作成時のコツ

### 明確な指示を出す

- **構成要素を列挙する** — 登場するノード（サーバー、サービス、アクター等）を具体的に伝える
- **接続関係を示す** — 「AからBへHTTPリクエスト」のように方向と内容を指定する
- **レイアウトを指定する** — 「左から右へ」「上から下へ」「3層構成で」等

### 段階的に作成する

1. まずシンプルな図を作成する
2. 確認後、ノードやラベルを追加・修正する
3. 複雑な図は一度に作ろうとせず、段階的に構築する

## トラブルシューティング

| 症状 | 対処法 |
|------|--------|
| MCP ツールが表示されない | Claude Code を再起動する |
| `npx drawio-mcp` が失敗する | `npm cache clean --force` 後に再試行 |
| devcontainer 内で動作しない | コンテナを再ビルドする |
| 生成された図が期待と異なる | より具体的な構成要素と接続関係を指示する |

## 関連ドキュメント

- [基本設計書の配置先](../design/basic/) — システム構成図等
- [詳細設計書の配置先](../design/detailed/) — シーケンス図、クラス図等
- [画面仕様書の配置先](../ui-specs/) — 画面遷移図等
