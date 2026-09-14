# custom-cc-sdd

[cc-sdd](https://github.com/gotalab/cc-sdd)（v3.0.2 / Claude Code Skills / 日本語）を自分用にカスタマイズした、Claude Code 向けの仕様駆動開発（SDD）環境。

## 含まれるもの

| パス | 内容 |
|---|---|
| `.claude/skills/kiro-*/` | cc-sdd のスキル 17 個。Claude Code が読み込む本体 |
| `.claude/settings.json` | ECC と競合しないためのプロジェクト設定（[ECC との併用](#ecc-との併用)） |
| `.kiro/settings/templates/` | 仕様（要件・設計・タスク）とステアリングのテンプレート |
| `CLAUDE.md` | cc-sdd のワークフローと ECC との使い分けを記したプロジェクトメモリ |
| `docs/jp/` | スキルの日本語訳（参照用。Claude Code は読み込まない）。入口は [docs/jp/README.md](docs/jp/README.md) |
| `THIRD_PARTY_NOTICES.md` | cc-sdd の MIT ライセンス表記 |

## 使い方

### 新しいプロジェクトを始める

このリポジトリは GitHub のテンプレートリポジトリになっている。テンプレートから作ると、履歴を引き継がない新しいリポジトリができる。

```bash
gh repo create my-app --private --template Noboon803/custom-cc-sdd --clone
```

GitHub の画面から作る場合は「Use this template」→「Create a new repository」を選ぶ。

GitHub にリポジトリを作らずに手元だけで始める場合は、クローンしてから履歴を切り離す。

```bash
git clone --depth 1 https://github.com/Noboon803/custom-cc-sdd.git my-app
cd my-app
rm -rf .git && git init
```

クローン後にやること:

- `README.md` を自分のプロジェクト用に書き換える
- `LICENSE` をプロジェクトのライセンスに合わせて差し替える
- `THIRD_PARTY_NOTICES.md` は cc-sdd のライセンス条件なので**残す**
- `docs/jp/` は不要なら削除してよい

### 既存のプロジェクトに入れる

クローンしたものから必要なファイルだけをコピーする。

```bash
git clone --depth 1 https://github.com/Noboon803/custom-cc-sdd.git /tmp/custom-cc-sdd
cd /path/to/existing-project
mkdir -p .claude/skills .kiro/settings
cp -R /tmp/custom-cc-sdd/.claude/skills/kiro-* .claude/skills/
cp -R /tmp/custom-cc-sdd/.kiro/settings/templates .kiro/settings/
cp /tmp/custom-cc-sdd/THIRD_PARTY_NOTICES.md .
```

次の 2 ファイルは、プロジェクトにすでにある場合は上書きせずに中身を統合する。ない場合はそのままコピーする。

- `CLAUDE.md`：`/tmp/custom-cc-sdd/CLAUDE.md` の内容を追記する
- `.claude/settings.json`：`claudeMdExcludes` と `skillOverrides` の項目を追加する

### 導入後

Claude Code を起動し、次のどれかから始める。

- `/kiro-discovery <アイデア>`：何を作るか、仕様をいくつに分けるかを整理する
- `/kiro-steering`：既存コードからプロジェクト全体の前提（ステアリング）を作る
- `/kiro-spec-init <作りたいもの>`：1 つの機能の仕様を作り始める

スキルごとの詳しい動作は [docs/jp/README.md](docs/jp/README.md) を参照。

## ECC との併用

[Everything Claude Code（ECC）](https://github.com/affaan-m/ECC) を `~/.claude` に入れている環境では、ECC にも独自の開発フロー（planner → tdd-guide → code-reviewer など）があり、cc-sdd の `kiro-*` と役割が重なる。このリポジトリでは、ECC の開発フローに関わる部分だけを止め、コーディング規約やセキュリティなどの品質ルールは残す。ECC がない環境では、以下の設定は何も影響しない。

| 仕組み | 場所 | 内容 |
|---|---|---|
| ルールの除外 | `.claude/settings.json` の `claudeMdExcludes` | ECC の `common/development-workflow.md`、`common/agents.md`、`common/code-review.md` を読み込まない |
| コマンドの自動起動を止める | `.claude/settings.json` の `skillOverrides` | `/plan`、`/prp-*`、`/orch-*`、`/multi-*`、`/gan-*`、`/code-review`、言語別の TDD コマンドなどを `user-invocable-only` にする。ユーザーが `/` で呼べば従来どおり動く |
| 使い分けの指示 | `CLAUDE.md` の「ECC との併用」 | 開発の流れは `kiro-*` で進める。`kiro-*` のサブエージェントには `general-purpose` を使い、ECC のエージェントを使わない |

ECC のエージェント自体は禁止していないので、ユーザーが名指しで頼めば使える。完全に禁止したい場合は、`.claude/settings.json` の `permissions.deny` に `"Agent(code-reviewer)"` のように追加する。

## メンテナンス

### ブランチ

| ブランチ | 内容 |
|---|---|
| `main` | 配布版。`upstream` に自分のカスタマイズを加えたもの |
| `upstream` | cc-sdd が出力したままの無改変版。本家の更新を取り込むためだけに使う |

### 本家 cc-sdd の更新を取り込む

```bash
git switch upstream
rm -rf .claude/skills/kiro-* .kiro/settings CLAUDE.md
npx cc-sdd@latest --lang ja --yes
git add .claude .kiro CLAUDE.md
git commit -m "chore: cc-sdd vX.Y.Z を取り込み"

git switch main
git diff main...upstream --stat -- .claude .kiro CLAUDE.md   # 変わったファイルを確認
git merge upstream
```

先に `rm -rf` するのは、本家で削除・改名されたファイルを残さないため。マージでカスタマイズと衝突した箇所は手で解決する。

### カスタマイズするとき

- スキルやテンプレートを変えたら、`docs/jp/` の対応するファイルも更新する
- 本家の更新を取り込んだあとは、変わったスキルの日本語訳も更新する
