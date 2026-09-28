# Andy 4.2 pilot

This is a compatibility pilot only. No four-trial sweep is scheduled or started.
It uses OpenCode 1.18.32, the official Andy Q8_0 GGUF and vision projector at
revision `d3efcb8137c88cd3c23466ddabf985ea59b52fdf`, and headless LM Studio with
32,768 context tokens. The primary OpenCode agent requests temperature 0.6 and
top-p 0.95. Other sampling settings retain the server defaults.

One on-demand `g6e.2xlarge` in `us-east-1` runs inference and the existing
software-rendered Minecraft benchmark together. Inference binds to Docker's
host bridge only; there is no public inference port or external model key.
The launcher uses an AWS Deep Learning Ubuntu 24.04 image with GPU drivers and
a 100 GB disposable root disk. The machine terminates after the run, with a
90-minute deadman limit including installation/download/build time.

After committing and pushing the branch, launch **one** pilot:

```sh
AWS_PROFILE=mineclaude-sso bench/aws/launch.sh --andy-pilot \
  --harness opencode --model selfhosted/andy-4.2 --type g6e.2xlarge \
  --seconds 600 --git-ref feat/andy-4.2 --run-id andy-4.2-pilot --no-wait
```

The launcher requires eight on-demand G/VT vCPUs of quota. Initial account quota
was zero; an increase to eight was requested on 2026-09-27. Check AWS Service
Quotas before retrying. Do not launch real trials as a fallback.

Quota request ID: `f5cfd56e4181428cbde3ec97d751e6f2CLVmNvc1`.
AWS support case: `179049897900084`. On 2026-09-28 the quota was approved at
eight vCPUs. All four supported L40S availability zones rejected launches for
insufficient capacity, so the compatibility pilot uses `--type g6.2xlarge`
(L4, 24 GB class VRAM, 32 GiB host RAM, $0.9776/hour on-demand). This is a
compatibility fallback, not the final trial hardware decision. Use `--subnet`
to select a specific availability zone when needed.

The first VM (`andy-4.2-pilot-20260928`) failed before gameplay because cloud-init
did not supply HOME. Model setup now runs through `sudo -H`; the failed VM was
terminated and its setup logs are retained in S3. The retry is
`andy-4.2-pilot-20260928b` loaded Andy successfully but failed to publish the
monitor: NVIDIA's `nv-hostengine` occupies host port 5555 on the GPU image.
The pilot now publishes the monitor on 5557. Parallel downloads shorten setup.

Success requires evidence in the transcript/runtime logs that Andy made a valid
MCP call and successfully acted in the game (for example moving or collecting
wood). An HTTP response alone is insufficient. Check screenshot acceptance,
tool-call parsing, action polling, and whether Andy emits obsolete Mindcraft
commands. The standard benchmark prompt and sandbox remain unchanged.

Artifacts include `inference/` with setup logs, model hashes, model revision,
loaded model and GPU details, plus the standard harness transcripts, runtime
sessions, video and score. Self-hosted token counts remain available; token
cost is `null` rather than a fictitious zero. Account for instance rental
separately. LM Studio/runtime installation is not yet version-pinned; inspect
the recorded versions and pin the working stack before real trials.

## Completed pilot: 2026-09-28

Run `andy-4.2-pilot-20260928c`, source `e4092be`, completed the normal 600-second
pilot on one on-demand `g6.2xlarge`. Artifacts are under the standard S3
`runs/andy-4.2-pilot-20260928c/` prefix and locally in
`state/bench/andy-4.2-pilot-20260928c-remote/` (ignored, not committed).

- OpenCode 1.18.32; LM Studio CLI commit 69d945a; CUDA runtime 2.41.0.
- Q8_0 model and vision projector loaded, 32,768 context. Vision use itself
  remains unvalidated: Andy never called the screenshot MCP tool directly.
- 50 model steps; 48 execute calls: five completed immediately, 42 failed,
  and one returned running after the 40-second inline wait.
- The final background action found stone and successfully broke four blocks.
  Runtime receipts show breaks at +572.30s, +579.61s, +595.25s and +614.09s
  relative to runner t0. Three were inside the ten-minute budget; one was in
  shutdown grace.
- Zero advancements. No successful item collection was confirmed. Breaking
  stone without first obtaining a pickaxe does not imply obtaining cobblestone.
- Andy read SKILL.md once, but repeatedly invented movement primitives instead
  of reading primitives.md: 33 errors named `move_to`. It also confused separate
  MCP tools with Python functions and initially tried blocked imports.

This demonstrates actual game mutation via Andy + OpenCode + MCP, but weak
unaided adaptation to the primitive API. No prompt intervention was applied,
and no guided follow-up or real trials ran. Preserve these artifacts as a
compatibility pilot, not a one-hour score. Before four real trials, separately
test a concise API reminder and evaluate whether it prevents the error loop.
