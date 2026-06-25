#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

"$ROOT_DIR/install.sh" --target agents --project-dir "$TMP_DIR" >/dev/null

diff -ru "$ROOT_DIR/adapters/agents/AGENTS.md" "$TMP_DIR/AGENTS.md"
diff -ru "$ROOT_DIR/shared/tasks.yaml" "$TMP_DIR/.agent-pipeline-commander/references/tasks.yaml"
diff -ru "$ROOT_DIR/shared/roles" "$TMP_DIR/.agent-pipeline-commander/references/roles"
diff -ru "$ROOT_DIR/shared/pipeline.project.yaml.example" "$TMP_DIR/.agent-pipeline-commander/assets/pipeline.project.yaml.example"
diff -ru "$ROOT_DIR/shared/project-details.md" "$TMP_DIR/.agent-pipeline-commander/assets/project-details.md"
diff -ru "$ROOT_DIR/shared/feature-template" "$TMP_DIR/.agent-pipeline-commander/assets/feature-template"

echo "install artifacts ok"

