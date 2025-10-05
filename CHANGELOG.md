# Changelog

## [0.1.1] - 2025-10-05

### WAF-CORE

#### Added

- Streaming SQLi backpressure & concurrency limiting (`sqli_protection.streaming_max_concurrent`) with metrics:
  - `waf_sqli_streaming_active`
  - `waf_sqli_streaming_backpressure_total`
  - `waf_sqli_streaming_early_block_total`
- GeoIP soft mode (`geoip_filter.soft_mode`) allowing dry-run (log/metrics only) decisions before enforcing blocks (`waf_geoip_soft_block_total`).
- Aggregated alert enrichment (top user-agents & latency p95) configurable via:
  - `alerting.aggregate.include_user_agents`
  - `alerting.aggregate.max_user_agents`
  - `alerting.aggregate.include_latency`
  - `alerting.aggregate.latency_sample_rate`
- Metrics for GeoIP hard vs soft decisions: `waf_geoip_block_total`, `waf_geoip_soft_block_total`.

#### Changed

- Alert aggregation summary payload now includes optional `top_user_agents` and `latency_stats` keys when enabled.
- README expanded with streaming backpressure docs and enrichment details (in progress if this note persists).

#### Fixed

- IP Filter: CIDR-aware.
- Logging: Redaction (header & body-sensitive pattern masking).
- TLS Visibility & Upstream Verification Posture logging (certificate days-left severity + relaxed verify notices).
- Upstream SSRF Guard: private range denial, allow/deny CIDR lists, optional DNS resolution.
- Path Canonicalization: collapse //, resolve . & .., safe percent-decode of unreserved chars.
- Safer concurrency handling for streaming SQLi semaphore (avoid unsafe mutation).
- Config Reload Safety: SHA-256 content hash skip + reload rate limiting (5/30s + cooldown).
- Tests for new default config values (`tests/config_defaults.rs`) ensuring stability across future refactors.
- Prometheus Metrics export (`/metrics`) for requests, body inspection latency, alert queue depth & drops.

#### Internal / Tooling

- Clarified comments and simplified hashing (removed external xxhash dependency in favor of `DefaultHasher`).

### WAF-API

#### Added

- `upstream_security` configuration section with new endpoints:
  - `GET /api/config/upstream_security`
  - `POST /api/config/upstream_security`
- `geoip_filter.soft_mode`: log-only mode for GeoIP decisions (no blocking when true; future runtime logic will honor this).
- Alerting aggregate tuning fields: `queue_capacity`, `drop_log_every`, `include_user_agents`, `max_user_agents`, `include_latency`, `latency_sample_rate` (schema + docs; logic pending).
- Logging redaction configuration: `redact_headers`, `sensitive_replacement`, `max_body_log_bytes`, `redact_body_patterns`.
- Route protection pattern model (public vs protected lists with wildcard `*`).
- Unit tests for auth route pattern precedence and wildcard handling.
- Troubleshooting guide for upstream security 404 scenarios in README.
- `sqli_protection.streaming_max_concurrent`: optional limit for concurrent streaming classification requests (separate from `max_concurrent_api_requests`). `null` or `0` (when implemented) means unlimited.

#### Changed

- Middleware refactored to generic pattern-based JWT enforcement (removed hard‑coded `/api/` auth assumption).
- README expanded with detailed sections for redaction, route protection model, alerting enhancements, and upstream security.
- Added automatic inclusion of `/api/*` in protected routes if not present in config.

#### Fixed

- 404 issue with new upstream security endpoints resolved by registering services in `routes::config_services`.
- Removed outdated `AppStateDummy` import; unified `AppState` across binary and tests.

#### Security

- Strengthened configuration surface for future runtime hardening (redaction + upstream security scaffolding).

#### Notes

- Alerting enrichment (user-agent summaries & latency sampling) and queue bounding are not yet implemented; current release only stores config.
- Runtime upstream destination enforcement (CIDR/private blocking) to be implemented in a subsequent release.

### WAF-UI

#### Added

- Tooltip helper icons across configuration pages (Settings, Alert, XSS, Path Traversal, Command Injection, Rate Limit, Reverse Proxy Upstream Dialog) replacing verbose inline helper text.
- Unified 4-column layout for core Action / Response / Size fields on XSS, Path Traversal, Command Injection pages.
- Import dialog enhancements (Command Injection) with auto classification of patterns vs keywords.
- Upstream dialog tooltips for name, address list, timeouts, enable / verify toggles.

#### Changed

- Consolidated UI consistency: replaced paragraph helper descriptions with `Info` icon tooltips.
- Improved readability and spacing in security configuration dialogs.

#### Fixed

- Ensured no TypeScript errors following UI refactors.
