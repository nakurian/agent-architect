# Add a New Service

Utility command to scaffold a new service folder from the template.

## Usage
```
/project:add-service order-service domain
```

Parse `$ARGUMENTS` to extract the service name (first word) and type (second word).
If `$ARGUMENTS` is empty, ask the human for the service name and type.

Where type is: ui | bff | domain | shared-lib | infrastructure

## Instructions

1. Read `manifest.yaml` to check the service doesn't already exist
2. Create `services/<service-name>/` with the following structure:
   - `CONTEXT.md` — copy content from `services/.template/CONTEXT.md`, replacing `[SERVICE_NAME]` with the actual name
   - `references/` — empty directory
   - `specs/` — empty directory
3. Update the CONTEXT.md with the service name and type
4. Add the service entry to `manifest.yaml` under `services:` with all fields:
   - Set status to `new`
   - Set the type from the argument
   - Set `repo: ""` and `local_path: ""` (builder will ask at build time)
   - Set `database: null` for ui/bff types, or the tech_stack default for domain types
   - Set `owns_events: []`
   - Ask the human for: description, port, depends_on
5. Confirm the service was added and remind the human to:
   - Fill in `services/<service-name>/CONTEXT.md`
   - Add any references to `services/<service-name>/references/`
   - Re-run spec phase if specs have already been generated

## Important
- Use the next available port number (check existing services) — shared-libs don't need ports, set to `null`
- For `shared-lib` type: set `database: null`, `owns_events: []`, `port: null`, `depends_on: []`
- Do NOT generate a spec — that's the spec agent's job
