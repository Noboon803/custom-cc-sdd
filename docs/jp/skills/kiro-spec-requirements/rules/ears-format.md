> 原文: `.claude/skills/kiro-spec-requirements/rules/ears-format.md`（cc-sdd v3.0.2）の日本語訳。参照用であり、Claude Code はこのファイルを読み込まない。

# EARS 形式のガイドライン

## 概要
EARS（Easy Approach to Requirements Syntax）は、仕様駆動開発における受け入れ基準の標準形式である。

EARS パターンは要件の論理構造（条件 + 主語 + 応答）を記述するものであり、特定の自然言語に縛られない。  
すべての受け入れ基準は、仕様に設定された対象言語（例えば `spec.json.language` / `ja`）で書くべきである。  
EARS のトリガーキーワードと固定フレーズ（`When`、`If`、`While`、`Where`、`The system shall`、`The [system] shall`）は英語のまま残し、可変部分（`[event]`（イベント）、`[precondition]`（前提条件）、`[trigger]`（トリガー）、`[feature is included]`（機能が含まれている）、`[response/action]`（応答／動作））だけを対象言語にローカライズする。トリガーや英語の固定フレーズそのものの内部に、対象言語のテキストを差し込んではならない。

## 主要な EARS パターン

### 1. イベント駆動の要件
- **パターン**: When [event], the [system] shall [response/action]
- **用途**: 特定のイベントやトリガーへの応答
- **例**: When user clicks checkout button, the Checkout Service shall validate cart contents（ユーザーがチェックアウトボタンをクリックしたとき、Checkout Service はカートの中身を検証する）

### 2. 状態駆動の要件
- **パターン**: While [precondition], the [system] shall [response/action]
- **用途**: システムの状態や前提条件に依存する振る舞い
- **例**: While payment is processing, the Checkout Service shall display loading indicator（支払い処理中は、Checkout Service はローディング表示を出す）

### 3. 望ましくない振る舞いの要件
- **パターン**: If [trigger], the [system] shall [response/action]
- **用途**: エラー、障害、望ましくない状況に対するシステムの応答
- **例**: If invalid credit card number is entered, then the website shall display error message（無効なクレジットカード番号が入力された場合、ウェブサイトはエラーメッセージを表示する）

### 4. オプション機能の要件
- **パターン**: Where [feature is included], the [system] shall [response/action]
- **用途**: オプションまたは条件付きの機能に対する要件
- **例**: Where the car has a sunroof, the car shall have a sunroof control panel（車にサンルーフがある構成では、車はサンルーフの操作パネルを備える）

### 5. 常時適用の要件
- **パターン**: The [system] shall [response/action]
- **用途**: 常に有効な要件と、システムの基本的な特性
- **例**: The mobile phone shall have a mass of less than 100 grams（携帯電話の質量は 100 グラム未満とする）

## 組み合わせパターン
- While [precondition], when [event], the [system] shall [response/action]
- When [event] and [additional condition], the [system] shall [response/action]

## 主語の選び方のガイドライン
- **ソフトウェアプロジェクト**: 具体的なシステム名／サービス名を使う（例: "Checkout Service"、"User Auth Module"）
- **プロセス／ワークフロー**: 責任を持つチーム／役割を使う（例: "Support Team"、"Review Process"）
- **ソフトウェア以外**: 適切な主語を使う（例: "Marketing Campaign"、"Documentation"）

## 品質基準
- 要件はテスト可能かつ検証可能で、単一の振る舞いを記述するものでなければならない。
- 客観的な言葉を使う: 必須の振る舞いには "shall"、推奨には "should" を使い、曖昧な用語は避ける。
- EARS 構文に従う: [condition], the [system] shall [response/action]。
