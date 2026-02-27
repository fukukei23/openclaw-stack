# Pairing Recovery Runbook

## Purpose

Recover device pairing when a client is no longer authorized or pairing data is lost.

## Preconditions

- Gateway service is running and healthy.
- Operator has access to the deployment host and logs.
- Existing credentials are handled as secrets and never pasted into docs.

## Steps

1. Confirm current gateway health and authentication behavior.
2. Back up current pairing-related files to a secure private location.
3. Regenerate or re-establish pairing using the approved operational procedure.
4. Validate that the client can authenticate and run a minimal request.
5. Record actions taken in an internal change log.

## Post-Recovery Checks

- Old invalid tokens or stale device registrations are revoked.
- Sanitized evidence is stored under `sanitized-archive/` with secrets masked.
- No raw secrets were written to version-controlled files.
