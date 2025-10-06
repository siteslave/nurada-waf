# Payload & List Samples

This folder contains sample `.txt` payload / indicator lists you can import into the various protection pages (SQL Injection, Command Injection, XSS, Path Traversal, RFI, LFI, and File Upload Protection).

## Index

### SQL Injection (SQLi)

- `sqli-patterns.txt` — Regex-based patterns (one per line)
- `sqli-keywords.txt` — Simple substring keywords (one per line)
- `sqli-sample-both.txt` — Mixed lines to use with "Auto classify" import

### Command Injection (CMDi)

- `cmdi-patterns.txt` — Command Injection regex patterns
- `cmdi-keywords.txt` — Command Injection keywords

### Cross-Site Scripting (XSS)

- `xss-patterns.txt` — XSS regex patterns
- `xss-keywords.txt` — XSS keywords

### Path Traversal (PT)

- `pt-patterns.txt` — Path Traversal regex patterns
- `pt-keywords.txt` — Path Traversal keywords

### Remote File Inclusion (RFI)

- `rfi-blocked-schemes.txt` — Blocked/monitored URI schemes or wrappers (with `://` or `data:`)
- `rfi-sensitive-params.txt` — Parameter names frequently used to reference remote resources
- `rfi-suspicious-extensions.txt` — Potentially dangerous file extensions

### Local File Inclusion (LFI)

- `lfi-sensitive-params.txt` — Parameter names often tied to local/remote file inclusion attempts

### File Upload Protection

- `file-upload-allowed-extensions.txt` — Whitelisted extensions (keep this minimal)
- `file-upload-blocked-extensions.txt` — High‑risk / executable / scripting extensions to deny
- `file-upload-blocked-magic-types.txt` — MIME / magic types to block after content sniffing
- `file-upload-suspicious-inner-extensions.txt` — Inner extensions for double‑extension detection (e.g. `image.jpg.php`)

## Notes

- One entry per line. Blank lines are ignored; duplicates are de‑duplicated.
- Lines beginning with `#` are treated as comments and ignored in modules that support comments (RFI, LFI, File Upload, Path Traversal). SQLi / CMDi / XSS lists currently treat any non-empty line as data (avoid `#` there unless you intend it as a literal pattern/keyword).
- Extensions are stored with a leading dot (e.g. `.php`, `.jpg`).
- Schemes in RFI lists are normalized (e.g. `http://`, `php://filter`, `data:`).
- All files must be plain text (`.txt`).

## Import Workflow (General)

1. Open the relevant protection page.
2. Click `Import (.txt)`.
3. Select the appropriate Target (e.g. Patterns, Keywords, Blocked Schemes, Sensitive Params, Allowed Extensions, etc.) or choose an Auto classify option where available.
4. Pick a file from this folder and review the Preview list.
5. (Optional) Toggle **Replace existing** to overwrite instead of merging.
6. Click **Import**, then **Save** the configuration.

## Feature-Specific Tips

### RFI

- Use a tight `whitelist_domains` list plus broad `blocked_schemes` for defense-in-depth.
- Add only the sensitive params you actually see in your application to reduce noise.

### LFI

- Start with a minimal sensitive param list, expand based on real traffic analysis.

### File Upload

- Prefer an allowlist strategy: keep `allowed extensions` small rather than growing a giant blocklist.
- Combine extension checks with magic/MIME validation (`blocked-magic-types`).
- Use `suspicious inner extensions` to flag double extensions early.

### SQLi / CMDi / XSS / PT

- Regex patterns should be anchored or scoped to reduce false positives.
- Keep keyword lists concise; overly broad entries (e.g. `or`) can cause excessive noise.

## Updating / Customizing

You can duplicate any file and tailor it, or maintain separate environment-specific variants (e.g. `file-upload-allowed-extensions.prod.txt`). The import dialog lets you merge rather than replace so you can layer organization-wide + app-specific lists.

---

If you add new payload files, remember to document them here for future operators.
