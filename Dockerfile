# ---- Stage 1: fetch prebuilt binaries + libs from the HF dataset ----
# Kept separate so python/huggingface_hub never land in the final image.
FROM python:3.12-slim AS fetch

RUN pip install --no-cache-dir "huggingface_hub[hf_transfer]"

ENV HF_HUB_ENABLE_HF_TRANSFER=1

# Public dataset — no token needed. bin/ (llama-cli, llama-quantize,
# llama-server, run-llama-server wrapper) + lib/ (cublas, cublasLt,
# cudart, nvJitLink) land under /out.
RUN hf download juiceb0xc0de/llama-cpp-cu12-8-sm-80-86-89-90-100 \
      --repo-type dataset \
      --local-dir /out

# ---- Stage 2: runtime ----
# cuda 12.8.1 runtime on ubuntu 24.04 (glibc 2.39). The shipped binaries
# were built on Debian 12 (glibc 2.38); 2.39 >= 2.38, so they load. The
# wrapper points LD_LIBRARY_PATH at the bundled lib/, so this image is
# self-contained regardless of what the base image ships.
FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

COPY --from=fetch /out/bin /app/bin
COPY --from=fetch /out/lib /app/lib

RUN chmod +x /app/bin/llama-cli \
             /app/bin/llama-quantize \
             /app/bin/llama-server \
             /app/bin/run-llama-server

ENV PATH="/app/bin:${PATH}"

EXPOSE 8080

# run-llama-server sets LD_LIBRARY_PATH=/app/lib then execs llama-server.
CMD ["run-llama-server", "--host", "0.0.0.0", "--port", "8080"]
