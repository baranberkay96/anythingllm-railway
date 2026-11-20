# Deploy and Host AnythingLLM with Railway

AnythingLLM is an all-in-one AI workspace from Mintplex Labs: chat with your documents (RAG), run AI agents with web browsing and tools, and switch between 30+ LLM providers or your own Ollama server. This community template runs the official AnythingLLM 1.20 image on Railway with a password, a persistent volume and settings that survive redeploys.

## About Hosting AnythingLLM

AnythingLLM is one Node.js application with two processes: the server (API, web UI, agents, built-in LanceDB vector database and a local embedding model) and a document collector that turns PDFs, Word files, web pages and more into text. Everything it stores lives in one data directory: a SQLite database, your documents, the vectors, downloaded models and the settings you pick in the UI.

On Railway, the template runs that image behind Railway's HTTPS domain with the data directory on a volume. Single-user password mode is on from the first boot, with the password generated at deploy. The settings file that upstream keeps outside the data directory is moved onto the volume, so the LLM provider and keys you choose in the UI are still there after a redeploy.

## Common Use Cases

- Private ChatGPT-style assistant over your own documents, wikis and websites (RAG)
- AI agents that browse the web, summarize pages, write files and call MCP tools
- One chat UI for OpenAI, Claude, Gemini, OpenRouter, Ollama and other providers
- Embeddable chat widget and developer API for your own sites and apps
- Team knowledge base with workspaces and per-user accounts (multi-user mode)

## Dependencies for AnythingLLM Hosting

- An LLM provider: an API key (OpenAI, Anthropic, Gemini, OpenRouter and many more) or your own Ollama/LM Studio server
- Nothing else: embeddings (built-in model) and the vector database (LanceDB) run inside the service

### Deployment Dependencies

- AnythingLLM source and docs: https://github.com/Mintplex-Labs/anything-llm and https://docs.anythingllm.com
- Docker image: https://hub.docker.com/r/mintplexlabs/anythingllm
- Configuration reference: https://docs.anythingllm.com/configuration
- Template source: https://github.com/baranberkay96/anythingllm-railway

### Implementation Details

| Service | What it runs | Public | Volume |
|---|---|---|---|
| AnythingLLM | `mintplexlabs/anythingllm:1.20.0` (pinned by digest) with a small start wrapper | yes, port 3001 | `/app/server/storage` |

**First login.** Open the service's public URL and sign in with the `AUTH_TOKEN` variable of the AnythingLLM service (generated at deploy, shown in the Variables tab). Then open **Settings > AI Providers > LLM**, pick your provider and paste its key, or set `OPEN_AI_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` or `OPENROUTER_API_KEY` on Railway before deploying. Keys set as Railway variables take precedence over keys typed in the UI.

**Several users.** Turn on **Settings > Security > Multi-user mode** and create the admin account. From then on people sign in with their own accounts and `AUTH_TOKEN` is no longer used.

**What the template adds.** The upstream image keeps UI settings in `/app/server/.env`, outside the data directory, so on most hosted setups the chosen LLM provider and keys disappear on the next redeploy. Here that file lives on the volume. The encryption key and salt (`SIG_KEY`, `SIG_SALT`) and the session secret are generated at deploy, so stored credentials stay readable. The data directory is the upstream path, so document uploads reach the collector. An empty or too short password does not open the instance: the start log says it is locked and how to fix it. Telemetry is off by default (`DISABLE_TELEMETRY`).

**Resources.** About 0.45 GB RAM idle (measured), up to about 0.65 GB while embedding documents with the built-in model. It fits the Trial plan's 1 GB; large document batches are more comfortable on Hobby.

**Scaling.** AnythingLLM uses SQLite and an embedded vector store on the volume, so run one replica. For more capacity raise the service's CPU and memory, or point it at an external vector database (Settings > Vector Database).

**Upgrading.** The version is pinned in `services/anythingllm/Dockerfile` of the template repo. To upgrade, change the image tag and digest to a newer release from Docker Hub and redeploy; database migrations run at start. Back up the volume first.

### Why Deploy AnythingLLM on Railway?

Railway runs AnythingLLM with HTTPS, a persistent volume and generated secrets in one click, so you get a private document chat and agent workspace without managing a server. You pay only for what the service uses, can add Ollama or other services to the same project later, and keep every document and setting on your own volume.
