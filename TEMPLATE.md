# AnythingLLM v1 Private AI Workspace (RAG + Agents): Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **AnythingLLM v1 Private AI Workspace (RAG + Agents)** (major version of the pinned 1.20.0) |
| Description | Chat with your documents, RAG and AI agents. Password on by default. (68 chars) |
| Category | AI/ML |
| Tags | anythingllm, rag, llm, ai-agents, chat-with-documents, lancedb, openai, anthropic, ollama, self-hosted |
| Icon | `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/anything-llm.svg` (200, image/svg+xml) |
| Repo | `baranberkay96/anythingllm-railway`, service root `/services/anythingllm` |

## Feasibility (checked 2026-11-20)

- Licence: MIT (`Mintplex-Labs/anything-llm`), commercial hosting allowed.
- No privileged mode, GPU, UDP or Docker socket. The optional built-in Lemonade LLM engine (Vulkan) is not used; LLMs come from API providers or the user's Ollama.
- Image `mintplexlabs/anythingllm:1.20.0`: amd64 1.19 GB compressed (under the 4 GB Trial/Free cap).

## Base market templates (checked 2026-11-20)

- `HNSCS1` "AnythingLLM" (983 active, 1,972 total): image `mintplexlabs/anythingllm:railway` (moving tag, amd64-only build of upstream's `render` branch), volume `/storage`, `STORAGE_DIR=/storage`, `RAILWAY_RUN_UID=0`, no password, no secrets.
- `anything-llm` (38 active): unpinned `mintplexlabs/anythingllm`, volume `/storage` + `STORAGE_DIR=/storage`, no password.
- `anythingllm-on-railway-or-1-click-llm-ap` (19 active): `:railway` tag, same layout.

### Improvements over market templates

1. **Password mode on by default.** `AUTH_TOKEN` (password) and `JWT_SECRET` are generated at deploy; the market templates leave the instance open until someone sets a password in the UI (whoever opens the URL first can).
2. **UI settings survive redeploys.** AnythingLLM writes the provider, model and keys chosen in the UI to `/app/server/.env`, outside the data directory. The wrapper symlinks it to `$STORAGE_DIR/.env` on the volume. Verified: provider/model set through the API were still there after a redeploy.
3. **Document uploads work with the standard image.** The server finds the collector's upload folder at `$STORAGE_DIR/../../collector/hotdir`. With `STORAGE_DIR=/storage` (market templates on the standard image) uploads fail with `ENOENT /collector/hotdir/...` (reproduced on the first test deploy). The volume is mounted at upstream's own path `/app/server/storage`.
4. **Stable encryption keys.** `SIG_KEY`/`SIG_SALT` generated at deploy; without them AnythingLLM generates keys into the non-persistent `.env`, and stored provider credentials become unreadable after a redeploy.
5. Pinned release (tag + index digest) instead of a moving tag; multi-arch upstream image instead of the amd64-only `railway` build.
6. Runs as the image's unprivileged user (uid 1000) instead of `RAILWAY_RUN_UID=0`; the wrapper hands the volume over (also volumes from root-run templates).
7. Fail-closed password handling (STANDARD 8.29), telemetry off by default, healthcheck with a 600 s window (Prisma generate + migrations at boot).

## Pinned versions

| Component | Reference | Released | Checked |
|---|---|---|---|
| AnythingLLM | `mintplexlabs/anythingllm:1.20.0@sha256:3e2b7bc8eb0f73a130fc575f1372bd4e7189e399a63c037497fc183c141fc0ae` | 2026-11-17 | 2026-11-20 |

## Architecture

```
Browser ──https──► AnythingLLM :3001 (server: UI, API, agents, LanceDB, native embedder)
                     └─ collector :8888 (same container, localhost): parses uploads, web pages
Volume /app/server/storage: anythingllm.db (SQLite), documents/, lancedb/, models/, .env (UI settings)
```

## Services and variables

| Service | Source | Health | Domain | Volume |
|---|---|---|---|---|
| AnythingLLM | repo `/services/anythingllm` (`FROM` the pinned image + `railway-start.sh`) | `/api/ping`, 600 s | public, 3001 | `/app/server/storage` |

Variables: `AUTH_TOKEN` (password, `secret(24)` alphanumeric), `JWT_SECRET`, `SIG_KEY`, `SIG_SALT` (`secret(48)` alphanumeric), `STORAGE_DIR=/app/server/storage`, `SERVER_PORT=PORT=3001`, `DISABLE_TELEMETRY=true`, optional `OPEN_AI_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY`. Empty variables are unset before start so they never hide values saved in the UI (dotenv does not override existing variables).

## Resource profile (measured on Railway, 2026-11-20)

| Service | Idle RAM | Peak seen | CPU idle |
|---|---|---|---|
| AnythingLLM | 0.43 GB | 0.64 GB (boot + first embedding) | ~0.08 vCPU |

Estimated cost: ~0.45 GB × $10 + ~0.1 vCPU × $20 + 1 GB volume × $0.15 ≈ **$6–7/month** idle. Minimum plan: Trial (1 GB per service) works for light use; Hobby recommended for larger document sets.

## Test results (Railway, pre-publish, 2026-11-20)

- Deploy: SUCCESS, `/api/ping` 200.
- Auth: `/api/workspaces` without token 401; wrong password 401; generated password 200 + token.
- Core action: created a workspace, uploaded a text file and embedded it (`upload-and-embed`, built-in embedder + LanceDB) in ~3 s; the document is listed in the workspace.
- Persistence: set LLM provider/model/key through `/api/system/update-env`, redeployed, values and the embedded document still present.
- STANDARD 8.29: `AUTH_TOKEN=abc` → deploy SUCCESS, log says LOCKED, login with `abc` 401, API 401.
- Chat with an LLM was not tested (no provider key in the test workspace).

## Verification checklist

- `https://{domain}/api/ping` returns `{"online":true}`.
- Sign in with `AUTH_TOKEN`; choose an LLM in Settings; chat in a new workspace.
- Upload a PDF to a workspace and ask about it.
- Redeploy: the LLM setting and documents remain.

## Open questions

- Upstream marks an instance with `AUTH_TOKEN` set as already onboarded, so the onboarding wizard is skipped; users choose the LLM in Settings (README says so).
- `/api/setup-complete` is unauthenticated upstream and reveals which provider is configured (not the keys).
