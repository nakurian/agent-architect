# Rebuild a Single Service

Re-run the build phase for a single service after spec changes or to fix review issues.

## Usage
```
/project:rebuild-service <service-name>
```

The service name is passed as `$ARGUMENTS`. If empty, ask the human which service to rebuild.

## Instructions

1. Read `manifest.yaml` to verify the service exists; check `manifest.local.yaml` then `manifest.yaml` for `local_path`
2. If `local_path` is empty, ask the human for the path to the existing code
3. Navigate to the service code directory at `local_path`
4. Read `services/<service-name>/specs/SPEC.md` — the updated spec
5. Read `services/<service-name>/specs/BUILD-REPORT.md` — what was previously built
6. Read `phases/7-review.md` (if exists) — any issues to fix for this service
7. Read relevant contracts from `contracts/`
8. Read `standards/` — coding standards

Determine what changed:
- If spec has new endpoints → implement them
- If spec has modified logic → update the code
- If review flagged issues → fix them
- If contracts changed → update integration code

Follow the same build process as Phase 5, but only for the changed parts.

Update the BUILD-REPORT.md when done.

## Important
- Do NOT rebuild from scratch unless the spec fundamentally changed
- Focus on incremental changes
- Run all existing tests after changes to ensure nothing broke
