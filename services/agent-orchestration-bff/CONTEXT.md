# Service: agent-orchestration-bff

## Purpose

Backend-for-frontend service that acts as the bridge between the agent-architect-ui and the planning repo filesystem. It owns all file I/O, manifest parsing, agent CLI orchestration, and real-time change streaming. The UI never touches the filesystem directly — everything goes through this BFF.

## Responsibilities

- Read and write `manifest.yaml` — expose project state to the UI
- Serve specs, contracts, and phase completion data from the planning repo
- Trigger Claude Code CLI in headless mode (`claude -p`) to execute agent phases
- Stream CLI execution output to the UI in real time via SSE
- Watch the planning repo filesystem for changes (chokidar) and push updates via SSE
- Manage the approval workflow state (`approvals.json`) for the Human Review Gate

## Key Entities

| Entity | Description | Key Fields |
|--------|-------------|------------|
| Manifest | Parsed manifest.yaml exposed as structured API responses | services, tech_stack, quality_gates, approvals |
| PhaseExecution | A running or completed agent phase invocation | phase_number, target_service, status, started_at, output |
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
| phase.triggered | UI requests phase execution via API | phase_number, target_service, initiated_by |
| sse:file-change | chokidar detects planning repo change | path, event_type, timestamp |
| sse:phase-output | Claude CLI writes to stdout/stderr | phase_number, stream (stdout/stderr), chunk |
| sse:phase-complete | Claude CLI process exits | phase_number, exit_code, duration |

### Subscribes To

This service does not subscribe to events from other services. It generates events from internal sources (filesystem watcher, CLI process output) and publishes them to clients via SSE.

## External Dependencies

- **Planning repo filesystem** — reads/writes manifest.yaml, services/, contracts/, phases/, approvals.json
- **Claude Code CLI** — spawned as child process in headless mode (`claude -p`)

## Special Considerations

- The planning repo path must be configurable (environment variable) — not hardcoded
- No database — reads manifest.yaml as state, persists approvals to approvals.json
- See `standards/ui-architecture.md` for SSE streaming patterns, file watcher configuration, execution locking, and endpoint specifications
