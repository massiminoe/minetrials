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
AWS support case: `179049897900084`. At preparation time the request was
`CASE_OPENED`; no GPU instance had been launched and gameplay was unverified.

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
