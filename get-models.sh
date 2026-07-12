#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# get-models.sh — pull the two GGUFs to serve side by side.
#   Bella (persona)      <- juiceb0xc0de/bella-bartender-gemma-e4b-GGUF
#   Teacher (base E4B)   <- mradermacher/gemma-4-E4B-GGUF
# Override any REPO/QUANT via env. Uses --include glob so the exact quant
# filename doesn't have to be known ahead of time.
# ---------------------------------------------------------------------------
set -euo pipefail

MODELS_DIR="${MODELS_DIR:-/workspace/models}"
mkdir -p "$MODELS_DIR"
HF_BIN="$(command -v hf || command -v huggingface-cli)"
export HF_HUB_ENABLE_HF_TRANSFER=1

BELLA_REPO="${BELLA_REPO:-juiceb0xc0de/bella-bartender-gemma-e4b-GGUF}"
BELLA_QUANT="${BELLA_QUANT:-Q8_0}"
TEACHER_REPO="${TEACHER_REPO:-mradermacher/gemma-4-E4B-GGUF}"
TEACHER_QUANT="${TEACHER_QUANT:-Q8_0}"

echo "==> Bella:   $BELLA_REPO  (*${BELLA_QUANT}*.gguf)"
"$HF_BIN" download "$BELLA_REPO"   --include "*${BELLA_QUANT}*.gguf" --local-dir "$MODELS_DIR/bella"

echo "==> Teacher: $TEACHER_REPO  (*${TEACHER_QUANT}*.gguf)"
"$HF_BIN" download "$TEACHER_REPO" --include "*${TEACHER_QUANT}*.gguf" --local-dir "$MODELS_DIR/teacher"

echo "==> downloaded:"
find "$MODELS_DIR" -name '*.gguf' -exec ls -lh {} \; | awk '{print "   "$5"  "$9}'
