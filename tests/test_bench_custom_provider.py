"""The private provider preserves MCP configuration and never exports a key."""
import json
import os
from pathlib import Path
import shutil
import subprocess

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.parametrize("seconds", ["3600", "0", "-1", "not-a-number"])
def test_andy_pilot_rejects_invalid_budgets_before_aws(seconds):
    result = subprocess.run([
        "bash", str(ROOT / "bench/aws/launch.sh"), "--andy-pilot",
        "--harness", "opencode", "--model", "selfhosted/andy-4.2",
        "--type", "g6.2xlarge", "--seconds", seconds,
    ], capture_output=True, text=True)
    assert result.returncode == 2
    assert "--andy-pilot requires" in result.stderr


@pytest.mark.skipif(not shutil.which("node"), reason="Node required for harness config")
def test_custom_provider_preserves_mcp_and_keeps_credentials_out_of_artifacts(tmp_path):
    config = tmp_path / "opencode.json"
    artifact = tmp_path / "provider.json"
    mcp = {"minetrials": {"type": "remote", "url": "http://minetrials:5556/mcp"}}
    config.write_text(json.dumps({"mcp": mcp, "permission": {"*": "allow"}}))
    env = {**os.environ, "BENCH_MODEL": "selfhosted/andy-4.2",
           "BENCH_OPENAI_BASE_URL": "http://host.docker.internal:1234/v1",
           "BENCH_OPENAI_API_KEY": "private-test-secret"}
    subprocess.run(["node", str(ROOT / "bench/harness/opencode/custom-provider.mjs"),
                    str(config), str(artifact)], env=env, check=True)
    result = json.loads(config.read_text())
    assert result["mcp"] == mcp
    assert result["model"] == result["small_model"] == "selfhosted/andy-4.2"
    assert result["enabled_providers"] == ["selfhosted"]
    assert result["provider"]["selfhosted"]["options"]["baseURL"] == env["BENCH_OPENAI_BASE_URL"]
    assert "private-test-secret" not in config.read_text() + artifact.read_text()
    assert "host.docker.internal" not in artifact.read_text()
