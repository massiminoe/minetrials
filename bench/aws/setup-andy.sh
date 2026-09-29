#!/usr/bin/env bash
# Run on the ephemeral GPU VM, before the benchmark clock starts.
set -euo pipefail
ART=$(realpath "$1")
PILOT=true
[[ "${2:-pilot}" == "trial" ]] && PILOT=false
mkdir -p "$ART"
exec > >(tee "$ART/setup.log") 2>&1
nvidia-smi > "$ART/nvidia-smi.txt"
MODEL_REV=d3efcb8137c88cd3c23466ddabf985ea59b52fdf
MODEL_DIR="$HOME/.lmstudio/models/Mindcraft-CE/Andy-4.2-GGUF"
mkdir -p "$MODEL_DIR"
for file in andy-4.2.q8_0.gguf mmproj-BF16.gguf; do
    [[ -f "$MODEL_DIR/$file.complete" ]] && continue
    if command -v aria2c >/dev/null 2>&1; then
        aria2c --max-connection-per-server=8 --split=8 --min-split-size=16M \
            --summary-interval=30 --console-log-level=warn --download-result=hide \
            --dir="$MODEL_DIR" --out="$file" \
            "https://huggingface.co/Mindcraft-CE/Andy-4.2-GGUF/resolve/$MODEL_REV/$file"
    else
        curl --fail --location --retry 3 \
            "https://huggingface.co/Mindcraft-CE/Andy-4.2-GGUF/resolve/$MODEL_REV/$file" \
            --output "$MODEL_DIR/$file"
    fi
    touch "$MODEL_DIR/$file.complete"
done
(cd "$MODEL_DIR" && sha256sum *.gguf) > "$ART/model-sha256.txt"
if [[ ! -x "$HOME/.lmstudio/bin/lms" ]]; then
    curl --fail --location https://lmstudio.ai/install.sh -o /tmp/lmstudio-install.sh
    bash /tmp/lmstudio-install.sh
fi
export PATH="$HOME/.lmstudio/bin:$PATH"
lms --version > "$ART/lms-version.txt"
lms daemon up
lms runtime get llama.cpp:cuda -y
lms runtime ls > "$ART/runtime-versions.txt"
lms load andy-4.2 --yes \
    --identifier andy-4.2 --context-length 32768 --gpu max </dev/null
# Listen only on Docker's host bridge; no public inference port is opened.
DOCKER_IP=$(ip -4 addr show docker0 | awk '/inet / {split($2,a,"/"); print a[1]}')
test -n "$DOCKER_IP"
lms server start --port 1234 --bind "$DOCKER_IP"
curl --fail --retry 3 "http://$DOCKER_IP:1234/v1/models" > "$ART/models.json"
lms ps > "$ART/loaded-models.txt"
cat > "$ART/settings.json" <<JSON
{"model":"Mindcraft-CE/Andy-4.2-GGUF","revision":"$MODEL_REV","quantization":"Q8_0","context":32768,"serving":"LM Studio llmster","pilot":$PILOT}
JSON
