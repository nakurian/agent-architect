# How To Use — Agent Architect

A step-by-step guide for team members using this framework to plan and build microservices projects.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Getting Started (New Project)](#getting-started-new-project)
- [Phase-by-Phase Walkthrough](#phase-by-phase-walkthrough)
- [Common Workflows](#common-workflows)
- [Using with Claude Code](#using-with-claude-code)
- [Using with GitHub Copilot](#using-with-github-copilot)
- [Team Collaboration](#team-collaboration)
- [Troubleshooting](#troubleshooting)
- [Reference: All Commands](#reference-all-commands)

---

## Prerequisites

You need ONE of the following AI coding tools:

| Tool | Install | Minimum Version |
|------|---------|----------------|
| **Claude Code** (recommended) | `npm install -g @anthropic-ai/claude-code` | Any |
| **GitHub Copilot** | VS Code extension + Copilot subscription | Agent mode (GA) |

No other dependencies. The framework is just markdown files and folders.

---

## Getting Started (New Project)

### Step 1: Create your project repo from this template

```bash
# Option A: GitHub template (recommended)
gh repo create my-project-plan --template your-org/agent-architect --private
cd my-project-plan

# Option B: Clone and disconnect
git clone https://github.com/your-org/agent-architect.git my-project-plan
cd my-project-plan
rm -rf .git && git init
git add -A && git commit -m "feat: init from agent-architect template"
```

### Step 2: Run Phase 0 — Interactive Setup

This is the **only step that requires human input**. The agent interviews you and configures everything.

**With Claude Code:**
```bash
claude
/project:0-setup
```

**With Copilot (VS Code):**
```
# Open Copilot Chat → select "Agent" mode → type:
/0-setup
```

The agent will ask you about (one topic at a time):

```
1. Project name and description          → saves to manifest.yaml
2. Tech stack (language, framework, DB)   → saves to manifest.yaml + standards/
3. Coding conventions and team rules      → saves to standards/coding-standards.md
4. What you're building and for whom      → saves to context/PROJECT.md
5. Each service and its details           → saves to manifest.yaml + services/*/CONTEXT.md
6. Quality gate preferences               → saves to manifest.yaml
```

**Tips:**
- Say **"defaults are fine"** for any section to accept sensible defaults
- Say **"not sure yet"** for anything — the discovery phase will flag it later
- If you get interrupted, re-run `/project:0-setup` — it detects what's already configured and picks up where you left off

### Step 3: Drop in reference materials (optional but recommended)

```bash
# Existing requirements docs
cp ~/Documents/PRD.pdf context/references/requirements/

# UI designs / wireframes
cp ~/Downloads/mockups.png context/references/designs/

# Existing API specs (OpenAPI, Swagger, Postman)
cp ~/projects/payment-api/swagger.yaml context/references/existing-apis/

# Confluence exports
cp ~/Downloads/arch-overview.pdf context/references/confluence/

# Data models / ERDs
cp ~/Documents/data-model.png context/references/data-models/
```

The discovery agent will read all of these in Phase 1.

### Step 4: You're ready — run the phases

Continue to the [Phase-by-Phase Walkthrough](#phase-by-phase-walkthrough) below.

---

## Phase-by-Phase Walkthrough

### Phase 1: Discovery

**What it does:** Reads ALL your context and produces a gap analysis.

```bash
/project:1-discover
```

**Output:** `phases/1-discover.md` containing:
- System understanding (agent's interpretation of what you're building)
- Service map (each service's role and boundaries)
- Gap analysis (what's missing or unclear)
- Risk assessment (where things could go wrong)
- Questions for you (specific, with default assumptions)

**What you do next:**
1. Read `phases/1-discover.md`
2. Answer the questions — edit the file directly, or answer in chat
3. If the agent misunderstood something, clarify in `context/PROJECT.md`
4. Move to Phase 2 when satisfied

**Time:** 2-5 minutes (agent), 10-30 minutes (your review)

---

### Phase 2: Architecture

**What it does:** Makes system-level design decisions based on your context + answers.

```bash
/project:2-architect
```

**Output:**
- `phases/2-architect.md` — architecture document with diagrams, service boundaries, cross-cutting concerns
- `context/decisions/ADR-*.md` — architecture decision records (database strategy, auth, communication patterns, **test strategy**)
- Dependency graph showing build order

**What you do next:**
1. Review the architecture document — does the service decomposition make sense?
2. Review ADRs — do you agree with the decisions?
3. If the agent suggests manifest changes, review and confirm
4. Move to Phase 3 when satisfied

**Time:** 3-10 minutes (agent), 15-30 minutes (your review)

---

### Phase 3: Specification

**What it does:** Writes detailed, buildable specs for each service.

```bash
# All services at once (for small projects, < 5 services)
/project:3-specify

# One service at a time (recommended for larger projects)
/project:3-specify order-service
/project:3-specify bff-gateway
/project:3-specify web-ui
```

**Output per service:**
- `services/<name>/specs/SPEC.md` — implementation specification containing:
  - API endpoints with exact request/response schemas
  - Data models with field types and constraints
  - Business logic with preconditions, flows, and error cases
  - Events published/subscribed with schemas
  - Integration points with failure handling
  - Implementation sequence (step-by-step build order)
  - Dependencies and package versions
  - Environment configuration
- `services/<name>/specs/TEST-PLAN.md` — comprehensive test cases containing:
  - Business acceptance tests (happy path user journeys)
  - Edge cases and boundary conditions (from systematic checklist)
  - Error scenarios (failures, timeouts, invalid input)
  - Security test cases (auth, injection, CORS — augmented by QA in team mode)
  - Performance test cases (load, latency)
  - Data integrity test cases (concurrent writes, idempotency)
  - Traceability matrix linking every test to a SPEC.md section

**What you do next:**
1. **This is the most important review.** Read each SPEC.md carefully
2. Check: Do the API designs make sense? Are business rules correct?
3. Check: Are there missing endpoints or edge cases?
4. Review TEST-PLAN.md — are the test cases thorough? Any missing scenarios?
5. Edit SPEC.md or TEST-PLAN.md directly if you want changes
6. Move to Phase 4 when all specs and test plans are reviewed

**Time:** 5-15 minutes per service (agent), 20-60 minutes per service (your review)

> **Note:** If you re-run this phase, the previous spec is saved as `SPEC.prev.md` so you can diff changes.

---

### Phase 4: Contracts

**What it does:** Extracts all cross-service interfaces into shared contract files.

```bash
/project:4-contract
```

**Output:**
- `contracts/api/<consumer>-to-<provider>.yaml` — OpenAPI specs for each service-to-service call
- `contracts/events/<event-name>.json` — JSON schemas for each async event
- `contracts/shared-models/<model>.json` — shared data types
- `contracts/CONTRACT-MATRIX.md` — overview of all interfaces
- `contracts/INTEGRATION-TEST-PLAN.md` — cross-service test scenarios:
  - End-to-end user journeys spanning multiple services
  - Failure cascade scenarios (what happens when a service is down)
  - Eventual consistency scenarios (event delivery delays)
  - Contract compliance verification plan

**What you do next:**
1. Review `CONTRACT-MATRIX.md` — does every service-to-service interaction have a contract?
2. Spot-check a few contract files — are the schemas correct?
3. Review `INTEGRATION-TEST-PLAN.md` — are the cross-service test scenarios realistic?
4. These contracts become the source of truth during building
5. Move to Phase 5

**Time:** 3-5 minutes (agent), 5-15 minutes (your review)

---

### HUMAN REVIEW GATE

Before building, ensure specs, test plans, and contracts are approved:

```bash
# Check status — are all specs, test plans, and contracts done?
/project:status
# Or with team details:
/project:team-status
```

The builder agent will ask for approval sign-off when you start Phase 5. Three quality gates must pass:
- **spec_review** — SPEC.md files reviewed and approved
- **test_plan_review** — TEST-PLAN.md files reviewed and approved
- **contract_review** — contracts and INTEGRATION-TEST-PLAN.md reviewed

This records who reviewed what in `manifest.yaml` under `approvals`.

---

### Phase 5: Build

**What it does:** Implements a single service from its spec.

```bash
# Build one service (recommended)
/project:5-build order-service

# Or let the agent pick from build_targets in manifest
/project:5-build
```

**First time — the agent asks where the code goes:**
```
I'm ready to build order-service. Where should the code live?

Options:
1. Enter an absolute path (e.g., /Users/you/projects/order-service)
2. Enter a relative path from this planning repo (e.g., ../order-service)
3. If this is an existing repo, I can clone from: [repo URL]
```

The path is saved to `manifest.local.yaml` (gitignored) — it never asks again.

**What the agent does:**
1. Scaffolds the project (framework, config, health check, Dockerfile)
2. Implements features in the spec's exact order
3. Writes tests alongside every feature — each test maps to a TEST-PLAN.md case ID (`// Covers: TC-ORD-ACC-001`)
4. Runs tests after each step
5. Commits after each step
6. Creates `services/<name>/specs/BUILD-REPORT.md` — what was built, deviations, gaps
7. Creates `services/<name>/specs/TEST-REPORT.md` — coverage %, test case mapping, P0/P1 completion

**What you do next:**
1. Read BUILD-REPORT.md — any gaps or deviations?
2. Read TEST-REPORT.md — are P0/P1 test cases implemented? Coverage meets threshold?
3. Run the service locally — does it start?
4. Review the code if desired
5. Repeat for the next service, or move to Phase 6

**Time:** 10-30 minutes per service (agent)

**Building multiple services in parallel:**
```bash
# Terminal 1
claude -p "/project:5-build order-service"

# Terminal 2
claude -p "/project:5-build bff-gateway"
```

---

### Phase 6: Validation

**What it does:** Verifies that built services work together.

```bash
/project:6-validate
```

**Output:** `phases/6-validate.md` containing:
- Contract compliance results (pass/fail per service)
- Cross-service integration test results (executing scenarios from `INTEGRATION-TEST-PLAN.md`)
- Contract test verification (Pact tests pass/fail)
- Test case coverage summary per service (from TEST-REPORT.md files)
- Docker compose for running all services together
- Issues found with recommended fixes

**What you do next:**
1. Review issues found
2. Run `/project:rebuild-service <name>` for any service that needs fixes
3. Move to Phase 7

**Time:** 5-15 minutes (agent), varies (fixing issues)

---

### Phase 7: Review

**What it does:** Reviews all generated code for production readiness.

```bash
/project:7-review
```

**Output:** `phases/7-review.md` — code review report with:
- Critical issues (must fix before production)
- Warnings (should fix)
- Suggestions (nice to have)
- Per-service scorecard (Security, Reliability, Performance, Maintainability, Testing, **Test Completeness**)

**What you do next:**
1. Fix critical issues using `/project:rebuild-service <name>`
2. Address warnings as appropriate
3. Your services are ready for deployment

**Time:** 5-10 minutes (agent), varies (fixing issues)

---

## Common Workflows

### Working from a Jira ticket (feature or bug)

The fastest way to go from ticket to code:

```bash
# Feature work — reads ticket, determines scope, runs phases
/project:feature GS-123

# Bug fix — reads ticket, diagnoses, fixes, creates PR
/project:bugfix GS-456
```

**What the feature agent does:**
1. Reads the Jira ticket (summary, description, acceptance criteria, priority)
2. Determines which services are affected (analyzes ticket + manifest)
3. Asks you to confirm the scope
4. Registers the ticket in `manifest.yaml` under `active_tickets`
5. Updates service CONTEXT.md files with the ticket details
6. Determines which phases to run (full pipeline for new services, incremental for existing)
7. Runs phases with the Jira key injected everywhere:
   - Branch: `feat/GS-123-guest-entitlements`
   - Commits: `feat(GS-123): add entitlement endpoint`
   - Test IDs: `TC-GUEST-GS123-001`
   - BUILD-REPORT.md: acceptance criteria status
8. Comments on the Jira ticket with build status and PR link
9. Optionally transitions the ticket (asks you first)

**What the bugfix agent does:**
1. Reads the bug ticket (steps to reproduce, expected vs actual, stack trace)
2. Identifies the affected service
3. Diagnoses the root cause — presents analysis for your confirmation
4. Creates `fix/GS-456-...` branch
5. Applies surgical fix + mandatory regression test
6. Verifies fix (tests + local)
7. Creates PR, comments on Jira

**For multi-service features:**
```bash
/project:feature GS-123 --team    # Spawns agent team for complex features
```

**If Atlassian MCP isn't available:** Both commands fall back to manual input — you paste the ticket details and continue normally.

---

### Adding a new service mid-project

```bash
/project:add-service notification-service domain

# Then fill in the context
vim services/notification-service/CONTEXT.md

# Re-run spec for just this service
/project:3-specify notification-service

# Re-run contracts to include new service interfaces
/project:4-contract

# Build it
/project:5-build notification-service
```

### Changing requirements after specs are written

```bash
# 1. Update the context
vim context/PROJECT.md                           # or service CONTEXT.md

# 2. Re-run spec for affected services
/project:3-specify order-service                 # previous spec saved as SPEC.prev.md

# 3. Review what changed
diff services/order-service/specs/SPEC.prev.md services/order-service/specs/SPEC.md

# 4. Re-run contracts if APIs changed
/project:4-contract

# 5. Rebuild the service
/project:rebuild-service order-service
```

### Enriching an existing service (adding features)

```bash
# 1. Set status to "enrich" in manifest.yaml
# 2. Put existing API spec in services/<name>/references/
# 3. Describe new features in services/<name>/CONTEXT.md
# 4. Run spec phase — it writes specs for NEW/CHANGED parts only
/project:3-specify payment-service

# 5. Build — agent modifies existing code, doesn't rebuild from scratch
/project:5-build payment-service
```

### Checking project progress

```bash
/project:status
```

Shows a dashboard with:
- Which phases are complete
- Which services have specs / are built
- Current build targets
- Recommended next action

### Fixing issues from code review

```bash
# After Phase 7 flags issues:
/project:rebuild-service order-service
# Agent reads the review report and fixes flagged issues
```

---

## Using with Claude Code

### Setup

```bash
# Install Claude Code (if not already installed)
npm install -g @anthropic-ai/claude-code

# Navigate to the planning repo
cd my-project-plan

# Start Claude Code
claude
```

### Running phases

All phases are slash commands prefixed with `/project:`:

```bash
# Phase commands
/project:0-setup                    # Interactive setup
/project:1-discover                 # Discovery
/project:2-architect                # Architecture + test strategy ADR
/project:3-specify                  # Specs + test plans (all services)
/project:3-specify order-service    # Spec + test plan (one service)
/project:4-contract                 # Contracts + integration test plan
/project:5-build order-service      # Build with test traceability
/project:6-validate                 # Cross-service validation
/project:7-review                   # Quality + test completeness review

# Ticket-driven commands (Jira integration)
/project:feature GS-123             # Jira ticket → context → phases → track
/project:feature GS-123 --team      # Same + spawn agent team
/project:bugfix GS-456              # Bug ticket → diagnose → fix → PR

# Utility commands
/project:status                     # Progress dashboard
/project:add-service name type      # Add new service
/project:rebuild-service name       # Rebuild after changes
/project:retrospective              # Post-iteration self-improvement

# Team orchestration commands
/project:team-start                 # Spawn 5-agent team, auto-orchestrate
/project:team-migrate               # Upgrade v1 repo to v2.0
/project:team-status                # Enhanced status with agents & tests
```

### Running headless (CI/automation)

```bash
# Run a phase non-interactively
claude -p "/project:3-specify order-service"

# Run build in background
claude -p "/project:5-build order-service" --allowedTools "Read,Edit,Write,Bash,Glob,Grep"
```

### Using Agent Teams (recommended for 3+ services)

Agent Teams spawn 5 specialized AI agents that orchestrate Phases 1-7 automatically.

```bash
# 1. Enable agent teams (one-time, in ~/.claude/settings.json)
#    "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }

# 2. Install tmux for split-pane visibility (optional but recommended)
brew install tmux    # macOS

# 3. Run Phase 0 solo (interactive)
/project:0-setup

# 4. Start the team
/project:team-start
```

**What happens:**
1. Team lead detects completed phases and creates a task dependency graph
2. 4 teammates spawn in tmux panes: architect, lead-engineer, qa-security, devops
3. Architect begins Phase 1 (Discovery) automatically
4. At quality gates, team lead presents deliverables and waits for your approval
5. In Phase 5, services build in parallel (lead-engineer builds, devops does infra, qa-security writes test harness)
6. In Phase 7, all agents review from their perspective (security, architecture, code quality, infrastructure)

**The 5 agents:**
| Agent | Model | Responsibilities |
|-------|-------|------------------|
| Team Lead / PO | opus | Orchestrates, enforces gates, relays human decisions |
| Sr. Architect | opus | Discovery, architecture, ADRs, contracts, cross-service review |
| Sr. Lead Engineer | opus | Specs, test plans, builds, code quality |
| Sr. QA & Security | sonnet | Security/perf tests, validation lead, review lead |
| Sr. DevOps | sonnet | Dockerfiles, CI/CD, docker-compose, infra review |

**Challenge dynamics:** Agents push back on each other — architect vs engineer on feasibility, QA vs engineer on testability, devops vs architect on deployability.

**For existing repos (migrate from sequential):**
```bash
/project:team-migrate     # Detects progress, adds framework section, shows summary
/project:team-start       # Resumes from next incomplete phase
```

**Check team progress:**
```bash
/project:team-status      # Shows agents, phases, test coverage, pending gates
```

---

## Using with GitHub Copilot

### Setup

1. Open the planning repo in VS Code
2. Ensure Copilot extension is installed and signed in
3. Copilot automatically reads `.github/copilot-instructions.md`

### Running phases

Open Copilot Chat in **Agent mode** (select "Agent" from the dropdown):

```
# Type / to see all available prompts:
/0-setup
/1-discover
/2-architect
/3-specify
/5-build
...

# Or describe what you want naturally:
"Run the discovery phase and analyze all context in this repo"
"Generate a spec for the order-service based on the architecture"
"Build the bff-gateway service following its SPEC.md"
```

### Using with Copilot Coding Agent (autonomous)

For autonomous execution via GitHub Issues:

1. Create a GitHub issue:
   ```
   Title: Build order-service from spec

   Follow the instructions in .github/prompts/project/5-build.prompt.md
   to build the order-service. The spec is at
   services/order-service/specs/SPEC.md.
   ```

2. Assign the issue to **Copilot**
3. Copilot creates a branch, builds the code, runs tests, opens a PR
4. Review the PR and provide feedback — Copilot iterates

### Keeping prompts in sync

After editing any `.claude/commands/project/*.md` file:

```bash
./scripts/sync-prompts.sh
```

This copies all Claude commands to `.github/prompts/` as Copilot prompt files.

---

## Team Collaboration

### Initial setup for each developer

When a new team member clones the planning repo:

```bash
git clone https://github.com/your-org/your-project-plan
cd my-project-plan

# Create local path overrides (machine-specific)
cp manifest.local.yaml.example manifest.local.yaml
vim manifest.local.yaml   # Set your local paths for each service
```

### What's shared vs local

| File | Shared (git) | Local (gitignored) |
|------|:-----------:|:-----------------:|
| `manifest.yaml` | Yes | — |
| `manifest.local.yaml` | — | Yes (paths) |
| `context/` | Yes | — |
| `services/*/CONTEXT.md` | Yes | — |
| `services/*/specs/SPEC.md` | Yes | — |
| `contracts/` | Yes | — |
| `standards/` | Yes | — |
| `phases/` | Yes | — |
| Service code repos | — | Yes (separate repos) |

### Typical team workflow

**Option A: Sequential (manual orchestration)**
```
   Lead Architect              Dev 1                    Dev 2
   ─────────────              ─────                    ─────
   /project:0-setup
   /project:1-discover
   /project:2-architect
   /project:3-specify         (generates SPEC.md + TEST-PLAN.md)
   /project:4-contract        (generates contracts + INTEGRATION-TEST-PLAN.md)
   ──── reviews & approves specs + test plans + contracts ────
                               /project:5-build         /project:5-build
                               order-service             payment-service

                               /project:5-build
                               bff-gateway

   /project:6-validate
   /project:7-review
                               /project:rebuild-service  /project:rebuild-service
                               order-service             payment-service
```

**Option B: Agent Teams (automated orchestration)**
```
   Human                       Agent Team (5 agents)
   ─────                       ─────────────────────
   /project:0-setup
   /project:team-start  ────→  architect: Phase 1 Discovery
                                architect: Phase 2 Architecture
                                  (all agents review)
                                lead-engineer: Phase 3 Specs + Test Plans
                                  (qa-security augments test plans)
                                architect: Phase 4 Contracts
   ← approve specs/tests/contracts →
                                lead-engineer: Build services (PARALLEL)
                                devops: Build infrastructure  (PARALLEL)
                                qa-security: Build test harness (PARALLEL)
                                qa-security: Phase 6 Validation
                                all agents: Phase 7 Review
   ← final approval →
```

### Approval tracking

When the builder agent starts, it checks if specs were approved:

```
Specs need approval before building.
Has someone reviewed the specs in services/*/specs/SPEC.md?
If yes, who approved?
```

The approval is recorded in `manifest.yaml`:
```yaml
approvals:
  spec_review:
    approved_by: "@lead-architect"
    date: "2026-03-17"
```

---

## Troubleshooting

### "Run /project:0-setup first"

The discovery agent detected that `manifest.yaml` hasn't been configured. Run Phase 0 first.

### Spec agent runs out of context / quality drops

For projects with 5+ services, specify one at a time:
```bash
/project:3-specify order-service
/project:3-specify bff-gateway
```

### Builder doesn't know where to put code

The `local_path` is empty. The agent will ask you for the path. Once provided, it's saved to `manifest.local.yaml` and won't ask again.

### I changed a spec but the builder uses the old one

Re-read the spec: the builder always reads `SPEC.md` fresh. If you edited it manually, just re-run the build:
```bash
/project:rebuild-service order-service
```

### Copilot prompts are outdated

After editing `.claude/commands/project/*.md`, re-sync:
```bash
./scripts/sync-prompts.sh
```

### Two developers have merge conflicts on manifest.yaml

This usually happens with `local_path` fields. Solution: local paths should ONLY be in `manifest.local.yaml` (gitignored). If paths leaked into `manifest.yaml`, move them to `manifest.local.yaml` and clear them in `manifest.yaml`.

### I want to start over on a service

```bash
# Reset the service status in manifest.yaml to "new"
# Delete the old specs and reports
rm services/order-service/specs/SPEC.md
rm services/order-service/specs/TEST-PLAN.md
rm services/order-service/specs/BUILD-REPORT.md
rm services/order-service/specs/TEST-REPORT.md

# Re-run from spec phase
/project:3-specify order-service
/project:5-build order-service
```

### Test coverage is below threshold

Check `TEST-REPORT.md` for the service — it shows which test cases are implemented and which are deferred. The `test_case_coverage_minimum` gate (default 95%) requires P0+P1 test cases to be implemented. Fix by implementing deferred test cases or adjusting the threshold in `manifest.yaml`.

### Team agents are stuck or idle

Check team status and manually nudge:
```bash
/project:team-status       # See which agents are active and what's blocking them
```

If an agent is idle, send it a message or restart the team:
```bash
/project:team-start        # Re-detects progress and resumes from current phase
```

### The agent adds features not in the spec

The builder is instructed to follow SPEC.md exactly. If it gold-plates, remind it:
```
Follow the SPEC.md exactly. Do not add features not in the spec.
```

---

## Reference: All Commands

### Phase Commands

| Command | Purpose | Input | Output |
|---------|---------|-------|--------|
| `/project:0-setup` | Interactive project setup | Your answers | manifest.yaml, PROJECT.md, standards, service folders |
| `/project:1-discover` | Analyze context | Everything in context/ + services/ | `phases/1-discover.md` |
| `/project:2-architect` | System design | Discovery + standards | `phases/2-architect.md` + ADRs (incl. test strategy) |
| `/project:3-specify [service]` | Write specs + test plans | Architecture + service context | `SPEC.md` + `TEST-PLAN.md` per service |
| `/project:4-contract` | Generate contracts + integration tests | All specs | `contracts/` + `INTEGRATION-TEST-PLAN.md` |
| `/project:5-build <service>` | Build with test traceability | Spec + test plan + contracts | Code + `BUILD-REPORT.md` + `TEST-REPORT.md` |
| `/project:6-validate` | Cross-service validation | Build/test reports + integration plan | `phases/6-validate.md` |
| `/project:7-review` | Quality + test completeness review | Built code + test reports | `phases/7-review.md` |

### Ticket-Driven Commands

| Command | Purpose | Input | Output |
|---------|---------|-------|--------|
| `/project:feature <JIRA-KEY>` | End-to-end feature from Jira ticket | Jira ticket | Context updates, specs, code, PRs — all tagged with Jira key |
| `/project:feature <JIRA-KEY> --team` | Same + agent team for multi-service | Jira ticket | Same as above with parallel agent orchestration |
| `/project:bugfix <JIRA-KEY>` | Surgical bugfix from Jira ticket | Jira bug ticket | Diagnosis, fix, regression test, PR — all tagged with Jira key |

### Utility Commands

| Command | Purpose |
|---------|---------|
| `/project:status` | Show phase progress and service states |
| `/project:add-service <name> <type>` | Scaffold a new service folder |
| `/project:rebuild-service <name>` | Incrementally rebuild after changes |
| `/project:retrospective` | Post-iteration self-improvement analysis |

### Team Orchestration Commands

| Command | Purpose |
|---------|---------|
| `/project:team-start` | Spawn 5-agent team, auto-orchestrate Phases 1-7 |
| `/project:team-migrate` | Upgrade v1 repo to team-capable (v2.0) |
| `/project:team-status` | Enhanced dashboard with agents, test coverage, gates |

### Manifest Fields (per service)

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique kebab-case identifier |
| `type` | Yes | `ui`, `bff`, `domain`, `shared-lib`, `infrastructure` |
| `status` | Yes | `new`, `existing`, `enrich`, `skip` |
| `description` | Yes | What this service does |
| `owner` | Recommended | Team or person responsible |
| `repo` | If existing | Git URL for clone/push |
| `local_path` | Set at build time | Where code lives on disk (saved in manifest.local.yaml) |
| `port` | Yes (null for shared-lib) | Service port number |
| `database` | Yes | Database name or `null` |
| `depends_on` | Yes | List of services this one calls |
| `owns_events` | Yes | List of events this service publishes |
| `notes` | Optional | Anything extra the agent should know |
