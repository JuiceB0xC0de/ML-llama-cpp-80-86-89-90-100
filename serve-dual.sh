#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# serve-dual.sh — both models side by side on one RTX 6000 Ada (48 GB).
#   Bella   -> :8080   (alias "bella")
#   Teacher -> :8081   (alias "teacher")
# Two E4B GGUFs + KV cache fit with room to spare; full GPU offload (-ngl 99).
# Logs to /workspace/*.log. Ctrl-C stops both.
# ---------------------------------------------------------------------------
set -euo pipefail

APP_DIR="${APP_DIR:-/app}"
MODELS_DIR="${MODELS_DIR:-/workspace/models}"
RLS="$APP_DIR/bin/run-llama-server"
NGL="${NGL:-99}"
CTX="${CTX:-8192}"
LOGDIR="${LOGDIR:-/workspace}"

BELLA_GGUF="${BELLA_GGUF:-$(find "$MODELS_DIR/bella"   -name '*.gguf' 2>/dev/null | head -1)}"
TEACHER_GGUF="${TEACHER_GGUF:-$(find "$MODELS_DIR/teacher" -name '*.gguf' 2>/dev/null | head -1)}"

[ -n "$BELLA_GGUF"   ] && [ -f "$BELLA_GGUF"   ] || { echo "no Bella GGUF — run ./get-models.sh" >&2; exit 1; }
[ -n "$TEACHER_GGUF" ] && [ -f "$TEACHER_GGUF" ] || { echo "no teacher GGUF — run ./get-models.sh" >&2; exit 1; }

echo "Bella   :8080  $BELLA_GGUF"
"$RLS" -m "$BELLA_GGUF"   --host 0.0.0.0 --port 8080 -ngl "$NGL" -c "$CTX" --alias bella   >"$LOGDIR/bella.log"   2>&1 &
BPID=$!
echo "Teacher :8081  $TEACHER_GGUF"
"$RLS" -m "$TEACHER_GGUF" --host 0.0.0.0 --port 8081 -ngl "$NGL" -c "$CTX" --alias teacher >"$LOGDIR/teacher.log" 2>&1 &
TPID=$!

trap 'echo; echo "stopping..."; kill "$BPID" "$TPID" 2>/dev/null' INT TERM
echo
echo "PIDs: bella=$BPID teacher=$TPID   logs: $LOGDIR/{bella,teacher}.log"
echo "Wait for load, then:  curl -s localhost:8080/health ; curl -s localhost:8081/health"
echo "Query both in unison:  python3 ask.py"
wait
