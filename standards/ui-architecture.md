# UI Architecture Standards

These standards apply to any UI built on top of the Agent Architect planning framework.

## Layered Architecture

All UIs must follow this layered architecture:

```
┌─────────────────────────────────────────────────────┐
│              agent-architect-ui (Frontend)            │
├─────────────┬───────────────┬───────────────────────┤
│  Dashboard  │  Spec Viewer  │  Review & Approval    │
│  & Phases   │  & Editor     │  Workflow              │
└──────┬──────┴───────┬───────┴───────────┬───────────┘
       │              │                   │
       ▼              ▼                   ▼
┌─────────────────────────────────────────────────────┐
│         agent-orchestration-bff (Service)             │
├─────────────────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐    │
│  │ Manifest │ │ Phase    │ │ Approval          │    │
│  │ Parser   │ │ Reader   │ │ Manager           │    │
│  └──────────┘ └──────────┘ └──────────────────┘    │
│  ┌──────────────────┐ ┌────────────────────────┐   │
│  │ File Watcher     │ │ SSE Stream Server      │   │
│  │ (chokidar)       │ │                        │   │
│  └──────────────────┘ └────────────────────────┘   │
├─────────────────────────────────────────────────────┤
│              File System (planning repo)              │
│  manifest.yaml │ services/ │ contracts/ │ phases/    │
└─────────────────────────────────────────────────────┘
```

## BFF Layer Pattern

The UI communicates with the planning repo exclusively through a dedicated BFF service (`agent-orchestration-bff`). The BFF is a **separate service** — not embedded API routes inside the UI. Direct filesystem access from the client is not permitted.

The BFF owns:
- Reading/writing `manifest.yaml` and planning repo files
- Serving specs, contracts, and phase status to the UI
- Managing the approval workflow (approvals.json)
- Watching the filesystem for changes and streaming updates via SSE

### Required BFF Endpoints

```
/api/v1/manifest              — Read/write manifest.yaml
/api/v1/phases/:phase         — Phase status (read from phases/ directory)
/api/v1/services/:name        — Service specs and status
/api/v1/contracts             — Contract browser
/api/v1/approvals             — Review gate workflow
/api/v1/events/stream         — SSE endpoint for real-time file change updates
```

### Manifest as State

The `manifest.yaml` is the single source of truth. The BFF reads it for all state — no separate database is needed initially. For approval workflows and audit trails, extend with a lightweight `approvals.json` alongside the manifest.

## Real-Time Updates via File Watchers

Use `chokidar` to watch the planning repo for changes and push updates to the UI via SSE:

- Watch for: specs generated, phases completed, contracts extracted, manifest changes
- SSE is preferred over WebSocket for file-change events (simpler, sufficient for this use case)
- Debounce filesystem events (200ms) to avoid flooding the client during agent writes

## UI Template Integration

If scaffolding from an existing UI template or component library, map its features to Agent Architect concerns:

| UI Concern | How It Maps |
|---|---|
| Sidebar nav | Phase-based navigation (Discover → Architect → Specify → Contract → Build → Validate → Review) |
| Auth context | Optional — useful if deploying as shared team tool with an SSO/OAuth provider |
| State management | Manifest state, phase status, active service tracking |
| Feature flags | Toggle advanced features (auto-approve, etc.) |
| Data tables | Service list, contract browser, quality scorecard |
| Forms | Manifest editor, approval forms |
| Dark mode | Recommended — support light and dark themes |
| Component docs (Storybook, etc.) | Document new agent-architect-specific components |
| Loading/Error states | Feedback for BFF requests and SSE connection status |
| HTTP client interceptors | BFF API calls with consistent error handling |

## Markdown Rendering

Specs and contracts are markdown files rendered in-browser:

- Use `react-markdown` + `remark-gfm` for GitHub-flavored markdown
- Add Mermaid plugin for architecture diagrams embedded in specs
- Support inline commenting for spec review workflows

## Repository Separation

Both the UI and the BFF are **separate repositories** from the planning repo. Neither lives inside the planning repo — this keeps it clean as a specification-only workspace.

- `agent-architect-ui` — Frontend. Talks only to the BFF, never to the filesystem directly.
- `agent-orchestration-bff` — Backend service. Owns all filesystem I/O.
- Planning repo — The workspace the BFF reads/writes. Contains manifest, specs, contracts, phases.

Both services are registered in the planning repo's `manifest.yaml` so agents can discover and build them.
