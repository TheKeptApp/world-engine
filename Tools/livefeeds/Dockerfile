# Live-feed relay (Tools/livefeeds), one feed per container: LIVEFEEDS_FEED=rtd | cta | ctabus.
# Python standard library only. No keys are baked in: CTA_TRAIN_API_KEY / CTA_BUS_API_KEY come from the runtime
# environment (a secret manager), never from this file or the build context. See docs/live-world/deploy.md.
#   docker build -t livefeeds Tools/livefeeds
#   docker run --rm -p 8080:8080 -e LIVEFEEDS_FEED=rtd livefeeds
FROM python:3.12-slim

# tzdata: service days and CTA local times use zoneinfo (America/Chicago, America/Denver).
RUN apt-get update && apt-get install -y --no-install-recommends tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --home-dir /app relay

WORKDIR /app
COPY --chown=relay:relay livefeeds ./livefeeds
COPY --chown=relay:relay areas.json ./areas.json
COPY --chown=relay:relay data ./data

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080 \
    LIVEFEEDS_HOST=0.0.0.0 \
    LIVEFEEDS_FEED=rtd \
    LIVEFEEDS_CACHE=/tmp/livefeeds-cache

USER relay
EXPOSE 8080

# Liveness only (no upstream call). Cloud Run ignores HEALTHCHECK; configure its probes on /healthz instead.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python3 -c "import os,urllib.request; urllib.request.urlopen('http://127.0.0.1:%s/healthz' % os.environ.get('PORT','8080'), timeout=2)"

CMD ["python3", "-m", "livefeeds", "serve"]
