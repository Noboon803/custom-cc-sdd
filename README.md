# custom-cc-sdd

[cc-sdd](https://github.com/gotalab/cc-sdd)（v3.0.2 / Claude Code Skills / 日本語）を自分用にカスタマイズした、Claude Code 向けの仕様駆動開発（SDD）環境。

## 含まれるもの

| パス | 内容 |
|---|---|
| `.claude/skills/kiro-*/` | cc-sdd のスキル 17 個。Claude Code が読み込む本体 |
| `.claude/settings.json` | ECC と競合しないための設定と、Python の品質チェック hook の登録（[ECC との併用](#ecc-との併用)、[Python の品質チェック](#python-の品質チェック)） |
| `.claude/hooks/python-quality.sh` | Python ファイルの編集後に ruff と mypy を実行する hook |
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
mkdir -p .claude/skills .claude/hooks .kiro/settings
cp -R /tmp/custom-cc-sdd/.claude/skills/kiro-* .claude/skills/
cp /tmp/custom-cc-sdd/.claude/hooks/python-quality.sh .claude/hooks/
cp -R /tmp/custom-cc-sdd/.kiro/settings/templates .kiro/settings/
cp /tmp/custom-cc-sdd/THIRD_PARTY_NOTICES.md .
```

次の 2 ファイルは、プロジェクトにすでにある場合は上書きせずに中身を統合する。ない場合はそのままコピーする。

- `CLAUDE.md`：`/tmp/custom-cc-sdd/CLAUDE.md` の内容を追記する
- `.claude/settings.json`：`claudeMdExcludes`、`skillOverrides`、`hooks` の項目を追加する

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
| レビューへの組み込み | `kiro-review` の「12.5 Coding Standards」、`kiro-impl/templates/reviewer-prompt.md` の「12. Coding Standards」 | `kiro-impl` のレビュー担当が変更したファイルを読み、ECC の言語別ルールなどの必須項目への違反を REJECTED にする。結果は `Coding standards:` 行に出る |

ECC のエージェント自体は禁止していないので、ユーザーが名指しで頼めば使える。完全に禁止したい場合は、`.claude/settings.json` の `permissions.deny` に `"Agent(code-reviewer)"` のように追加する。

## Python の品質チェック

Python ファイルを Write / Edit したとき（サブエージェントの編集も含む）に、`.claude/hooks/python-quality.sh` が次を実行する。ECC がなくても動く。

| 順番 | コマンド | 動作 |
|---|---|---|
| 1 | `ruff format` | 自動で整形する |
| 2 | `ruff check --fix` | 自動で直せる lint を直し、残った違反を報告する |
| 3 | `mypy` | `pyproject.toml` の `[tool.mypy]`、`mypy.ini`、`setup.cfg` の `[mypy]` のどれかがある場合だけ実行し、編集したファイルの型エラーを報告する |

- 問題が残ると hook が Claude に内容を返し、Claude がその場で修正する
- ruff と mypy はプロジェクトの `.venv/bin/` を優先し、なければ PATH から探す。どちらにもなければ何もしない。`uv add --dev ruff mypy` などで開発依存に入れておく
- black で整形しているプロジェクトでは ruff format と結果が一部異なることがあるので、ruff format に揃えるか、hook の該当行を外す
- Python 以外のファイルでは何もしない

## テストの深さ

本家の cc-sdd のレビューは「実装を壊したら失敗するテストか」を確かめる。どこまで確かめるかの線引きがないため、レビュー担当が自発的にミューテーション試験を行って細部のテストを求め、実装担当も細かな入力の組み合わせまでテストを書く傾向があった。このリポジトリでは、必要なテストは必ず求めたうえで、それを超える部分だけを却下の対象から外す。

| 項目 | 基準 |
|---|---|
| 必須のテスト（欠けていたら却下） | タスクで追加・変更した振る舞いごとに、壊れたら失敗するテスト。対象は受け入れ基準、要件が求めるエラー時の動作、設計が指定する動作。加えて、追加・変更したコードの経路（関数と分岐）はすべてテストで実行されること |
| カバレッジの閾値 | ステアリングまたはテストの設定の値（設定がなければ 80%）。全体の下限であり、満たしていても必須のテストが欠けていれば却下する |
| 却下せず提案にするもの | 要件にも設計にもないケース（NaN の扱いなど）、テスト済みの振る舞いへの入力の追加、追加の堅牢化 |
| 入力の選び方 | 1 つの振る舞いにつき代表的な入力を 1 つ。要件や設計が具体的な値（両端を含む境界など）を示している場合はその値も |
| ミューテーション試験 | データの保存、セキュリティ、認可の振る舞いを変えるタスクだけで、その振る舞いに限って行う |

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

本家のファイルに手を入れているのは次の 4 つ。マージで衝突しやすいのはこれらになる。

| ファイル | 変更内容 |
|---|---|
| `CLAUDE.md` | スキル自動起動の対象を `kiro-*` に限定、「ECC との併用」セクションを追加 |
| `.claude/skills/kiro-review/SKILL.md` | 「11. Test Quality」にテストの深さの基準を追加、「12.5 Coding Standards」と出力の `Coding standards:` 行を追加 |
| `.claude/skills/kiro-impl/templates/reviewer-prompt.md` | 「10. Test Quality」にテストの深さの基準を追加、「12. Coding Standards」と出力の `Coding standards:` 行を追加 |
| `.claude/skills/kiro-impl/templates/implementer-prompt.md` | 「Step 3」にテストの深さの基準を追加 |

### カスタマイズするとき

- スキルやテンプレートを変えたら、`docs/jp/` の対応するファイルも更新する
- 本家の更新を取り込んだあとは、変わったスキルの日本語訳も更新する
