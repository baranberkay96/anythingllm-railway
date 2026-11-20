# NOTICE: AnythingLLM v1 Private AI Workspace (RAG + Agents) template

## Software deployed

- **AnythingLLM** by Mintplex Labs Inc., MIT License, https://github.com/Mintplex-Labs/anything-llm. Deployed unmodified from the official image `mintplexlabs/anythingllm:1.20.0` (pinned by digest). Copyright (c) Mintplex Labs Inc.

## Written for this template

- `services/anythingllm/Dockerfile` and `services/anythingllm/railway-start.sh`: start wrapper (volume ownership, settings file on the volume, password checks, privilege drop). It calls the image's own `docker-entrypoint.sh`.
- `README.md`, `TEMPLATE.md`, `template.json`: written for this template.

## Upstream files checked (read only, 2026-11-20)

- `docker/Dockerfile`, `docker/docker-entrypoint.sh`, `docker/docker-healthcheck.sh`, `docker/.env.example` at tag `v1.20.0`.
- `server/utils/helpers/updateENV.js` (settings dump to `server/.env`), `server/utils/files/multer.js` (collector hotdir path), `server/utils/middleware/validatedRequest.js` (password mode), `server/index.js` at `v1.20.0`.
- Branches `render` (source of the `:railway` image tag) and `pg` compared with `master`.

## Market templates reviewed

`HNSCS1`, `anything-llm`, `anythingllm-on-railway-or-1-click-llm-ap` (configuration only; nothing copied).

## Names and affiliation

AnythingLLM is a trademark of Mintplex Labs Inc. This is a community template, not affiliated with or endorsed by Mintplex Labs. The icon comes from the homarr-labs dashboard-icons collection.
