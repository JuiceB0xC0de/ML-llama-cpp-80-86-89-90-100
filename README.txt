Rick — this Dockerfile fixes the glibc mismatch.

Problem:
  HF Spaces built your llama.cpp binary on Debian 12 (glibc 2.38).
  RunPod Ubuntu 22.04 images only have glibc 2.35.
  The binary refuses to load.

Fix:
  This image uses nvidia/cuda:12.8.1-runtime-ubuntu24.04
  which has glibc 2.39 — higher than 2.38, so the binary loads.

Where to find it:
  /Users/chiggy/docker-llama-cpp-runpod/Dockerfile

Build + push:
  docker build -t juiceboxdocks/llama-cpp-cu12-8-sm-80-86-89-90-100:latest .
  docker push juiceboxdocks/llama-cpp-cu12-8-sm-80-86-89-90-100:latest

Then on RunPod, use image:
  juiceboxdocks/llama-cpp-cu12-8-sm-80-86-89-90-100:latest

How binaries get in:
  A 2-stage build. Stage 1 (python:3.12-slim) runs `hf download` on the
  public dataset:
    juiceb0xc0de/llama-cpp-cu12-8-sm-80-86-89-90-100
  pulling bin/ (llama-cli, llama-quantize, llama-server + run-llama-server
  wrapper) and lib/ (cublas, cublasLt, cudart, nvJitLink). Stage 2 copies
  only /app into the cuda-runtime image — no python/huggingface_hub in the
  final image.

  The container runs `run-llama-server`, a wrapper that sets
  LD_LIBRARY_PATH=/app/lib before exec'ing llama-server, so the binaries
  use their own bundled CUDA libs and the image is self-contained.

  To update binaries: re-push the HF dataset, then rebuild (no cache:
  `docker build --no-cache ...`).
