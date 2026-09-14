---
name: kiro-steering
description: .kiro/steering/ を永続的なプロジェクトメモリとして維持する（bootstrap/sync）。ステアリングドキュメントを初期化または更新するときに使用する。
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
metadata:
  shared-rules: "steering-principles.md"
---

> 原文: `.claude/skills/kiro-steering/SKILL.md`（cc-sdd v3.0.2）の日本語訳。参照用であり、Claude Code はこのファイルを読み込まない。

# kiro-steering スキル

## 役割
あなたは `.kiro/steering/` を永続的なプロジェクトメモリとして維持するための専門スキルである。

## 中核ミッション
**役割**: `.kiro/steering/` を永続的なプロジェクトメモリとして維持する。

**ミッション**:
- Bootstrap（初期構築）: コードベースからコアとなるステアリングを生成する（初回）
- Sync（同期）: ステアリングとコードベースの整合を保つ（保守）
- Preserve（保全）: ユーザーによるカスタマイズは不可侵であり、更新は追記方式で行う

**成功基準**:
- ステアリングは網羅的なリストではなく、パターンと原則を捉えている
- コードのドリフト（ステアリングとコードの乖離）が検出され、報告されている
- すべての `.kiro/steering/*.md` が同等に扱われている（コア + カスタム）

## 実行ステップ

### ステップ 1: コンテキストを収集する

ステアリングのコンテキストが会話内ですでに得られている場合は、冗長なファイル読み込みを省略する。

- Bootstrap モードの場合: `.kiro/settings/templates/steering/` からテンプレートを読む
- Sync モードの場合: 既存の `.kiro/steering/*.md` ファイルをすべて読む
- ステアリングの原則として、このスキルのディレクトリにある `rules/steering-principles.md` を読む

## シナリオ判定

`.kiro/steering/` の状態を確認する:

**Bootstrap モード**: 空である、またはコアファイル（product.md、tech.md、structure.md）が欠けている
**Sync モード**: すべてのコアファイルが存在する

---

## Bootstrap フロー

1. `.kiro/settings/templates/steering/` からテンプレートを読み込む
2. コードベースを分析する（JIT: 必要になった時点で取得する）:

#### 並列リサーチ

以下のリサーチ領域は互いに独立しており、並列に実行できる:
1. **プロダクト分析**: 目的、価値、中核機能を把握するために、README、package.json、ドキュメントファイルを調べる
2. **技術分析**: 技術的なパターンと意思決定を把握するために、設定ファイル、依存関係、フレームワークを調べる
3. **構造分析**: 構成を把握するために、ディレクトリツリー、命名規則、import パターンを調べる

すべての並列リサーチが完了したら、ステアリングファイル用にパターンを統合する。

3. パターンを抽出する（リストではなく）:
   - プロダクト: 目的、価値、中核機能
   - 技術: フレームワーク、意思決定、規約
   - 構造: 構成、命名、import
4. ステアリングファイルを生成する（テンプレートに従う）
5. このスキルのディレクトリにある `rules/steering-principles.md` から原則を読み込む
6. レビュー用に要約を提示する

**重点**: ファイルや依存関係のカタログではなく、意思決定の指針となるパターン。

---

## Sync フロー

1. 既存のステアリング（`.kiro/steering/*.md`）をすべて読み込む
2. コードベースの変更を分析する（JIT）
3. ドリフトを検出する:
   - **ステアリング → コード**: 欠けている要素 → 警告
   - **コード → ステアリング**: 新しいパターン → 更新候補
   - **カスタムファイル**: 関連性を確認する
4. 更新を提案する（追記方式、ユーザーのコンテンツは保全する）
5. 報告する: 更新、警告、推奨事項

**更新の考え方**: 置き換えるのではなく追加する。ユーザーのセクションは保全する。

---

## 粒度の原則

`rules/steering-principles.md`（このスキルのディレクトリ内）より:

> 「新しいコードが既存のパターンに従っているなら、ステアリングを更新する必要はないはずだ。」

網羅的なリストではなく、パターンと原則を記述する。

**悪い例**: ディレクトリツリー内のすべてのファイルを列挙する
**良い例**: 構成パターンを例とともに説明する

## ツールの使い方

- `Glob`: ソースファイル／設定ファイルを探す
- `Read`: ステアリング、ドキュメント、設定を読む
- `Grep`: パターンを検索する
- `Bash` で `ls`: 構造を分析する

**JIT 戦略**: 事前にまとめて取得するのではなく、必要になったときに取得する。

## 出力の説明

チャットでの要約のみ（ファイルは直接更新する）。

### Bootstrap:
```
Steering Created

## Generated:
- product.md: [簡潔な説明]
- tech.md: [主要な技術スタック]
- structure.md: [構成]

Review and approve as Source of Truth.
```
（`Steering Created` は「ステアリングを作成した」、`Generated` は「生成したファイル」、最終行は「Source of Truth（信頼できる唯一の情報源）としてレビューし、承認すること」の意）

### Sync:
```
Steering Updated

## Changes:
- tech.md: React 18 → 19
- structure.md: Added API pattern

## Code Drift:
- Components not following import conventions

## Recommendations:
- Consider api-standards.md
```
（`Steering Updated` は「ステアリングを更新した」、`Changes` は「変更」（例: structure.md に API パターンを追加）、`Code Drift` は「コードのドリフト」（例: import 規約に従っていないコンポーネント）、`Recommendations` は「推奨事項」（例: api-standards.md の作成を検討）の意）

## 例

### Bootstrap
**入力**: 空のステアリング、React TypeScript プロジェクト
**出力**: パターンを記述した 3 ファイル - "Feature-first"、"TypeScript strict"、"React 19"

### Sync
**入力**: 既存のステアリング、新しい `/api` ディレクトリ
**出力**: 更新された structure.md、規約に準拠していないファイルの指摘、api-standards.md の提案

## 安全策とフォールバック

- **セキュリティ**: キー、パスワード、シークレットは決して含めない（原則を参照）
- **不確実な場合**: 両方の状態を報告し、ユーザーに確認する
- **保全**: 迷ったときは置き換えるより追加する

## 注記

- すべての `.kiro/steering/*.md` はプロジェクトメモリとして読み込まれる
- テンプレートと原則は、カスタマイズできるよう外部ファイルになっている
- カタログではなくパターンに重点を置く
- 「Golden Rule（黄金律）」: パターンに従う新しいコードであれば、ステアリングの更新は必要ないはずである
- `.kiro/settings/` の内容はステアリングファイルに記述してはならない（settings はメタデータであり、プロジェクトの知識ではない）
