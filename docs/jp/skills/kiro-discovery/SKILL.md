---
name: kiro-discovery
description: 新しい作業の入口。最適なアクションパスまたは作業の分解（既存仕様の更新、新規仕様の作成、混合分解、仕様不要）を判断し、構造化された対話を通じてアイデアを洗練する。
disable-model-invocation: true
allowed-tools: Read, Write, Glob, Grep, Agent, WebSearch, WebFetch, AskUserQuestion
argument-hint: <idea-or-request>
---

> 原文: `.claude/skills/kiro-discovery/SKILL.md`（cc-sdd v3.0.2）の日本語訳。参照用であり、Claude Code はこのファイルを読み込まない。

# kiro-discovery スキル

## コアミッション
- **成功基準**:
  - 既存のプロジェクト状態に基づいて、正しいアクションパスまたは作業の分解が特定されている
  - ユーザーの意図が、推測ではなく質問を通じて明確化されている
  - 出力が実行可能な次のステップである（単なる説明ではない）

## 実行ステップ

### ステップ 1: 軽量スキャン

アクションパスを判断するために、**メタデータのみ**を収集する。この時点ではファイルの全内容を読んではならない。

- **仕様の棚卸し**: `.kiro/specs/*/spec.json` を Glob し、各 spec.json の `name`、`phase` フィールドと `approvals` の状態を読む。機能名とその現在の状態を記録する。
- **ステアリングの存在確認**: `.kiro/steering/` にどのファイル（product.md、tech.md、structure.md、roadmap.md）が存在するかを確認する。この時点ではそれらの内容を読んではならない。
- **ロードマップの確認**: `.kiro/steering/roadmap.md` が存在する場合は、それを読む。これには以前のディスカバリーセッションで得たプロジェクトレベルのコンテキスト（アプローチ、スコープ、制約、仕様リスト）が含まれている。これを使ってプロジェクトのコンテキストを復元する。
- **トップレベル構造**: プロジェクトのルートディレクトリを一覧表示し、主要なディレクトリとファイルを記録する。サブディレクトリへ再帰してはならない。

このステップで消費するコンテキストは最小限にすべきである。`specs/` が空でステアリングも存在しない場合は、「greenfield project」（新規プロジェクト）と記録してステップ 2 へ進む。

### ステップ 2: アクションパスの判断

ユーザーのリクエストとステップ 1 で得たメタデータに基づき、どのパスに該当するかを判断する。

**パス A: 既存の仕様でカバーされる**
- リクエストが、既存仕様の領域内での拡張、強化、または修正である
- リクエストの意味のある部分がすべて、その同じ仕様の境界に収まる
- 残る小さなフォローアップ作業は、新しい仕様を作成せずに直接対応できる
- 残りのステップはスキップする

**パス B: 仕様不要**
- リクエストがバグ修正、設定変更、単純なリファクタリング、または些細な追加である
- リクエストのどの意味のある部分も、新しい仕様境界や更新された仕様境界を必要としない
- リクエストは既存の仕様の更新も必要としない
- 残りのステップはスキップする

**パス C: 新規の単一スコープ機能**
- リクエストが新しいもので、既存の仕様と重ならず、1 つの仕様に収まる

**パス D: 複数スコープへの分解が必要**
- リクエストが複数の領域にまたがる、または単一の仕様では 20 個以上のタスクが生じる

**パス E: 混合分解**
- リクエストに、既存仕様の拡張、1 つ以上の新規仕様候補、そして任意で直接実装の作業が混在している
- このパスは、本当に新しい仕様境界が少なくとも 1 つ必要な場合にのみ使う

パス C/D/E の場合は、判断したパス（または混合分解）をユーザーに提示し、先へ進む前に確認を取る。
パス A/B の場合は、次のアクションを推奨して停止する。

### ステップ 3: 詳細なコンテキストの読み込み

**パス C、D、E の場合のみ。** ここでディスカバリーに必要なコンテキストを読み込む。

**メインコンテキストで行う**（ユーザーとの対話に不可欠）:
- **ステアリングドキュメント**: プロジェクトの目標、制約、技術スタックを把握するため、product.md と tech.md を（存在すれば）読む
- **関連する仕様**: リクエストが既存の仕様に隣接する場合は、その仕様の requirements.md を読み、境界を理解して重複を避ける

**Agent ツールでサブエージェントに委任する**（探索をメインコンテキストの外に保つ）:
- **コードベースの探索**: サブエージェントをディスパッチしてコードベースを探索させ、構造化された要約を返させる。プロンプト例: "Explore this project's codebase. Summarize: (1) tech stack and frameworks, (2) directory structure and key modules, (3) patterns and conventions used, (4) areas relevant to [user's request]. Return a summary under 200 lines."（訳: 「このプロジェクトのコードベースを探索せよ。(1) 技術スタックとフレームワーク、(2) ディレクトリ構造と主要モジュール、(3) 使われているパターンと規約、(4) [ユーザーのリクエスト] に関連する領域、を要約せよ。200 行未満の要約を返せ。」）
- サブエージェントは Read/Glob/Grep を使って探索し、結果を返す。メインコンテキストに入るのは要約だけである。
- パス D/E の場合は、自然な領域境界、既存のモジュール分割、そしてどの領域が既存仕様の拡張に見え、どの領域が新しい境界に見えるかも特定するようサブエージェントに依頼する。
- ステップ 1 のトップレベルのディレクトリ一覧で十分な、小さい／自明なリクエストでは、サブエージェントのディスパッチをスキップする。

**コンテキスト予算**: メインコンテキストに読み込む内容の合計を約 500 行未満に保つ。重い探索はサブエージェントが担う。

### ステップ 4: アイデアの理解

明確化のための質問は（一度にすべてではなく）**順番に**行い、機能の詳細よりも境界の発見を優先する。

1. **誰が、なぜ**: 誰が問題を抱えているか。それはどんな苦痛を引き起こしているか。
2. **望ましい結果**: これが完了したとき、何が成り立っているべきか。
3. **境界候補**: この作業における自然な責務の継ぎ目はどこか。実装を独立して進められるように分割できるのはどこか。
4. **境界外**: 関連していても、この仕様が明示的に所有すべきでないものは何か。
5. **既存か新規か**: どの部分が既存仕様の拡張に見え、どの部分が本当に新しい境界に見えるか。
6. **上流／下流**: これはどの既存システム、仕様、コンポーネントに依存しているか。将来のどの作業がこれに依存しそうか。
7. **制約**: 技術、スケジュール、互換性の制約はあるか。

すでに読み込んだコンテキストから答えを推測できない質問だけを行う。ステアリングドキュメントがすでに答えている質問はスキップする。ユーザーがすでに明確な説明をしている場合は、ステップ 5 へ飛ぶ。
目的は、まだ最終的な担当を割り当てることではない。目的は、後で仕様、タスク、レビュースコープになり得る、最もきれいな責務境界を発見することである。

### ステップ 5: アプローチの提案

トレードオフを付けて、**2〜3 個の具体的なアプローチ**を提案する。

各アプローチについて:
- **アプローチ名**: 1 行の要約
- **仕組み**: 技術的アプローチについて 2〜3 文
- **長所**: このアプローチの良い点
- **短所**: リスクや欠点
- **スコープ見積もり**: おおよその複雑さ（small / medium / large）

技術調査が必要な場合（馴染みのないフレームワーク、ライブラリの評価など）は、Agent ツールでサブエージェントをディスパッチする。プロンプト例: "Research [topic]: compare options, check latest versions, note known issues. Return a summary of findings with recommendation."（訳: 「[トピック] を調査せよ。選択肢を比較し、最新バージョンを確認し、既知の問題を記録せよ。推奨を付けた調査結果の要約を返せ。」）サブエージェントは WebSearch/WebFetch を使い、簡潔な要約を返す。生の検索結果がメインコンテキストに入ることは決してない。

1 つのアプローチを推奨し、その理由を説明する。

**ユーザーがアプローチを選択した後**、ステップ 6 へ進む前にサブエージェントをディスパッチして実現可能性を確認する。プロンプト例: "Verify the viability of this technical approach: [chosen tech stack / key libraries]. Check: (1) Are these technologies still actively maintained? (2) Any license incompatibilities (e.g., GPL contamination)? (3) Do the components actually work together for [use case]? (4) Any known showstoppers (critical bugs, security vulnerabilities, platform limitations)? Return only issues found, or 'No issues found' if everything checks out."（訳: 「この技術的アプローチの実現可能性を確認せよ: [選択した技術スタック／主要ライブラリ]。確認事項: (1) これらの技術は今も活発にメンテナンスされているか。(2) ライセンスの非互換（例: GPL 汚染）はないか。(3) 各コンポーネントは [ユースケース] のために実際に連携して動作するか。(4) 既知の致命的問題（重大なバグ、セキュリティ脆弱性、プラットフォームの制限）はないか。見つかった問題のみを返し、すべて問題なければ 'No issues found' と返せ。」）

実現可能性の確認で問題が判明した場合は、それをユーザーに提示し、アプローチの選択をやり直す。問題がなければステップ 6 へ進む。

### ステップ 6: 洗練と確認

- アプローチに関するユーザーの質問や懸念に対応する
- 必要に応じてスコープを絞る: より小さく提供可能なインクリメントと、よりきれいな責務の継ぎ目を優先する
- パス D/E の場合: 依存関係の順序を付けた作業の分解を提案する
  - 境界に値する新しい機能 1 つ = 仕様 1 つ
  - 既存仕様の拡張は、対象の仕様とともに明示的に列挙する
  - 本当に小さい直接実装の項目は、無理に仕様へ押し込まず、別に列挙する
  - 仕様間／ワークストリーム間の依存関係を明示する
  - プロジェクトのニーズに基づき、垂直スライス（エンドツーエンドの価値）か水平レイヤー（一度に 1 層ずつ）かを検討する
- 最終的な方向性を確認する

### ステップ 7: ファイルをディスクに書き込む

**CRITICAL: 次のコマンドを提案する前に、必ず Write ツールを使ってこれらのファイルを作成しなければならない。会話のテキストはセッションの境界を越えて残らない。このステップを飛ばすと、セッション終了時にディスカバリーの分析がすべて失われる。**

**パス C（単一仕様）の場合**:

Write ツールを使い、次の構造で `.kiro/specs/<feature-name>/brief.md` を作成する。

```
# Brief: <feature-name>

## Problem
[誰が問題を抱えているか、それがどんな苦痛を引き起こしているか]

## Current State
[現在何が存在するか、何が不足しているか]

## Desired Outcome
[完了時に何が成り立っているべきか]

## Approach
[選択したアプローチとその理由]

## Scope
- **In**: [この機能に含まれるもの]
- **Out**: [明示的に除外されるもの]

## Boundary Candidates
- [責務の継ぎ目 1]
- [責務の継ぎ目 2]

## Out of Boundary
- [この仕様が所有しない、明示的な非ゴール]

## Upstream / Downstream
- **Upstream**: [これが依存する既存のシステム／仕様]
- **Downstream**: [想定される利用者、または後続の仕様]

## Existing Spec Touchpoints
- **Extends**: [この作業が更新する既存の仕様（あれば）]
- **Adjacent**: [重複を避けるべき隣接する仕様やモジュール]

## Constraints
[技術、互換性、その他の制約]
```

（見出しの意味: Problem=問題、Current State=現状、Desired Outcome=望ましい結果、Approach=アプローチ、Scope=スコープ、Boundary Candidates=境界候補、Out of Boundary=境界外、Upstream / Downstream=上流／下流、Existing Spec Touchpoints=既存仕様との接点、Extends=拡張対象、Adjacent=隣接、Constraints=制約）

**パス D（複数仕様への分解）の場合**:

Write ツールを使って以下を作成する。
- `.kiro/steering/roadmap.md`
- `## Specs (dependency order)` の下に列挙されたすべての機能について `.kiro/specs/<feature>/brief.md`

ロードマップは次の構造を使う。

```
# Roadmap

## Overview
[プロジェクトの目標と選択したアプローチ -- 1〜2 段落]

## Approach Decision
- **Chosen**: [アプローチ名と要約]
- **Why**: [主な理由]
- **Rejected alternatives**: [検討したものと、それを却下した理由]

## Scope
- **In**: [プロジェクト全体に含まれるもの]
- **Out**: [明示的に除外されるもの]

## Constraints
[技術、互換性、スケジュール、その他プロジェクト全体の制約]

## Boundary Strategy
- **Why this split**: [これらの仕様境界がなぜ独立性を高めるか]
- **Shared seams to watch**: [慎重なレビューが必要な、仕様をまたぐ境界]

## Specs (dependency order)
- [ ] feature-a -- [1 行の説明]. Dependencies: none
- [ ] feature-b -- [1 行の説明]. Dependencies: feature-a
- [ ] feature-c -- [1 行の説明]. Dependencies: feature-a, feature-b
```

（見出しの意味: Overview=概要、Approach Decision=アプローチの決定、Chosen=採用、Why=理由、Rejected alternatives=却下した代替案、Boundary Strategy=境界戦略、Why this split=この分割の理由、Shared seams to watch=注意すべき共有の継ぎ目、Specs (dependency order)=仕様（依存順）、Dependencies=依存先）

次に、`## Specs (dependency order)` の下に列挙された**すべての**機能について、パス C の brief 形式を使って `.kiro/specs/<feature>/brief.md` を作成する。これにより `/kiro-spec-batch` による並列の仕様作成が可能になる。

**パス E（混合分解）の場合**:

パス D と同じロードマップ構造に、次の追加セクションを加えて使う。

```
## Existing Spec Updates
- [ ] existing-feature-a -- [拡張内容の 1 行の説明]. Dependencies: none
- [ ] existing-feature-b -- [拡張内容の 1 行の説明]. Dependencies: feature-a

## Direct Implementation Candidates
- [ ] small-item-a -- [これが直接実装のままである理由]
- [ ] small-item-b -- [これが直接実装のままである理由]

## Specs (dependency order)
- [ ] new-feature-a -- [1 行の説明]. Dependencies: none
- [ ] new-feature-b -- [1 行の説明]. Dependencies: new-feature-a
```

（見出しの意味: Existing Spec Updates=既存仕様の更新、Direct Implementation Candidates=直接実装の候補）

パス E のルール:
- `/kiro-spec-batch` が変更なしでパースできるように、`## Specs (dependency order)` は**新規仕様専用**として確保しておく
- 既存仕様の拡張は `## Existing Spec Updates` の下に記録する
- 本当に仕様不要な作業は `## Direct Implementation Candidates` の下に記録する
- `brief.md` は、`## Specs (dependency order)` の下に列挙された**新規仕様**についてのみ作成する

**再エントリー（roadmap.md が既に存在する場合）**:
Write ツールを使い、次の新規仕様の brief.md を作成する。スコープや順序が変わった場合は Write ツールで roadmap.md を更新し、完了済みの項目と過去のフェーズは保持する。

書き込んだ後、ファイルを読み戻して存在を確認する。

### ステップ 8: 次のステップの提案

次のコマンドを提案して停止する。このスキルから下流の仕様生成を自動的に実行してはならない。

- パス A: 既存の仕様を更新するため `/kiro-spec-requirements {feature}`
- パス B: 仕様を作成せずに直接実装することを推奨する
- パス C: デフォルトは `/kiro-spec-init <feature-name>`
  - 任意の高速パス: ユーザーがすぐに続行することを明示的に望む場合は `/kiro-spec-quick <feature-name>`
- パス D: デフォルトは `/kiro-spec-batch`（roadmap.md の依存順に基づいて全仕様を並列に作成する）
  - 任意の慎重なパス: 残りをバッチ処理する前に最初のスライスを検証したい場合は `/kiro-spec-init <first-feature-name>`
- パス E: 分解のうち新規仕様の部分に基づいて次のコマンドを選ぶ
  - 新規仕様がちょうど 1 つの場合: `/kiro-spec-init <new-feature-name>`
  - 新規仕様が複数ある場合: `/kiro-spec-batch`
  - あわせて、どの既存仕様を `/kiro-spec-requirements <feature>` で見直すべきかを記載する
- 再エントリー: `/kiro-spec-init <next-feature-name>`、または複数の仕様が残っている場合は `/kiro-spec-batch`

分解に既存仕様の更新と直接実装の候補しか含まれない場合は、パス E を使ってはならない。1 つの既存仕様が明らかな置き場所であればパス A を優先し、そうでなければロードマップの項目を作らずに、既存仕様の更新と直接実装の作業を推奨する。

## 重大な制約
- **ディスク上のファイルが継続性の源である**: パス C/D/E では、次のコマンドを提案する前に、必要に応じて brief.md と roadmap.md を作成する。ディスカバリーの結果を会話のテキストだけに残してはならない。

## 安全策とフォールバック

**ロードマップが既に存在する場合（再エントリー）**:
- 質問する前に roadmap.md を読み、プロジェクトのコンテキストを復元する
- 完了済み仕様の状態に基づいて次の仕様を決める
- 次の仕様についてのみ brief.md を書く（ジャストインタイム）
- 実装での経験に基づいてスコープや順序が変わった場合は roadmap.md を更新する
- リクエストがプロジェクトを拡大する場合は、新しい仕様を新しいフェーズとして追記し、既存の内容を上書きしない
