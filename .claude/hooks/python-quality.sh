#!/usr/bin/env bash
# PostToolUse hook: format, lint, and type-check a Python file Claude just edited.
#
# - ruff format / ruff check --fix are applied automatically.
# - mypy runs only when the project configures it (pyproject.toml [tool.mypy], mypy.ini, setup.cfg [mypy]).
# - Tools are taken from <project>/.venv/bin first, then PATH. Missing tools are skipped.
# - Remaining problems are written to stderr with exit 2 so Claude sees them and fixes the file.
set -uo pipefail

readonly EXIT_BLOCKING=2
readonly PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

read_file_path() {
  python3 -c 'import json, sys; print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))' 2>/dev/null
}

resolve_tool() {
  if [ -x "$PROJECT_DIR/.venv/bin/$1" ]; then
    echo "$PROJECT_DIR/.venv/bin/$1"
  else
    command -v "$1" 2>/dev/null
  fi
}

has_mypy_config() {
  [ -f "$PROJECT_DIR/mypy.ini" ] || [ -f "$PROJECT_DIR/.mypy.ini" ] \
    || grep -qs '^\[tool\.mypy\]' "$PROJECT_DIR/pyproject.toml" \
    || grep -qs '^\[mypy\]' "$PROJECT_DIR/setup.cfg"
}

file_path="$(read_file_path)"
case "$file_path" in
  "$PROJECT_DIR"/*.py) ;;
  *) exit 0 ;;
esac
[ -f "$file_path" ] || exit 0

rel_path="${file_path#"$PROJECT_DIR"/}"
problems=""

add_problem() { # $1=tool label, $2=output
  problems+="[$1]"$'\n'"$2"$'\n\n'
}

ruff="$(resolve_tool ruff)"
if [ -n "$ruff" ]; then
  if ! out="$(cd "$PROJECT_DIR" && "$ruff" format --quiet "$rel_path" 2>&1)"; then
    add_problem "ruff format" "$out"
  fi
  if ! out="$(cd "$PROJECT_DIR" && "$ruff" check --fix --quiet "$rel_path" 2>&1)"; then
    add_problem "ruff check" "$out"
  fi
fi

mypy="$(resolve_tool mypy)"
if [ -n "$mypy" ] && has_mypy_config; then
  out="$(cd "$PROJECT_DIR" && "$mypy" --no-error-summary "$rel_path" 2>&1)"
  case $? in
    0) ;;
    1) # type errors: report only those in the edited file
      own_errors="$(printf '%s\n' "$out" | grep -F "$rel_path:")"
      [ -n "$own_errors" ] && add_problem "mypy" "$own_errors"
      ;;
    *) add_problem "mypy (failed to run)" "$out" ;;
  esac
fi

if [ -n "$problems" ]; then
  printf 'Python quality checks found problems in %s (auto-fixes were already applied). Fix these before continuing:\n\n%s' \
    "$rel_path" "$problems" >&2
  exit "$EXIT_BLOCKING"
fi
exit 0
