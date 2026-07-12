#!/usr/bin/env python3
"""Query Bella (:8080) and the teacher (:8081) in unison — side by side.

Type a prompt; both models answer. Conversation history is kept PER MODEL,
so neither is ever cold-started mid-run — every turn carries the full warm
context. Warm up with a few real turns before you trust any teacher output.

Stdlib only (no pip installs on the pod). OpenAI-compatible /v1 endpoints.
"""
import json
import sys
import urllib.request

ENDPOINTS = {
    "BELLA":   "http://localhost:8080/v1/chat/completions",
    "TEACHER": "http://localhost:8081/v1/chat/completions",
}
SYSTEM = ""          # set a system prompt here if you want one on both
TEMPERATURE = 0.7
MAX_TOKENS = 512

hist = {name: ([{"role": "system", "content": SYSTEM}] if SYSTEM else [])
        for name in ENDPOINTS}


def ask(url, messages):
    body = json.dumps({
        "messages": messages,
        "temperature": TEMPERATURE,
        "max_tokens": MAX_TOKENS,
        "stream": False,
    }).encode()
    req = urllib.request.Request(
        url, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=600) as r:
        data = json.load(r)
    return data["choices"][0]["message"]["content"].strip()


def main():
    print("Ask both models. Ctrl-D or 'quit' to exit. History kept per model (warm).")
    while True:
        try:
            prompt = input("\n>>> ").strip()
        except EOFError:
            print()
            break
        if not prompt:
            continue
        if prompt in ("quit", "exit"):
            break
        for name, url in ENDPOINTS.items():
            hist[name].append({"role": "user", "content": prompt})
            try:
                out = ask(url, hist[name])
                hist[name].append({"role": "assistant", "content": out})
            except Exception as e:              # noqa: BLE001
                hist[name].pop()                # don't poison history on failure
                out = f"[error talking to {name} at {url}: {e}]"
            print(f"\n===== {name} =====\n{out}")


if __name__ == "__main__":
    sys.exit(main())
