# Changelog

## [0.1.4] - 2025-10-08

### WAF-CORE

#### Added

- File Upload blocked log payload now includes `filename=<name>` prefix (before sanitized preview) for easier incident triage and correlation.
- Per-request correlation ID for all blocked enforcement events: new `request_id=` field in `BLOCKED|...` log lines and `X-WAF-Request-ID` header plus embedded JSON/HTML body token in block responses for user-facing correlation.
- Branded block response footer: "Powered by NuradaWAF" now rendered bottom-right in HTML block pages (opposite support contact) and a `"powered_by": "NuradaWAF"` field added to JSON block responses for user-facing transparency and downstream UI display.

#### Changed

- `FileUploadDecision` enum variants `Block` and `Log` now carry an `Option<String>` with the originating filename. Existing code matching on `Block(reason)` must be updated to `Block(reason, _)`.
- Multipart file upload logging merges reason + filename into the blocked `BLOCKED|type=UPLOAD` payload string. Format example:
  `BLOCKED|type=UPLOAD|...|payload=filename=shell.php blocked_extension;field1=value1&...` (preview still redacted/truncated as before).
- Global blocked log line format enhanced: now consistently appends `location=<context>` (e.g. `location=body`, `location=header:User-Agent`, `location=rate_limit:ip`) and ensures only a single centralized `BLOCKED|...` line is emitted per enforcement (duplicate per-plugin block lines removed). This is backward-incompatible for strict log parsers expecting a fixed field count—update parsing rules to allow the new `location=` segment (appears before `payload=`) and optional filename prefix inside `payload` for uploads.
- Blocked log line format now also includes `request_id=<uuid32>` immediately after the `location=` field. Update any log parsers/ETL pipelines to accept the new token order: `...|method=GET|location=body|request_id=<uuid32>|payload=...` where `<uuid32>` is a dashless (32 lowercase hex) UUID v4.
- Request ID format changed from a custom time/counter hex to a dashless UUID v4 (32 lowercase hex chars) to improve entropy and cross-system uniqueness.
- Response correlation header renamed from `X-Request-ID` to `X-WAF-Request-ID` to reduce collision risk with upstream or existing infrastructure headers.

#### Fixed

- `file_upload_protection.inspect_magic` serde default now correctly resolves to `true` (previously only true via `Default` impl, causing deserialized configs without the field to disable magic inspection inadvertently).

### WAF-API

- Dashboard stats parsing updated to count block events strictly via new unified patterns:
  - `BLOCKED|type=SQLI`
  - `BLOCKED|type=XSS`
  - `BLOCKED|type=UPLOAD`
  - `BLOCKED|type=RFI`
  - `BLOCKED|type=LFI`
  - `BLOCKED|type=PATH_TRAVERSAL`
  - `BLOCKED|type=GEOIP`
  - `BLOCKED|type=IP_FILTER`
  - `BLOCKED|type=GLOBAL_RATE_LIMIT`
  - `BLOCKED|type=ROUTE_RATE_LIMIT`
  - `BLOCKED|type=USER_AGENT`
- Removed all legacy fallback parsing branches from dashboard stats, attack logs, and attack series endpoints (now unified-format only).
- Exposed new counters in stats response: `upload`, `rfi`, `lfi` (omitted from JSON when zero).
- Updated README with unified block log format documentation, token table, and removal of legacy parsing guidance.

#### Notes

- Previous mixed token forms (e.g., `SQLI_DETECTED|`, `XSS_DETECTED|`, `UA_BLOCK|`, `IP_BLACKLISTED|`) are no longer tallied for new statistics calculations; ensure log emitter conforms to new format for accurate counts.
- Unified token tests added for CMDI, PATH_TRAVERSAL, USER_AGENT, and IP_FILTER to validate parsing logic.

### WAF-UI 

- Update Sidebar menu
- Add icon on page title

## [0.1.3] - 2025-10-07

### WAF-CORE

#### Changed

- Per-route plugin toggles: `rfi`, `lfi`, and `file_upload` now default to disabled when omitted (previously treated as enabled when the global module was on). To enable for a route, explicitly set the flag to `true` under `route.plugins`. Other plugins retain prior behavior (omitted = enabled). This is a behavioral tightening to avoid unintended inspection overhead.

#### Migration Notes

- If you relied on implicit activation of RFI/LFI/File Upload protection on routes without explicit `plugins:` entries, add:

```yaml
plugins:
  rfi: true
  lfi: true
  file_upload: true
```

to those route definitions.

### WAF-API

#### Added

- Config normalization (`ensure_defaults`) now auto-populates safe default values for newly introduced or unset fields across multiple protection sections (RFI, LFI, File Upload, Path Traversal, XSS, CMDi, User-Agent filter, GeoIP filter, IP filter). Each applied change is logged with a human-readable message at startup.
- Additional test coverage for default application and idempotency:
  - RFI / LFI / File Upload defaults (response codes, size limits, overlap cleanup, message population)
  - Path Traversal, XSS, and CMDi default response code + size/url limits
  - User-Agent filter, GeoIP filter, IP filter default block codes (403)
  - File upload relational validation (max_file_size clamped to max_multipart_size)
  - Extension overlap removal logic (allowed vs blocked) implicitly validated
  - Idempotency test ensures subsequent normalization passes make no changes

### WAF-UI

#### Added

- Backup page: skeleton loading rows for Files and History tables.
- Backup page: illustrated empty states (icon + explanatory text + primary / secondary actions).
- Backup & History: click active tab (Files / History) now forces a refresh (debounced by loading state).
- Global toast system (top-right) standardized across configuration pages for create/save/delete/download/restore actions (success, destructive, warning, info variants).

#### Changed

- Backup page: reverted CRUD/action feedback from inline-only to unified global toast usage for consistency with other pages; inline tray retained only for potential future retry contexts.
- Backup & History initial load failures now render embedded error panels (icon + message + Retry) instead of inline error toasts.
- Removed circular badge backgrounds around illustrative icons in Backup empty/error states (cleaner minimal style).
- Files & History pagination footers are hidden during loading or error states to prevent stale/phantom page counts.

#### Fixed

- Backup Files pagination showing multiple pages after API failure (list resets & footer hidden).
- History pagination persisting stale pages after fetch error (history cleared & page reset on error, footer hidden).
- Reverse Proxy: Upstream Security dialog opening with tooltip ("Deny private networks") shown immediately; prevented auto-focus on tooltip trigger.

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
