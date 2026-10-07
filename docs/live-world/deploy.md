# Deploying the live-feed relay (not deployed)

Status 2026-10-07: deploy-ready, **not deployed**. R chooses the host later. Nothing here has been run on a cloud
account.

Verified 2026-10-07 in the cloud session: image built and run with Docker, `/healthz` 200, Docker health `healthy`,
process runs as uid 10001, image holds only `livefeeds/`, `areas.json`, `data/`; env-var config and the unknown-feed
error tested. One gap: the sandbox's build network cannot reach Debian's package mirror, so the `tzdata` install step was
replaced by mounting the host's zoneinfo for that test; on a normal build host (Cloud Build, a laptop) it runs as written.

## The container

`Tools/livefeeds/Dockerfile` (build context `Tools/livefeeds`): `python:3.12-slim` plus `tzdata`, standard library only,
runs as an unprivileged user, serves on `$PORT` (default 8080). One container serves **one feed**; run one service
per feed (`rtd`, `cta`, `ctabus`). The image holds code, `areas.json` and `data/` only (`.dockerignore`); never keys,
caches or tests.

```
docker build -t livefeeds Tools/livefeeds
docker run --rm -p 8080:8080 -e LIVEFEEDS_FEED=ctabus -e CTA_BUS_API_KEY livefeeds   # key passed through, not typed
```

## Configuration (environment variables; a command-line flag wins)

| Variable | Default | Meaning |
|---|---|---|
| `LIVEFEEDS_FEED` | `rtd` | `rtd`, `cta` (trains) or `ctabus` |
| `PORT` | 8080 in the image | listening port (Cloud Run sets it) |
| `LIVEFEEDS_HOST` | `0.0.0.0` in the image | listening address |
| `LIVEFEEDS_INTERVAL` | 30 | upstream poll seconds (never below 30) |
| `LIVEFEEDS_IDLE_SECONDS` | 120 | pause polling after this long without a phone request; 0 = always poll |
| `LIVEFEEDS_CLIENT_POLL` | 15 | poll hint sent to phones |
| `LIVEFEEDS_CACHE` | `/tmp/livefeeds-cache` | snapshot, daily salt, routes, shapes, stops |
| `CTA_TRAIN_API_KEY` / `CTA_BUS_API_KEY` | none | **secrets**, read per request, never logged or served |

The cache is a convenience: on a fresh instance the relay re-downloads routes and shapes (RTD about 10 MB, CTA
69 MB, weekly) and starts a new daily salt, so an ephemeral disk is fine. CTA's 69 MB static zip is streamed to a temp
file; give the instance at least 512 MB memory.

## Health

- `GET /healthz`: liveness, 200 while the process serves; never calls upstream or wakes the poller.
- `GET /v1/status`: readiness detail (fresh / stale / unavailable, ages, error counters), for monitoring, not as a
  liveness probe (an upstream outage must not restart the relay; it serves the last snapshot as stale).
- The Dockerfile's `HEALTHCHECK` covers plain Docker hosts.

## Cloud Run (sketch)

```
gcloud run deploy livefeeds-ctabus --source Tools/livefeeds --region us-central1 \
  --set-env-vars LIVEFEEDS_FEED=ctabus --set-secrets CTA_BUS_API_KEY=cta-bus-key:latest \
  --min-instances 0 --max-instances 1 --memory 512Mi --cpu 1 --no-cpu-throttling
# probes: liveness and startup HTTP GET /healthz
```

- `--max-instances 1`: one poller per feed, so upstream quotas hold (CTA's 100,000 calls a day) and every phone gets
  the same snapshot. The relay already stops polling after 120 s without requests; with `--min-instances 0` Cloud
  Run also scales to zero, and the first request after that waits for a cold start plus one upstream poll (the relay
  waits up to 3 s for data, then answers `unavailable` and the phone retries).
- `--no-cpu-throttling` keeps the background poller running between requests while the instance is up.
- Keys go in Secret Manager (`--set-secrets`), never `--set-env-vars`.
- Costs scale with instance-hours; with scale-to-zero an idle relay costs nothing.

## Firebase

Firebase Hosting can front the same Cloud Run service with a rewrite (`"rewrites": [{"source": "/v1/**",
"run": {"serviceId": "livefeeds-ctabus", "region": "us-central1"}}]`), which adds the CDN in front of the
`Cache-Control` the relay already sends (`/v1/shapes` and `/v1/stops` cache for a day, vehicles for a few seconds).
Cloud Functions are a poor fit: the relay is a long-lived poller with in-memory state, not a per-request function.

## Before going live

- CTA purpose clause answered in writing (live-feeds.md blocker 2).
- A real contact address in the relay's User-Agent (`fetch.USER_AGENT`), as upstream operators ask.
- Attribution stays in every response (already enforced in code).
