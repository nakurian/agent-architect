# Agent Architect

A template repository for building multi-microservice systems using AI coding tools as your development team.

**No custom tooling. No learning curve. Just folders, markdown, and your AI coding tool.**

**Works with:** Claude Code | GitHub Copilot (agent mode) | Any AI tool that reads markdown

> **New here?** Read **[HOW-TO-USE.md](HOW-TO-USE.md)** for the complete step-by-step guide.

## Quick Start

### 1. Create your project from this template

```bash
# Use GitHub template (recommended)
gh repo create my-project-plan --template your-org/agent-architect --private
cd my-project-plan
```

### 2. One-time setup for Agent Teams

Add this to `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### 3. Run the interactive setup

```bash
claude                  # Open Claude Code in this directory
/project:0-setup        # Agent interviews you and populates everything
```

The setup agent asks about your project one topic at a time:
- Project name, description, business domain
- Tech stack (language, framework, database, testing)
- Business context (what you're building, for whom, core workflows)
- Services (name, type, existing repo, dependencies)
- Quality gates (review requirements, coverage thresholds)

Every answer is **saved immediately** to the right file. If interrupted, re-run and it picks up where you left off.

### 4. (Optional) Add reference materials

```bash
cp ~/Downloads/requirements.pdf context/references/requirements/
cp ~/Downloads/api-spec.yaml context/references/existing-apis/
cp ~/Downloads/wireframes.png context/references/designs/
```

### 5. Choose your mode and go

#### Option A: Sequential Mode (1–2 services)

Run phases manually, one at a time:

```bash
/project:1-discover            # Agent analyzes everything, asks clarifying questions
/project:2-architect           # Agent designs system + test strategy ADR
/project:3-specify             # Agent writes SPEC.md + TEST-PLAN.md per service
/project:4-contract            # Agent generates API contracts + integration test plan

# Review and approve specs, test plans, and contracts before building

/project:5-build order-service # Build one service at a time
/project:6-validate            # Verify services work together
/project:7-review              # Security, quality, and test completeness review
```

#### Option B: Team Mode (3+ services, recommended)

One command — agents handle Phases 1–7 automatically:

```bash
/project:team-start
```

---

## How Team Mode Works

Running `/project:team-start` spawns **5 specialized agents** that orchestrate all remaining phases:

| Agent | Model | Role |
|-------|-------|------|
| **Team Lead / PO** (your session) | opus | Orchestrates, enforces gates, relays your decisions |
| **Sr. Solutions Architect** | opus | Discovery, architecture, contracts, cross-service review |
| **Sr. Lead Engineer** | opus | Specs, test plans, builds services |
| **Sr. QA & Security** | sonnet | Test plan augmentation, validation, security review |
| **Sr. DevOps** | sonnet | Dockerfiles, CI/CD, docker-compose, deployment review |

### What the agents do

```
Phase 1  Architect discovers alone, surfaces blocking questions for you
Phase 2  Architect designs → 3 reviewers challenge in parallel → you approve
Phase 3  Engineer writes specs per service (parallel) → QA augments each → you approve
Phase 4  Architect generates contracts → Engineer reviews → you approve
Phase 5  Layer 0 services build in parallel + DevOps builds infra + QA builds test harness
         Layer 1+ services start as their dependencies complete
Phase 6  QA leads cross-service validation + DevOps support
Phase 7  4 parallel reviews (security, architecture, code quality, infra) → final report
```

Agents **challenge each other** — architect vs engineer on feasibility, QA vs engineer on testability, DevOps vs architect on deployability.

### What you do

Between gates, agents work autonomously. You intervene at **4 quality gates**:

| Gate | When | What You Review |
|------|------|-----------------|
| **Spec review** | After Phase 3 | `services/*/specs/SPEC.md` — API designs, business rules |
| **Test plan review** | After Phase 3 | `services/*/specs/TEST-PLAN.md` — test case thoroughness |
| **Contract review** | After Phase 4 | `contracts/CONTRACT-MATRIX.md` — cross-service consistency |
| **Production readiness** | After Phase 7 | `phases/7-review.md` — per-service scorecards |

You'll also answer the architect's **blocking questions** after Phase 1 discovery.

### Check progress anytime

```bash
/project:status            # Phase progress and service states
/project:team-status       # Enhanced: agent assignments, test coverage, gate status
```

---

## Sequential vs Team Mode

| | Sequential | Team |
|---|---|---|
| **How it runs** | You trigger each `/project:N` command | Agents auto-orchestrate Phases 1–7 |
| **Parallelism** | Manual (multiple terminals) | Built-in (services build in dependency layers) |
| **Cross-checking** | Single agent per phase | Agents challenge each other's work |
| **Review depth** | 1 review perspective | 4 parallel review perspectives |
| **You intervene** | Between every phase | Only at quality gates |
| **Best for** | 1–2 services | 3+ services |

Transition is non-destructive — `/project:team-start` detects existing progress and picks up from the next incomplete phase.

---

## Phase Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 0: /project:0-setup        → Interactive project setup    │
│           Agent interviews you, populates manifest + standards   │
│           + PROJECT.md + service folders. No blank forms.        │
├─────────────────────────────────────────────────────────────────┤
│  Phase 1: /project:1-discover     → Gap analysis & questions    │
│  Phase 2: /project:2-architect    → System design & ADRs        │
│  Phase 3: /project:3-specify      → Specs + test plans / service│
│  Phase 4: /project:4-contract     → API contracts + integration │
│                                      test plan                   │
│               HUMAN REVIEW GATE                                  │
│                                                                  │
│  Phase 5: /project:5-build        → Build with test traceability│
│  Phase 6: /project:6-validate     → Cross-service validation    │
│  Phase 7: /project:7-review       → Security, quality & test    │
│                                      completeness review         │
├─────────────────────────────────────────────────────────────────┤
│  TEAM MODE (optional):                                           │
│  /project:team-start              → Spawn 5-agent team that      │
│                                      auto-orchestrates Phases 1-7│
└─────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
.
├── manifest.yaml              # Single source of truth (services, stack, quality gates)
├── manifest.local.yaml        # Machine-specific paths (gitignored, per developer)
├── CLAUDE.md                  # Agent instructions
│
├── context/                   # Human-maintained inputs
│   ├── PROJECT.md             #    Business overview
│   ├── references/            #    Supporting documents (PRDs, wireframes, API specs)
│   └── decisions/             #    Architecture Decision Records
│
├── services/                  # Per-service context & specs
│   ├── .template/             #    Template for new services
│   └── {service-name}/
│       ├── CONTEXT.md         #    Human-written service context
│       ├── references/        #    Service-specific references
│       └── specs/
│           ├── SPEC.md        #    Generated by spec agent (Phase 3)
│           ├── TEST-PLAN.md   #    Test cases with traceability (Phase 3)
│           ├── BUILD-REPORT.md#    Build results (Phase 5)
│           └── TEST-REPORT.md #    Test execution results (Phase 5)
│
├── contracts/                 # Cross-service interfaces
│   ├── api/                   #    OpenAPI specs (service-to-service)
│   ├── events/                #    Event JSON schemas
│   ├── shared-models/         #    Shared data types
│   ├── CONTRACT-MATRIX.md     #    Interface overview
│   └── INTEGRATION-TEST-PLAN.md   Cross-service test scenarios (Phase 4)
│
├── standards/                 # Engineering standards
│   ├── backend-system-design-standard.md   Backend Java/Spring Boot standard
│   ├── coding-standards.md                 Backend + frontend conventions
│   ├── api-design.md                       REST conventions, response envelope
│   ├── testing-standards.md                Test pyramid, edge cases, templates
│   └── ui-architecture.md                  Next.js/React/MUI frontend standard
│
├── phases/                    # Phase completion tracking
│
├── .claude/commands/project/  # Claude Code slash commands (/project:*)
│
├── .github/prompts/project/   # Copilot prompt files (synced from commands)
│
└── scripts/
    └── sync-prompts.sh        # Sync Claude commands → Copilot prompts
```

## Key Concepts

### manifest.yaml drives everything
Every agent reads the manifest first. Change the tech stack, agents generate different code. Change build_targets, agents focus on different services. Change a service status to `skip`, agents ignore it.

### Specs + test plans are the quality gate
The most important outputs are `services/*/specs/SPEC.md` and `TEST-PLAN.md`. A good spec produces good code. A good test plan catches bugs before they ship. Every test in code traces back to a test case ID (`// Covers: TC-ORD-ACC-001`), which traces back to a SPEC.md section.

### Contracts prevent integration failures
Cross-service API contracts in `contracts/` are shared truth. Both provider and consumer reference the same file. `INTEGRATION-TEST-PLAN.md` defines cross-service test scenarios, failure cascades, and eventual consistency verification.

### Phases are checkpoints, not walls
You can re-run any phase. Updated the requirements? Re-run discover + architect + specify. Found a bug in the spec? Fix it, then rebuild-service. The framework is iterative.

## Advanced Usage

### Building services in parallel (sequential mode)
```bash
# Run multiple Claude Code sessions (one per service)
# Terminal 1:
claude -p "/project:5-build order-service"
# Terminal 2:
claude -p "/project:5-build payment-service"
```

### Upgrading from sequential to team mode
```bash
/project:team-migrate      # Detects progress, upgrades to v2.0
/project:team-start        # Resumes from next incomplete phase
```

### Using with GitHub Copilot

The framework works with Copilot out of the box:

```bash
# Copilot reads .github/copilot-instructions.md (synced from CLAUDE.md)
# Copilot prompt files live in .github/prompts/project/*.prompt.md

# In VS Code Copilot Chat (agent mode), type / to see available prompts

# After editing any .claude/commands/project/*.md, sync to Copilot:
./scripts/sync-prompts.sh
```

### Enriching existing services
1. Set service status to `enrich` in manifest
2. Put the existing API spec in `services/<name>/references/`
3. Describe what needs to change in `services/<name>/CONTEXT.md`
4. Run phases 3-7 — specs will focus only on changes

## All Commands

### Phase Commands
```
/project:0-setup                    Interactive project setup (run first!)
/project:1-discover                 Discovery & gap analysis
/project:2-architect                Architecture & ADRs
/project:3-specify                  Specs + test plans (all services)
/project:3-specify order-service    Spec + test plan (one service)
/project:4-contract                 Contracts + integration test plan
/project:5-build order-service      Build with test traceability
/project:6-validate                 Cross-service validation
/project:7-review                   Quality + test completeness review
/project:retrospective              Post-iteration self-improvement
```

### Utility Commands
```
/project:status                     Progress dashboard
/project:add-service <name> <type>  Scaffold a new service folder
/project:rebuild-service <name>     Rebuild after changes
```

### Team Commands
```
/project:team-start                 Spawn 5-agent team, auto-orchestrate
/project:team-migrate               Upgrade v1 repo to v2.0
/project:team-status                Enhanced status with agents & tests
```

## FAQ

**Q: Where does the actual code live?**
A: Each service has a `local_path` in `manifest.yaml` pointing to its code directory. This can be anywhere — a sibling folder, an existing repo, a monorepo path. The builder agent asks for the path on first build and saves it. This planning repo only holds context, specs, and contracts — never code.

**Q: Can I skip phases?**
A: Phases 1-4 build on each other. You can skip 6-7 but they catch real issues. Phase 5 requires phase 3 (specs); phase 4 (contracts) is recommended for services with cross-service dependencies.

**Q: How do I handle changing requirements?**
A: Update `context/PROJECT.md` or the service's `CONTEXT.md`, then re-run from the phase that's affected. Specs are regenerated, builders can rebuild.

**Q: What if I have 10+ services?**
A: Use `build_targets` in manifest.yaml to focus on 2-3 at a time. The framework handles any number of services but building is most effective in small batches.

**Q: Can multiple developers work on this simultaneously?**
A: Yes. The planning repo is shared (manifest.yaml, specs, contracts). Machine-specific paths live in `manifest.local.yaml` (gitignored). Each developer creates their own from `manifest.local.yaml.example`.

**Q: How does the approval process work?**
A: Quality gates in `manifest.yaml` define what needs approval. The Team Lead pauses at each gate and presents work for your review. Approvals are recorded in the manifest under `approvals:` with who approved, when, and any notes.
