# AnythingLLM for Railway: the official multi-arch image, pinned by tag and
# digest, plus a start wrapper (volume ownership, persisted settings file,
# fail-closed password checks). No upstream code is rebuilt here.
FROM mintplexlabs/anythingllm:1.20.0@sha256:3e2b7bc8eb0f73a130fc575f1372bd4e7189e399a63c037497fc183c141fc0ae

# The wrapper starts as root to prepare the Railway volume, then drops to the
# image's own unprivileged user (anythingllm, uid 1000) before AnythingLLM runs.
USER root
COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start.sh
RUN bash -n /usr/local/bin/railway-start.sh && command -v setpriv

ENV STORAGE_DIR=/app/server/storage \
    SERVER_PORT=3001 \
    PORT=3001
EXPOSE 3001
ENTRYPOINT ["/bin/bash", "/usr/local/bin/railway-start.sh"]
CMD []
