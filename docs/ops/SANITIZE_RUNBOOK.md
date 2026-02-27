# Sanitization Runbook

## Goal

Prepare operational artifacts so they can be safely committed to a repository.

## Redaction Policy

- Replace all secrets with `<REDACTED>`.
- Secrets include API keys, tokens, passwords, private IP details that should remain private, and device identifiers when sensitive.
- If unsure, redact.

## Checklist

1. Copy raw artifacts into a temporary private working directory.
2. Redact secrets in each file.
3. Run string checks for obvious secret patterns.
4. Manually review each file before staging.
5. Move only sanitized files into `docs/ops/sanitized-archive/`.

## Example Local Checks

```bash
rg -n "AIza|AKIA|api[_-]?key|token|password|secret" docs/ops/sanitized-archive
```

If any sensitive value appears, stop and redact before commit.
