# ML-llama-cpp-80-86-89-90-100

Your prebuilt llama.cpp binaries on a **stock RunPod pod, via git — no Docker.**
Build the CUDA binaries in CI, publish to the HF dataset, clone-and-serve on a pod.

The old Docker image existed for one reason: the binaries were built on HF
Spaces (Debian 12, glibc 2.38) and RunPod's Ubuntu 22.04 templates ship glibc
2.35, so they wouldn't load. The image papered over that with an `ubuntu24.04`
base. We don't need an image for that — we `git clone` this repo onto the pod,
and (once the CI workflow has rebuilt the binaries on glibc 2.35) they load on
**every** template.

## One-time: launch the pod

- **GPU:** RTX 6000 Ada (48 GB) — fits two E4B GGUFs at full offload easily.
- **Template:** until the CI rebuild lands, use an **Ubuntu 24.04 / CUDA 12.8**
  template (glibc ≥ 2.39). The current dataset binaries need glibc 2.38;
  `setup.sh` checks this first and aborts loudly if the pod is too old.

## On the pod

```bash
git clone https://github.com/JuiceB0xC0de/ML-llama-cpp-80-86-89-90-100.git
cd ML-llama-cpp-80-86-89-90-100

./setup.sh          # glibc guard + pull binaries from the HF dataset -> /app/bin
./get-models.sh     # download Bella + teacher GGUFs -> /workspace/models
./serve-dual.sh     # Bella :8080, teacher :8081  (logs in /workspace/*.log)
```

Then, in a second shell:

```bash
python3 ask.py      # ask both models in unison, side by side
```

## Rebuilding the binaries (GitHub Actions, no Docker, no HF Space)

`.github/workflows/build-binaries.yml` compiles llama.cpp for SM
80/86/89/90/100 on an `ubuntu-22.04` runner (glibc 2.35 → widest RunPod
compat), bundles the CUDA libs, and `hf upload`s `bin/` + `lib/` to the dataset
`juiceb0xc0de/llama-cpp-cu12-8-sm-80-86-89-90-100`.

- Needs one repo secret: **`HF_TOKEN`** (a write token). Add it in
  *Settings → Secrets and variables → Actions*.
- Run it from the **Actions** tab (`workflow_dispatch`), or it triggers on
  pushes that touch the workflow or `wrapper/`.

## Knobs (env vars)

| var | default | what |
|---|---|---|
| `APP_DIR` | `/app` | where binaries land |
| `MODELS_DIR` | `/workspace/models` | where GGUFs land |
| `BELLA_REPO` / `BELLA_QUANT` | `juiceb0xc0de/bella-bartender-gemma-e4b-GGUF` / `Q8_0` | student model |
| `TEACHER_REPO` / `TEACHER_QUANT` | `mradermacher/gemma-4-E4B-GGUF` / `Q8_0` | base E4B teacher |
| `NGL` | `99` | GPU layers (full offload) |
| `CTX` | `8192` | context length |

## What's where

- `setup.sh` — pulls binaries from the HF dataset (glibc-guarded). Replaces the Dockerfile.
- `get-models.sh` — downloads the two GGUFs (quant via glob, exact names not needed up front).
- `serve.sh` — single server (the old Docker `CMD`).
- `serve-dual.sh` — both models side by side on one GPU.
- `ask.py` — fan-out REPL; keeps history per model so nothing is cold-started.
- `.github/workflows/build-binaries.yml` — CI that rebuilds + publishes the binaries.
- `wrapper/run-llama-server` — runtime `LD_LIBRARY_PATH` glue (source-controlled).
- `Dockerfile`, `README.txt` — legacy, kept for reference. Not used by this flow.

## Auth

Public dataset needs no token. Model downloads: log in on the pod yourself
(`hf auth login` or export `HF_TOKEN`) if either repo is gated. The scripts
never touch tokens.
