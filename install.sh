#!/usr/bin/env bash
set -euo pipefail

REPO="Jasmine-dong/skill_flow"
REF="${PIPELINE_COMMANDER_REF:-main}"
TARGET="auto"
PROJECT_DIR="$PWD"

usage() {
  cat <<'USAGE'
Pipeline Commander installer

Usage:
  ./install.sh [--target auto|codex|claude|agents|all] [--project-dir PATH]

Examples:
  curl -fsSL https://raw.githubusercontent.com/Jasmine-dong/skill_flow/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/Jasmine-dong/skill_flow/main/install.sh | bash -s -- --target all
  ./install.sh --target claude

Targets:
  auto    Install for detected tools. Falls back to project AGENTS.md.
  codex   Install Codex skill into ${CODEX_HOME:-~/.codex}/skills.
  claude  Install Claude Code slash command into ~/.claude/commands.
  agents  Install project-local AGENTS.md and shared resources.
  all     Install codex, claude, and agents adapters.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --project-dir)
      PROJECT_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$TARGET" in
  auto|codex|claude|agents|all) ;;
  *)
    echo "Invalid target: $TARGET" >&2
    exit 1
    ;;
esac

TMP_DIR=""
cleanup() {
  if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

SCRIPT_PATH="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/install.sh" ] && [ -d "$SCRIPT_DIR/shared" ] && [ -d "$SCRIPT_DIR/adapters" ]; then
  SRC_DIR="$SCRIPT_DIR"
else
  TMP_DIR="$(mktemp -d)"
  ARCHIVE_URL="https://github.com/$REPO/archive/refs/heads/$REF.tar.gz"
  echo "Downloading $REPO@$REF..."
  curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$TMP_DIR" --strip-components=1
  SRC_DIR="$TMP_DIR"
fi

copy_dir() {
  local src="$1"
  local dest="$2"
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"
}

install_codex() {
  local codex_home="${CODEX_HOME:-$HOME/.codex}"
  local dest="$codex_home/skills/pipeline-commander"
  mkdir -p "$dest/references" "$dest/assets"
  cp "$SRC_DIR/adapters/codex/SKILL.md" "$dest/SKILL.md"
  copy_dir "$SRC_DIR/adapters/codex/agents" "$dest/agents"
  cp "$SRC_DIR/shared/tasks.yaml" "$dest/references/tasks.yaml"
  copy_dir "$SRC_DIR/shared/roles" "$dest/references/roles"
  cp "$SRC_DIR/shared/pipeline.project.yaml.example" "$dest/assets/pipeline.project.yaml.example"
  cp "$SRC_DIR/shared/project-details.md" "$dest/assets/project-details.md"
  copy_dir "$SRC_DIR/shared/feature-template" "$dest/assets/feature-template"
  echo "Installed Codex skill: $dest"
  echo "Restart Codex to pick up the skill."
}

install_claude() {
  local claude_home="${CLAUDE_HOME:-$HOME/.claude}"
  local command_dest="$claude_home/commands/pipeline-commander.md"
  local resource_dest="$claude_home/pipeline-commander"
  mkdir -p "$claude_home/commands" "$resource_dest/references" "$resource_dest/assets"
  cp "$SRC_DIR/adapters/claude-code/commands/pipeline-commander.md" "$command_dest"
  cp "$SRC_DIR/shared/tasks.yaml" "$resource_dest/references/tasks.yaml"
  copy_dir "$SRC_DIR/shared/roles" "$resource_dest/references/roles"
  cp "$SRC_DIR/shared/pipeline.project.yaml.example" "$resource_dest/assets/pipeline.project.yaml.example"
  cp "$SRC_DIR/shared/project-details.md" "$resource_dest/assets/project-details.md"
  copy_dir "$SRC_DIR/shared/feature-template" "$resource_dest/assets/feature-template"
  echo "Installed Claude Code command: $command_dest"
  echo "Use /pipeline-commander <feature-id> in Claude Code."
}

install_agents() {
  local project_dir
  project_dir="$(cd "$PROJECT_DIR" && pwd)"
  local resource_dest="$project_dir/.agent-pipeline-commander"
  mkdir -p "$resource_dest/references" "$resource_dest/assets"
  cp "$SRC_DIR/adapters/agents/AGENTS.md" "$project_dir/AGENTS.md"
  cp "$SRC_DIR/shared/tasks.yaml" "$resource_dest/references/tasks.yaml"
  copy_dir "$SRC_DIR/shared/roles" "$resource_dest/references/roles"
  cp "$SRC_DIR/shared/pipeline.project.yaml.example" "$resource_dest/assets/pipeline.project.yaml.example"
  cp "$SRC_DIR/shared/project-details.md" "$resource_dest/assets/project-details.md"
  copy_dir "$SRC_DIR/shared/feature-template" "$resource_dest/assets/feature-template"
  echo "Installed project agent instructions: $project_dir/AGENTS.md"
  echo "Installed project resources: $resource_dest"
}

installed_any=0

if [ "$TARGET" = "all" ] || [ "$TARGET" = "codex" ]; then
  install_codex
  installed_any=1
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "claude" ]; then
  install_claude
  installed_any=1
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "agents" ]; then
  install_agents
  installed_any=1
fi

if [ "$TARGET" = "auto" ]; then
  if [ -d "${CODEX_HOME:-$HOME/.codex}" ]; then
    install_codex
    installed_any=1
  fi
  if [ -d "${CLAUDE_HOME:-$HOME/.claude}" ]; then
    install_claude
    installed_any=1
  fi
  if [ "$installed_any" -eq 0 ]; then
    install_agents
    installed_any=1
  fi
fi

echo "Done."
