#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# setup.sh — the Docker image, minus Docker.
#
# Pulls your prebuilt llama.cpp binaries (built on HF Spaces / Debian 12) out
# of the public HF dataset and drops them at $APP_DIR/bin, exactly like the
# 2-stage Dockerfile did — but as a clone-and-run script on a stock RunPod pod.
# No image build, no registry push.
#
# The ONLY thing that can break this is glibc: the binaries need >= 2.38.
# That check is the first thing we do, and it fails loud with the fix.
# ---------------------------------------------------------------------------
set -euo pipefail

APP_DIR="${APP_DIR:-/app}"
DATASET="juiceb0xc0de/llama-cpp-cu12-8-sm-80-86-89-90-100"
NEED_GLIBC="2.38"

echo "==> glibc guard (binaries built on Debian 12, need >= ${NEED_GLIBC})"
HAVE_GLIBC="$(ldd --version | head -1 | grep -oE '[0-9]+\.[0-9]+$')"
# If the smaller of {need, have} is NOT need, then have < need -> abort.
if [ "$(printf '%s\n%s\n' "$NEED_GLIBC" "$HAVE_GLIBC" | sort -V | head -1)" != "$NEED_GLIBC" ]; then
  cat >&2 <<EOF
ERROR: this pod ships glibc ${HAVE_GLIBC}, but the binaries need >= ${NEED_GLIBC}.

  RunPod's Ubuntu 22.04 templates ship glibc 2.35 and WILL NOT load these.
  Relaunch the pod on an Ubuntu 24.04 / CUDA 12.8 template (glibc 2.39).

This is the exact mismatch the old Docker image papered over with an
ubuntu24.04 base — here we just pick the right template instead.
EOF
  exit 1
fi
echo "    glibc ${HAVE_GLIBC} OK"

echo "==> GPU"
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader || {
  echo "WARN: nvidia-smi failed — is this a GPU pod?" >&2
}

echo "==> fetching prebuilt binaries + CUDA libs from ${DATASET}"
pip install --no-cache-dir -q "huggingface_hub[hf_transfer]"
export HF_HUB_ENABLE_HF_TRANSFER=1
HF_BIN="$(command -v hf || command -v huggingface-cli)"
"$HF_BIN" download "$DATASET" --repo-type dataset --local-dir "$APP_DIR"

chmod +x "$APP_DIR"/bin/llama-cli \
         "$APP_DIR"/bin/llama-quantize \
         "$APP_DIR"/bin/llama-server \
         "$APP_DIR"/bin/run-llama-server

echo "==> installed to ${APP_DIR}/bin"
ls -1 "$APP_DIR"/bin
echo "==> smoke test"
"$APP_DIR"/bin/run-llama-server --version 2>&1 | head -3 || true
echo "DONE. Next: ./get-models.sh  then  ./serve-dual.sh"
