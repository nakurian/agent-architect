# Service: agent-orchestration-bff

## Purpose

Backend-for-frontend service that acts as the bridge between the agent-architect-ui and the planning repo filesystem. It owns all file I/O, manifest parsing, approval management, and real-time change streaming. The UI never touches the filesystem directly — everything goes through this BFF.

## Responsibilities

- Read and write `manifest.yaml` — expose project state to the UI
- Serve specs, contracts, and phase completion data from the planning repo
- Watch the planning repo filesystem for changes (chokidar) and push updates via SSE
- Manage the approval workflow state (`approvals.json`) for the Human Review Gate

## Key Entities

| Entity | Description | Key Fields |
|--------|-------------|------------|
| Manifest | Parsed manifest.yaml exposed as structured API responses | services, tech_stack, quality_gates, approvals |
| PhaseStatus | Completion state of a phase read from phases/ directory | phase_number, name, status, completion_date |
| FileChange | A detected change in the planning repo | path, event_type (create/modify/delete), timestamp |
| Approval | Review gate sign-off record persisted in approvals.json | phase, approved_by, date, notes |

## API Consumers

| Consumer | Endpoints Used | Notes |
|----------|---------------|-------|
| agent-architect-ui | All endpoints | Sole consumer — this BFF exists to serve the UI |

## Events

### Publishes

| Event | Trigger | Payload Description |
|-------|---------|---------------------|
| approval.granted | Reviewer submits approval via API | phase, approver, timestamp, notes |
| sse:file-change | chokidar detects planning repo change | path, event_type, timestamp |

### Subscribes To

This service does not subscribe to events from other services. It generates events from internal sources (filesystem watcher) and publishes them to clients via SSE.

## External Dependencies

- **Planning repo filesystem** — reads/writes manifest.yaml, services/, contracts/, phases/, approvals.json

## Special Considerations

- The planning repo path must be configurable (environment variable) — not hardcoded
- No database — reads manifest.yaml as state, persists approvals to approvals.json
- See `standards/ui-architecture.md` for SSE streaming patterns, file watcher configuration, and endpoint specifications
