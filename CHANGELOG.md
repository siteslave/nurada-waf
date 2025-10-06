# Changelog

## [0.1.2] - 2025-10-07

### WAF-CORE

#### Added

- Configurable log timezone via `logging.timezone` (IANA TZ string, default `Asia/Bangkok`) applied to all structured log timestamps.
- Remote File Inclusion (RFI) protection module (`rfi_protection.*`) with:
  - Heuristic detection (blocked schemes, sensitive params + suspicious extensions, mixed traversal + remote reference)
  - Configurable `response_code`, `block_message`, `detection_only` mode
  - Size guards (`max_url_length`, `max_value_len`, `max_body_size`) and domain allowlist (`whitelist_domains`)
  - Optional POST body (form-urlencoded) inspection (`check_post_body`)
- Local File Inclusion (LFI) protection module (`lfi_protection.*`) with:
  - Traversal token & sensitive file heuristics limited to sensitive parameters
  - Configurable `response_code`, `block_message`, `detection_only` mode
  - Size guards (`max_url_length`, `max_value_len`, `max_body_size`) and POST body inspection (`check_post_body`)
- Per-route plugin toggles extended with `rfi` and `lfi` enabling selective activation per route.
- File Upload protection module (`file_upload_protection.*`) providing multipart/form-data inspection (extension & double-extension heuristics, magic signature detection (now extended with pdf/png/zip signatures opt-in), size & file count limits, MIME mismatch, allowlist/denylist, detection-only mode).

#### Changed

- Internal: Renamed `BangkokEncoder` to `TimezoneEncoder` to reflect configurable timezone support.

### WAF-API

#### Added

- Configuration sections & endpoints:
  - `rfi_protection`: `GET /api/config/rfi_protection`, `POST /api/config/rfi_protection`.
  - `lfi_protection`: `GET /api/config/lfi_protection`, `POST /api/config/lfi_protection`.
  - `file_upload_protection`: `GET /api/config/file_upload_protection`, `POST /api/config/file_upload_protection`.
- Per-route plugin toggles extended with: `rfi`, `lfi`, `file_upload`.
- Upstream safety guards:
  - Prevent deleting an upstream that is referenced by any route (returns HTTP 409 with referencing route list).
  - Prevent renaming an upstream (via `new_name`) when it is still referenced, or if target name already exists.
- README documentation for new protections and per-route plugin usage.

#### Changed

- Simplified `RfiProtection` schema (removed unused legacy fields) to align closely with current YAML usage set; unknown YAML fields are dropped on save.

#### Fixed

- Ensured new config endpoints are registered so they no longer return 404 after build.

#### Notes

- Runtime enforcement for `rfi_protection`, `lfi_protection`, and `file_upload_protection` is configuration-only at this version; blocking / inspection logic to be implemented in a future release.
- Additional validation (e.g., file size relationships, required lists) not yet enforced.

#### Migration

- After updating, existing configs without the new sections will have them defaulted on first write; review and adjust as needed.

### WAF-UI

#### Added (0.1.2)

- Remote File Inclusion (RFI) protection page (blocked schemes, sensitive params, suspicious extensions, whitelist domains, POST body scanning, detection-only mode).
- Local File Inclusion (LFI) protection page (sensitive params, traversal tokens, sensitive files) with import + auto classification.
- File Upload Protection page (allowed extensions, blocked extensions, blocked magic/MIME types, suspicious inner extensions for double‑extension detection, size & inspection controls).
- Per‑route plugin flags extended to include: `rfi`, `lfi`, `file_upload` (in addition to existing xss, sqli, path_traversal, cmdi, user_agent_filter, geoip).
- New payload lists in `payloads/`: RFI (`rfi-blocked-schemes.txt`, `rfi-sensitive-params.txt`, `rfi-suspicious-extensions.txt`), LFI (`lfi-sensitive-params.txt`), File Upload (`file-upload-allowed-extensions.txt`, `file-upload-blocked-extensions.txt`, `file-upload-blocked-magic-types.txt`, `file-upload-suspicious-inner-extensions.txt`).
- Comment (`#`) line support for RFI, LFI, File Upload, and Path Traversal imports.
- Expanded root `README.md` and `payloads/README.md` with documentation for new modules and payload usage.

#### Changed (0.1.2)

- Standardized normalization for RFI blocked schemes (ensure `://` or `data:` form).
- Payload import UX generalized across new modules (consistent preview, replace/merge toggle).

#### Fixed (0.1.2)

- Markdown formatting adjustments (README / payload docs) to satisfy lint rules (blank lines around headings/lists).

#### Notes (0.1.2)

- YAML export of routes now includes new plugin flags only when enabled.
- Encourage allowlist-first strategy for file upload security; blocklist is supplemental.

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
