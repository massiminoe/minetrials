// Add a private OpenAI-compatible endpoint without changing the MCP/task config.
import fs from 'node:fs';

const [configPath, artifactPath] = process.argv.slice(2);
const model = process.env.BENCH_MODEL;
if (!model?.startsWith('selfhosted/') || model.length <= 'selfhosted/'.length) {
  throw new Error('A custom endpoint requires --model selfhosted/<served-model-id>');
}
const baseURL = new URL(process.env.BENCH_OPENAI_BASE_URL);
if (!['http:', 'https:'].includes(baseURL.protocol) || baseURL.username || baseURL.password) {
  throw new Error('Use an HTTP(S) endpoint without credentials in the URL');
}
const modelId = model.slice('selfhosted/'.length);
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
config.provider = {
  selfhosted: {
    npm: '@ai-sdk/openai-compatible',
    name: 'Self-hosted Andy',
    options: {
      baseURL: baseURL.href,
      apiKey: '{env:BENCH_OPENAI_API_KEY}',
    },
    models: {
      [modelId]: {
        name: 'Andy 4.2 Q8',
        tool_call: true,
        attachment: true,
        temperature: true,
        limit: { context: 32768, output: 8192 },
        modalities: { input: ['text', 'image'], output: ['text'] },
      },
    },
  },
};
config.model = model;
config.small_model = model;
config.agent = { ...config.agent, build: { ...config.agent?.build, temperature: 0.6, top_p: 0.95 } };
config.enabled_providers = ['selfhosted'];
fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
// Deliberately exclude the endpoint and key from the public run artifacts.
fs.writeFileSync(artifactPath, JSON.stringify({
  provider: 'selfhosted', model: modelId, context: 32768, output: 8192,
  temperature: 0.6, top_p: 0.95, cost_basis: 'unavailable',
}, null, 2));
