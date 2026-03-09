---
name: commit
description: Git コミットエージェント。変更内容を分析し、適切なコミットメッセージを生成してコミットを実行する。キーワード: commit, コミット, git commit.
user_invocable: true
---

# Git Commit エージェント

## 手順

以下の手順を順番に実行する。

### 1. 現状確認（並列実行）

以下の 3 コマンドを **並列** で実行する:

```bash
git status
git diff --staged
git diff
```

さらに直近のコミットメッセージスタイルを確認する:

```bash
git log --oneline -10
```

### 2. 変更内容の分析

- staged と unstaged の両方の差分を確認する
- 変更の性質を判定する: `feat` / `fix` / `refactor` / `docs` / `test` / `chore` / `style`
- `.env`, `credentials`, 秘密鍵などの機密ファイルが含まれていないか確認する
  - 含まれていた場合は **警告** を出し、コミット対象から除外する

### 3. ステージング

- unstaged の変更がある場合、関連ファイルを `git add` でステージングする
- `git add -A` や `git add .` は使用しない（意図しないファイルの混入を防ぐ）
- ファイル名を個別に指定してステージングする

### 4. コミットメッセージ生成

リポジトリの既存コミットメッセージスタイルに合わせる。

**デフォルトフォーマット:**

```
{type}: {変更の要約（日本語 or 英語、既存スタイルに合わせる）}

{変更の詳細（必要な場合のみ）}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

**type 一覧:**

| type | 用途 |
|------|------|
| `feat` | 新機能追加 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみの変更 |
| `style` | コードの意味に影響しない変更（フォーマット等） |
| `refactor` | バグ修正でも機能追加でもないコード変更 |
| `test` | テストの追加・修正 |
| `chore` | ビルドプロセスや補助ツールの変更 |

### 5. コミット実行

```bash
git commit -m "$(cat <<'EOF'
{コミットメッセージ}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

### 6. 結果確認

```bash
git status
```

コミットが成功したことを確認し、結果を報告する。

## 注意事項

- **変更がない場合**: 空コミットは作成しない。ユーザーに報告して終了する。
- **pre-commit hook 失敗時**: hook のエラーを修正し、**新しいコミット** を作成する（`--amend` は使わない）。
- **push はしない**: コミットのみ実行する。push はユーザーが明示的に指示した場合のみ行う。
- **`--no-verify` は使わない**: hook をスキップしない。
