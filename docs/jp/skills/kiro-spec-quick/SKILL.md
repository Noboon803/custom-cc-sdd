---
name: kiro-spec-quick
description: 対話モードまたは自動モードによる仕様の高速生成
allowed-tools: Read, Skill, Bash, Write, Glob, Agent
argument-hint: <project-description> [--auto]
---

> 原文: `.claude/skills/kiro-spec-quick/SKILL.md`（cc-sdd v3.0.2）の日本語訳。参照用であり、Claude Code はこのファイルを読み込まない。

# 仕様の高速生成

<instructions>
## CRITICAL: 自動モードの実行ルール

**`$ARGUMENTS` に `--auto` フラグが含まれている場合、あなたは自動モード（AUTOMATIC MODE）である。**

自動モードでは:
- 4 つのフェーズを、止まることなく連続したループで**すべて**実行する
- 各フェーズの後に進捗を表示する（例: "Phase 1/4 complete: spec initialized"）
- フェーズ 2〜4 からの「Next Step」メッセージは**無視する**（それらは単体での使用向けである）
- フェーズ 4 の後、終了する前に最終の健全性レビューを実行する
- 停止するのは、健全性レビューが完了した後、またはエラーが発生した場合**のみ**である

---

## コアタスク
4 つの仕様フェーズを順番に実行する。自動モードでは、止まらずに全フェーズを実行する。対話モードでは、フェーズの間でユーザーに承認を求める。

高速生成が完了したと主張する前に、生成された要件、設計、タスクに対して軽量な健全性レビューを 1 回実行する。ホストが新規のサブエージェントをサポートしている場合はそれを使う。そうでなければ、健全性レビューをインラインで実行する。

## 実行ステップ

### ステップ 1: 引数の解析と初期化

`$ARGUMENTS` を解析する:
- `--auto` を含む場合: **自動モード**（4 フェーズすべてを実行する）
- それ以外: **対話モード**（各フェーズで確認を求める）
- 説明文を抽出する（`--auto` フラグがあれば取り除く）

例:
```
"User profile with avatar upload --auto" → mode=automatic, description="User profile with avatar upload"
"User profile feature" → mode=interactive, description="User profile feature"
```

モードのバナーを表示し、ステップ 2 へ進む。

### ステップ 2: フェーズループの実行

次の 4 つのフェーズを順番に実行する:

---

#### フェーズ 1: 仕様の初期化（直接実装）

**コアロジック**:

1. **ブリーフの確認**:
   - `.kiro/specs/{feature-name}/brief.md` が存在する場合（`/kiro-discovery` が作成したもの）、ディスカバリーのコンテキスト（問題、アプローチ、スコープ、制約）を得るためにそれを読む
   - `$ARGUMENTS` の代わりに、ブリーフの内容をプロジェクトの説明として使う

2. **機能名の生成**:
   - 説明文を kebab-case に変換する
   - 例: "User profile with avatar upload" → "user-profile-avatar-upload"
   - 名前は簡潔に保つ（理想は 2〜4 語）

3. **一意性の確認**:
   - Glob を使って `.kiro/specs/*/` を確認する
   - `brief.md` だけがある（`spec.json` がない）ディレクトリが存在する場合は、そのディレクトリを使う（ディスカバリーが作成したもの）
   - それ以外で機能名が既に存在する場合は、`-2`、`-3` などを付け足す

4. **ディレクトリの作成**:
   - Bash を使う: `mkdir -p .kiro/specs/{feature-name}`（ディスカバリーによって既に存在する場合はスキップする）

5. **テンプレートからファイルを初期化する**:

   a. テンプレートを読む:
   ```
   - .kiro/settings/templates/specs/init.json
   - .kiro/settings/templates/specs/requirements-init.md
   ```

   b. プレースホルダーを置換する:
   ```
   {{FEATURE_NAME}} → feature-name
   {{TIMESTAMP}} → current ISO 8601 timestamp (use `date -u +"%Y-%m-%dT%H:%M:%SZ"`)
   {{PROJECT_DESCRIPTION}} → description
   ja → language code (detect from user's input language, default to `en`)
   ```
   （意味: `{{FEATURE_NAME}}` → 機能名、`{{TIMESTAMP}}` → 現在の ISO 8601 タイムスタンプ（`date -u +"%Y-%m-%dT%H:%M:%SZ"` を使う）、`{{PROJECT_DESCRIPTION}}` → 説明文、`ja` → 言語コード（ユーザーの入力言語から検出し、デフォルトは `en`）。訳注: 最終行は原文でも `ja` となっており、インストール時に言語プレースホルダーが置換された結果と思われる）

   c. Write ツールを使ってファイルを書き込む:
   ```
   - .kiro/specs/{feature-name}/spec.json
   - .kiro/specs/{feature-name}/requirements.md
   ```

6. **進捗の出力**: "Phase 1/4 complete: Spec initialized at .kiro/specs/{feature-name}/"（フェーズ 1/4 完了: 仕様を初期化した）

**自動モード**: **直ちに**フェーズ 2 へ続行する。

**対話モード**: "Continue to requirements generation? (yes/no)"（要件生成へ進むか）と確認する
- "no" の場合: 停止し、現在の状態を表示する
- "yes" の場合: フェーズ 2 へ続行する

---

#### フェーズ 2: 要件の生成

Skill ツールで `/kiro-spec-requirements {feature-name}` を呼び出す。

完了を待つ。「Next Step」メッセージは**無視する**（それは単体での使用向けである）。

**進捗の出力**: "Phase 2/4 complete: Requirements generated"（フェーズ 2/4 完了: 要件を生成した）

**自動モード**: **直ちに**フェーズ 3 へ続行する。

**対話モード**: "Continue to design generation? (yes/no)"（設計生成へ進むか）と確認する
- "no" の場合: 停止し、現在の状態を表示する
- "yes" の場合: フェーズ 3 へ続行する

---

#### フェーズ 3: 設計の生成

Skill ツールで `/kiro-spec-design {feature-name} -y` を呼び出す。`-y` フラグは要件を自動承認する。

完了を待つ。「Next Step」メッセージは**無視する**。

**進捗の出力**: "Phase 3/4 complete: Design generated"（フェーズ 3/4 完了: 設計を生成した）

**自動モード**: **直ちに**フェーズ 4 へ続行する。

**対話モード**: "Continue to tasks generation? (yes/no)"（タスク生成へ進むか）と確認する
- "no" の場合: 停止し、現在の状態を表示する
- "yes" の場合: フェーズ 4 へ続行する

---

#### フェーズ 4: タスクの生成

Skill ツールで `/kiro-spec-tasks {feature-name} -y` を呼び出す。

注: `-y` フラグは要件、設計、タスクを自動承認する。

完了を待つ。

**進捗の出力**: "Phase 4/4 complete: Tasks generated"（フェーズ 4/4 完了: タスクを生成した）

#### 最終の健全性レビュー

フェーズ 4 の後、完了を主張する前に軽量な健全性レビューを実行する。

- `requirements.md`、`design.md`、`tasks.md` をディスクから直接レビューする。`brief.md` が存在する場合は、補助的なコンテキストとしてのみ使う。
- ホストがサポートしている場合は、新規のレビュー用サブエージェントを優先する。渡すのはファイルパスとレビューの目的だけにし、生成されたファイルはレビュー担当が自分で読むようにする。
- レビューの焦点:
  - 要件、設計、タスクは一貫したストーリーを語っているか
  - 明らかな矛盾、欠けている前提条件、または必須の設計作業に対するタスクのカバー漏れはないか
  - `_Depends:_`、`_Boundary:_`、`(P)` のマーカーは実装にとって妥当か
- レビューでタスク計画内に閉じた問題のみが見つかった場合は、生成された `tasks.md` を 1 回だけ修復または更新し、その後健全性レビューを再実行する。
- レビューで要件／設計に本当のギャップや矛盾が見つかった場合は、高速仕様が実装可能な状態だと主張せず、停止してフォローアップを報告する。

**4 フェーズすべてと健全性レビューが完了した。**

最終完了サマリー（「出力の説明」セクションを参照）を出力して終了する。

---

## 重要な制約

### エラー処理
- いずれかのフェーズが失敗したら、ワークフローを停止する
- エラーと現在の状態を表示する
- 手動で復旧するためのコマンドを提案する

</instructions>

## 出力の説明

### モードのバナー

**対話モード**:
```
Quick Spec Generation (Interactive Mode)

You will be prompted at each phase.
Note: Skips gap analysis and design validation.
```
（意味: 仕様の高速生成（対話モード）。各フェーズで確認が求められる。注: ギャップ分析と設計の検証はスキップする。）

**自動モード**:
```
Quick Spec Generation (Automatic Mode)

All phases execute automatically without prompts.
Note: Skips optional validations (gap analysis, design review) and user approval prompts. Internal review gates still run.
Final sanity review still runs.
```
（意味: 仕様の高速生成（自動モード）。全フェーズが確認なしで自動実行される。注: 任意の検証（ギャップ分析、設計レビュー）とユーザー承認の確認はスキップするが、内部のレビューゲートは実行される。最終の健全性レビューも実行される。）

### 途中の出力

各フェーズの後、簡潔な進捗を表示する:
```
Spec initialized at .kiro/specs/{feature}/
Requirements generated → Continuing to design...
Design generated → Continuing to tasks...
```

### 最終完了サマリー

`spec.json` で指定された言語で出力を行う:

```
Quick Spec Generation Complete!

Generated Files:
- specs/{feature}/spec.json
- specs/{feature}/requirements.md ({X} requirements)
- specs/{feature}/design.md ({Y} components, {Z} endpoints)
- specs/{feature}/tasks.md ({N} tasks)

Skipped: /kiro-validate-gap, /kiro-validate-design

Sanity review: PASSED | FOLLOW-UP REQUIRED

Next Steps:
1. Review generated specs (especially design.md)
2. Optional: `/kiro-validate-gap {feature}`, `/kiro-validate-design {feature}`
3. Start implementation: `/kiro-impl {feature}`
```
（意味: 生成したファイル一覧（要件数・コンポーネント数・エンドポイント数・タスク数）、スキップしたコマンド、健全性レビューの結果（`PASSED`=合格／`FOLLOW-UP REQUIRED`=フォローアップが必要）、次のステップ: 1. 生成された仕様をレビューする（特に design.md）、2. 任意で検証コマンドを実行する、3. 実装を開始する）

## 安全策とフォールバック

### エラーシナリオ

**テンプレートがない場合**:
- `.kiro/settings/templates/specs/` が存在するか確認する
- 欠けている具体的なファイルを報告する
- エラーで終了する

**ディレクトリの作成に失敗した場合**:
- 権限を確認する
- パスを付けてエラーを報告する
- エラーで終了する

**フェーズの実行に失敗した場合**（フェーズ 2〜4）:
- ワークフローを停止する
- 現在の状態と完了済みのフェーズを表示する
- 次を提案する: "Continue manually from `/kiro-spec-{next-phase} {feature}`"（`/kiro-spec-{next-phase} {feature}` から手動で続行せよ）

**健全性レビューが失敗した場合**:
- ワークフローを停止する
- 正確な矛盾、欠けている前提条件、またはタスク計画の問題を報告する
- 見つかった内容に応じて、`/kiro-spec-design {feature}`、`/kiro-spec-tasks {feature}`、または手動編集による的を絞ったフォローアップを提案する

**ユーザーによるキャンセル**（対話モード）:
- 穏当に停止する
- 完了済みのフェーズを表示する
- 手動での続行を提案する
