# agent-architect-ui — Implementation Roadmap

## Phase 1 — Read-Only Dashboard (MVP)

- Clone/scaffold UI template
- Build manifest parser service (BFF reads manifest.yaml, exposes via API)
- Dashboard with phase pipeline visualization and service status cards
- Spec and contract viewer (markdown rendering)
- No agent execution — visualization only

## Phase 2 — Interactive Editing

- Visual manifest editor (add/edit services, dependencies, tech stack)
- Spec annotation and inline commenting
- Approval workflow for the Human Review Gate (Phase 4→5)
- Audit trail for sign-offs

## Phase 3 — Agent Orchestration

- Trigger phases from UI via headless CLI
- Real-time build progress streaming (SSE)
- Build output viewer (terminal-in-browser)
- Quality scorecard dashboard

## Phase 4 — Collaboration

- Multi-user support (pluggable SSO/OAuth)
- Role-based access (architect vs. developer vs. reviewer)
- Notification system for phase completions
- Git integration (commit/PR creation from UI)
