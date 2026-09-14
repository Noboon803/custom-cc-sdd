---
name: kiro-spec-batch
description: roadmap.md 内のすべての機能について、依存ウェーブごとの並列サブエージェントのディスパッチにより、完全な仕様（要件、設計、タスク）を作成する。
allowed-tools: Read, Glob, Grep, Agent
---

> 原文: `.claude/skills/kiro-spec-batch/SKILL.md`（cc-sdd v3.0.2）の日本語訳。参照用であり、Claude Code はこのファイルを読み込まない。

# kiro-spec-batch スキル

## コアミッション
- **成功基準**:
  - すべての機能が完全な仕様ファイル（spec.json、requirements.md、design.md、tasks.md）を持っている
  - 依存関係の順序が守られている（上流の仕様が下流より先に完了する）
  - 独立した機能は、サブエージェントのディスパッチによって並列に処理される
  - 仕様横断の一貫性（データモデル、インターフェース、命名）が確認されている
  - `## Specs (dependency order)` のパースを壊さずに、混合ロードマップのコンテキストが理解されている
  - コントローラーのコンテキストが軽量に保たれている（重い作業はサブエージェントが行う）

## 実行ステップ

### ステップ 1: ロードマップの読み込みと検証

1. `.kiro/steering/roadmap.md` を読む
2. `## Specs (dependency order)` セクションをパースし、以下を抽出する:
   - 機能名
   - 1 行の説明
   - 各機能の依存関係
   - 完了状態（`[x]` = 完了、`[ ]` = 未完了）
3. 存在する場合は、コンテキストとして以下も読む:
   - `## Existing Spec Updates`
   - `## Direct Implementation Candidates`
   これらは依存ウェーブの実行には含めない。これらは、順序付けと一貫性レビューのための、把握目的だけの入力である。
4. `## Specs (dependency order)` 内の未完了の各機能について、`.kiro/specs/<feature>/brief.md` が存在することを確認する
5. brief.md が 1 つでも欠けている場合は、停止して次のように報告する: "Missing brief.md for: [list]. Run `/kiro-discovery` to generate briefs first."（次の機能の brief.md がない: [一覧]。先に `/kiro-discovery` を実行してブリーフを生成せよ）

### ステップ 2: 依存ウェーブの構築

未完了の機能を、依存関係に基づいてウェーブにグループ化する:

- **ウェーブ 1**: 依存関係がない（またはすべての依存先が既に完了 `[x]` している）機能
- **ウェーブ 2**: 依存先がすべてウェーブ 1 にあるか、既に完了している機能
- **ウェーブ N**: 依存先がすべてそれより前のウェーブにあるか、既に完了している機能

実行計画を表示する:
```
Spec Batch Plan:
  Wave 1 (parallel): app-foundation
  Wave 2 (parallel): block-editor, page-management
  Wave 3 (parallel): sidebar-navigation, database-views
  Wave 4 (parallel): cli-integration
  Total: 6 specs across 4 waves
```

ロードマップに `## Existing Spec Updates` または `## Direct Implementation Candidates` が含まれる場合は、ユーザーが分解の全体像を把握できるよう、それらをバッチ対象外の項目として別途言及する。

### ステップ 3: ウェーブの実行

各ウェーブについて、そのウェーブ内のすべての機能を Agent ツールで**並列サブエージェント**としてディスパッチする。

**ウェーブ内の各機能について**、次のプロンプトでサブエージェントをディスパッチする:

```
Create a complete specification for feature "{feature-name}".

1. Read the brief at .kiro/specs/{feature-name}/brief.md for feature context
2. Read the roadmap at .kiro/steering/roadmap.md for project context
3. Execute the full spec pipeline. For each phase, read the corresponding skill's SKILL.md for complete instructions (templates, rules, review gates):
   a. Initialize: Read .claude/skills/kiro-spec-init/SKILL.md, then create spec.json and requirements.md
   b. Generate requirements: Read .claude/skills/kiro-spec-requirements/SKILL.md, then follow its steps
   c. Generate design: Read .claude/skills/kiro-spec-design/SKILL.md, then follow its steps
   d. Generate tasks: Read .claude/skills/kiro-spec-tasks/SKILL.md, then follow its steps
4. Set all approvals to true in spec.json (auto-approve mode, equivalent of -y flag)
5. Report completion with file list and task count
```

（訳注: 上のプロンプトの日本語訳。実際には上の英語がそのまま送られる）
```
機能 "{feature-name}" の完全な仕様を作成せよ。

1. 機能のコンテキストとして .kiro/specs/{feature-name}/brief.md のブリーフを読む
2. プロジェクトのコンテキストとして .kiro/steering/roadmap.md のロードマップを読む
3. 仕様パイプライン全体を実行する。各フェーズについて、完全な指示（テンプレート、ルール、レビューゲート）を得るために対応するスキルの SKILL.md を読む:
   a. 初期化: .claude/skills/kiro-spec-init/SKILL.md を読み、spec.json と requirements.md を作成する
   b. 要件の生成: .claude/skills/kiro-spec-requirements/SKILL.md を読み、そのステップに従う
   c. 設計の生成: .claude/skills/kiro-spec-design/SKILL.md を読み、そのステップに従う
   d. タスクの生成: .claude/skills/kiro-spec-tasks/SKILL.md を読み、そのステップに従う
4. spec.json のすべての approvals を true に設定する（自動承認モード。-y フラグと同等）
5. ファイル一覧とタスク数を付けて完了を報告する
```

**ウェーブ内のすべてのサブエージェントが完了した後**:
1. 各機能に spec.json、requirements.md、design.md、tasks.md があることを確認する
2. 失敗した機能がある場合は、エラーを報告し、成功した機能で続行する
3. ウェーブの完了を表示する: "Wave N complete: [features]. Files verified."（ウェーブ N 完了: [機能]。ファイルを確認済み）
4. 次のウェーブへ進む

### ステップ 4: 仕様横断レビュー

すべてのウェーブが完了した後、仕様横断の一貫性レビューのために**単一のサブエージェント**をディスパッチする。これは最も価値の高い品質ゲートであり、仕様ごとのレビューゲートでは捕捉できない問題を捕捉する。

**サブエージェントへのプロンプト**:

```
You are a cross-spec reviewer. Read ALL generated specs and check for consistency across the entire project.

Read these files for every feature in the roadmap:
- .kiro/specs/*/design.md (primary: contains interfaces, data models, architecture)
- .kiro/specs/*/requirements.md (for scope and acceptance criteria)
- .kiro/specs/*/tasks.md (for boundary annotations only -- read _Boundary:_ lines, skip task descriptions)
- .kiro/steering/roadmap.md

Reading priority: Focus on design.md files (they contain interfaces, data models, architecture). For requirements.md, focus on section headings and acceptance criteria. For tasks.md, focus on _Boundary:_ annotations.

Check the following:

1. **Data model consistency**: Do all specs that reference the same entities (tables, types, interfaces) define them consistently? Are field names, types, and relationships aligned?

2. **Interface alignment**: Where spec A produces output that spec B consumes (APIs, events, shared state), do the contracts match exactly? Are request/response shapes, event payloads, and error codes consistent?

3. **No duplicate functionality**: Is any capability specified in more than one spec? Flag overlaps.

4. **Dependency completeness**: Does every spec's design.md reference the correct upstream specs? Are there implicit dependencies not declared in roadmap.md?

5. **Naming conventions**: Are component names, file paths, API routes, and database table names consistent across all specs?

6. **Shared infrastructure**: Are shared concerns (authentication, error handling, logging, configuration) handled in one spec and correctly referenced by others?

7. **Task boundary alignment**: Do task _Boundary:_ annotations across specs partition the codebase cleanly? Are there files claimed by multiple specs?
8. **Roadmap boundary continuity**: If roadmap includes `Existing Spec Updates` or `Direct Implementation Candidates`, do the generated new specs avoid absorbing that work by accident?
9. **Architecture boundary integrity**: Do the specs preserve clean responsibility seams, avoid shared ownership, keep dependency direction coherent, and include enough revalidation triggers to catch downstream impact?
10. **Change-friendly decomposition**: Has any spec absorbed multiple independent seams that should probably be split instead of kept together?

Output format:
- CONSISTENT: [list areas that are well-aligned]
- ISSUES: [list each issue with: which specs, what's inconsistent, suggested fix]
- If no issues found: "All specs are consistent. Ready for implementation."
```

（訳注: 上のプロンプトの日本語訳。実際には上の英語がそのまま送られる）
```
あなたは仕様横断のレビュー担当である。生成されたすべての仕様を読み、プロジェクト全体にわたる一貫性を確認せよ。

ロードマップ内のすべての機能について、次のファイルを読む:
- .kiro/specs/*/design.md（主要: インターフェース、データモデル、アーキテクチャを含む）
- .kiro/specs/*/requirements.md（スコープと受け入れ基準のため）
- .kiro/specs/*/tasks.md（境界の注記のためだけに読む -- _Boundary:_ の行を読み、タスクの説明はスキップする）
- .kiro/steering/roadmap.md

読む優先順位: design.md ファイルに重点を置く（インターフェース、データモデル、アーキテクチャを含むため）。requirements.md では、セクション見出しと受け入れ基準に重点を置く。tasks.md では、_Boundary:_ の注記に重点を置く。

次の点を確認する:

1. **データモデルの一貫性**: 同じエンティティ（テーブル、型、インターフェース）を参照するすべての仕様が、それらを一貫して定義しているか。フィールド名、型、リレーションは揃っているか。

2. **インターフェースの整合**: 仕様 A が出力を生成し仕様 B がそれを消費する箇所（API、イベント、共有状態）で、契約は完全に一致しているか。リクエスト／レスポンスの形、イベントのペイロード、エラーコードは一貫しているか。

3. **機能の重複がないこと**: 2 つ以上の仕様で規定されている能力はないか。重複を指摘する。

4. **依存関係の完全性**: すべての仕様の design.md が正しい上流の仕様を参照しているか。roadmap.md で宣言されていない暗黙の依存関係はないか。

5. **命名規約**: コンポーネント名、ファイルパス、API ルート、データベースのテーブル名は、すべての仕様で一貫しているか。

6. **共有インフラ**: 共有の関心事（認証、エラー処理、ロギング、設定）は 1 つの仕様で扱われ、他の仕様から正しく参照されているか。

7. **タスク境界の整合**: 仕様をまたいだタスクの _Boundary:_ 注記は、コードベースをきれいに分割しているか。複数の仕様が主張しているファイルはないか。
8. **ロードマップ境界の連続性**: ロードマップに `Existing Spec Updates` または `Direct Implementation Candidates` が含まれる場合、生成された新規仕様がその作業を誤って取り込んでいないか。
9. **アーキテクチャ境界の完全性**: 仕様はきれいな責務の継ぎ目を保ち、共有所有を避け、依存方向を一貫させ、下流への影響を捕捉するのに十分な再検証トリガーを含んでいるか。
10. **変更に強い分解**: 一緒にしておくのではなく分割すべきと思われる、複数の独立した継ぎ目を取り込んでしまった仕様はないか。

出力形式:
- CONSISTENT: [よく整合している領域の一覧]
- ISSUES: [各問題を、どの仕様か、何が不整合か、修正案とともに列挙する]
- 問題が見つからなかった場合: "All specs are consistent. Ready for implementation."
```

**レビュー用サブエージェントが結果を返した後**:
- **重大／重要な問題が見つかった場合**: 影響を受ける各仕様について、修正案を適用するための修正用サブエージェントをディスパッチする。問題が実際には分解の問題である場合（たとえば境界の重なりや、1 つの仕様が複数の独立した継ぎ目を抱えている場合）は、局所的に取り繕うのではなく、停止してロードマップ／ディスカバリーに戻る。修正後に仕様横断レビューを再実行する（是正は最大 3 ラウンド）。
- **軽微な問題のみの場合**: ユーザーが把握できるように報告し、ステップ 5 へ進む。
- **問題がない場合**: ステップ 5 へ進む。

### ステップ 5: 最終処理

1. `.kiro/specs/*/tasks.md` を Glob して、すべての仕様が存在することを確認する
2. 完了した各仕様について、spec.json を読んで phase と approvals を確認する
3. roadmap.md を更新する: 完了した仕様を `[x]` にする
4. roadmap.md に `Existing Spec Updates` または `Direct Implementation Candidates` が含まれる場合は、それらには手を付けず、他所で明示的に完了済みでない限り、残りのフォローアップ項目として言及する

最終サマリーを表示する:
```
Spec Batch Complete:
  ✓ app-foundation: X requirements, Y design components, Z tasks
  ✓ block-editor: ...
  ✓ page-management: ...
  ...
  Total: N specs created, M tasks generated
  Cross-spec review: PASSED / N issues found (M fixed)
  Existing spec updates pending: <count or none>
  Direct implementation candidates pending: <count or none>

Next: Review generated specs, then start implementation with /kiro-impl <feature>
```
（意味: 仕様ごとの要件数・設計コンポーネント数・タスク数、作成した仕様とタスクの合計、仕様横断レビューの結果（`PASSED`=合格／N 件の問題、うち M 件修正）、保留中の既存仕様の更新数と直接実装候補数（`<count or none>`=件数または none）、次: 生成された仕様をレビューし、`/kiro-impl <feature>` で実装を開始する）

## 重大な制約
- **コントローラーは軽量に保つ**: メインコンテキストで読むのは roadmap.md と brief.md の存在確認だけである。仕様の生成はすべてサブエージェント内で行う。
- **ウェーブの順序は厳格である**: それより前のウェーブのすべての機能が完了するまで、ウェーブを開始してはならない。
- **ウェーブ内は並列**: 同じウェーブ内のすべての機能は、順番にではなく、Agent ツールで並列にディスパッチしなければならない（MUST）。
- **部分的なウェーブにしない**: ウェーブ内のある機能が失敗しても、報告する前にそのウェーブ内の他の機能は完了させる。
- **完了済みの仕様はスキップする**: roadmap.md で `[x]` になっている機能、または tasks.md が既に存在する機能はスキップする。
- **`## Specs (dependency order)` がバッチ実行における正典であり続ける**: ロードマップの他のセクションはコンテキストであり、ウェーブへの入力ではない。

## 安全策とフォールバック

**サブエージェントの失敗**:
- エラーを記録し、失敗した機能をスキップする
- ウェーブ内の残りの機能で続行する
- 失敗した機能をサマリーで報告する
- 次を提案する: "Run `/kiro-spec-quick <feature> --auto` manually for failed features."（失敗した機能には `/kiro-spec-quick <feature> --auto` を手動で実行せよ）

**循環依存**:
- 依存グラフに循環がある場合は、その循環を報告して停止する
- 次を提案する: "Fix dependency ordering in roadmap.md"（roadmap.md の依存順序を修正せよ）

**ロードマップが見つからない場合**:
- 停止して次のように報告する: "No roadmap.md found. Run `/kiro-discovery` first."（roadmap.md が見つからない。先に `/kiro-discovery` を実行せよ）
