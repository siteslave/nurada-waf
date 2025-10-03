# Payload Samples

This folder contains sample `.txt` files you can import in the SQL Injection, Command Injection, XSS, and Path Traversal pages.

Files:

- `sqli-patterns.txt` — Regex-based patterns (one per line)
- `sqli-keywords.txt` — Simple substring keywords (one per line)
- `sqli-sample-both.txt` — Mixed lines to use with "Auto classify" import
- `cmdi-patterns.txt` — Command Injection regex patterns (one per line)
- `cmdi-keywords.txt` — Command Injection keywords (one per line)
- `xss-patterns.txt` — XSS regex patterns (one per line)
- `xss-keywords.txt` — XSS keywords (one per line)
- `pt-patterns.txt` — Path Traversal regex patterns (one per line)
- `pt-keywords.txt` — Path Traversal keywords (one per line)

Notes:

- One entry per line. Blank lines are ignored; duplicates are de-duplicated.
- No comment syntax: any non-empty line is treated as an item.
- File type must be plain text (`.txt`).

How to import:

1. Open the relevant page (SQL Injection, Command Injection, XSS, or Path Traversal).
2. Click "Import (.txt)".
3. Choose Target: `Patterns`, `Keywords`, or `Auto classify` (if available).
4. Pick a file from this folder and review the Preview.
5. Optional: toggle "Replace existing" to overwrite instead of merging.
6. Click Import, then Save the configuration.
