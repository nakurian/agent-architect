# Ticket-Driven Feature: Jira → Context → Build

You are the **Feature Agent**. Your job is to take a Jira ticket, pull its context, determine which services are affected, and drive the framework phases to implement the feature — with the Jira key tracked everywhere.

## Usage
```
/project:feature GS-123
/project:feature GS-123 --team    # also start team mode for multi-service features
```

Parse `$ARGUMENTS` to extract:
- **Jira key** (required): first argument, e.g., `GS-123`
- **--team** flag (optional): if present, spawn the agent team after context setup

If `$ARGUMENTS` is empty, ask the human for the Jira ticket key.

## Prerequisites
- `manifest.yaml` must exist (Phase 0 completed or at minimum the manifest is configured)
- Atlassian MCP must be available (`mcp__plugin_atlassian_atlassian__*` tools)
  - If Atlassian MCP is NOT available: warn the human, then ask them to paste the ticket details manually (summary, description, acceptance criteria, type, priority, affected services). Continue with manual input.

## Instructions

### Step 0: Initialize Serena MCP (Context Efficiency)

Follow the **Agent Startup Protocol** from CLAUDE.md:
1. Check if `plugin:serena:serena` MCP tools are available
2. If available: call `check_onboarding_performed`, then `activate_project` with this planning repo's path
3. If not available: note it, use Grep/Glob/Read with offset+limit as fallbacks
4. During Phase 5 build steps (Step 7), **re-activate Serena** on each service's `local_path` before navigating the service codebase

### Step 1: Read the Jira Ticket

Use the Atlassian MCP to fetch the ticket:
1. Call `getJiraIssue` with the ticket key from `$ARGUMENTS`
2. Extract these fields:
   - **Summary** — ticket title
   - **Description** — full description (may contain acceptance criteria, business context)
   - **Issue Type** — Story, Task, Epic, Spike
   - **Priority** — P1/P2/P3/P4 or Critical/High/Medium/Low
   - **Labels** — may indicate affected services or domains
   - **Acceptance Criteria** — from description or custom field
   - **Linked Issues** — parent epic, blockers, related tickets
   - **Assignee** — who owns it
   - **Components** — Jira components (often map to services)
3. If the ticket is an **Epic**: list its child issues. Each child may become a separate feature cycle.
4. If the ticket has **linked issues**: note them — they may reveal dependencies or related work in progress.

Present a summary to the human:
```
📋 [TICKET-KEY]: [Summary]
Type: [type] | Priority: [priority]
Labels: [labels]

Description:
[first ~500 chars or full if short]

Acceptance Criteria:
[extracted criteria, numbered]

Linked Issues:
- [KEY]: [summary] (relationship: blocks/is-blocked-by/relates-to)
```

Ask: "Does this look right? Any additional context I should know before proceeding?"

### Step 2: Determine Affected Services

Analyze the ticket to determine which services need changes:

1. **Read `manifest.yaml`** — get the full service list with types and dependencies
2. **Match from ticket content**:
   - Check ticket labels/components against service names
   - Scan description for service names, API endpoints, or domain terms
   - Check `depends_on` chains — if service A is affected, its BFF/UI consumers may need changes too
3. **Check existing specs** — read `services/*/specs/SPEC.md` headers to understand what each service currently does
4. **Infer from business domain**:
   - Order-related → `order-service`, potentially `api-gateway`
   - User-related → `user-service`
   - UI changes mentioned → the relevant `ui` type service + its BFF

Present the assessment:
```
Affected Services (my analysis):
  ✅ order-service — [reason: "ticket mentions order enrichment"]
  ✅ api-gateway — [reason: "depends on order-service, needs new endpoint"]
  ⚠️  admin-ui — [reason: "might need UI for new entitlement view — unclear"]

Services NOT affected:
  ⬚ voyage-service — no voyage-related changes
```

Ask: "Is this scope correct? Should I add or remove any services?"

### Step 3: Register the Ticket in Manifest

After the human confirms scope, update `manifest.yaml`:

1. **Check for duplicate/conflicting tickets**: Read `active_tickets` for:
   - An existing entry with the **same Jira key** — if found and status is `in-progress`, ask the human: "This ticket is already registered as in-progress. Resume the existing work, or restart from scratch?"
   - Other `in-progress` tickets targeting the **same services** — warn the human: "Note: [OTHER-KEY] is also in-progress and affects [overlapping-services]. There may be branch conflicts."

2. Add or update the `active_tickets` section:
```yaml
active_tickets:
  - key: "GS-123"
    type: "feature"
    summary: "Add order enrichment"
    priority: "High"
    services:
      - "order-service"
      - "api-gateway"
    branch_prefix: "feat/GS-123"
    started: "2026-03-30"            # today's date
    status: "in-progress"
```

3. **Update `build_targets`** to include the affected services:
   - If `build_targets` is empty (`[]`) — set it to the affected services
   - If `build_targets` already has values — ASK the human: "build_targets currently contains [existing]. Should I merge these services in, or replace the list?"
   - Record the original `build_targets` value in the `active_tickets` entry (under `notes`) so it can be restored after the feature completes

### Step 4: Update Context Files

For each affected service:

1. **If `services/<name>/CONTEXT.md` exists** — append a new section:
```markdown
## Feature: [TICKET-KEY] — [Summary]
<!-- Source: Jira [TICKET-KEY] — added [today] -->

### Business Context
[From ticket description — what and why]

### Acceptance Criteria
[Numbered list from the ticket]

### Technical Notes
[Any technical details from the ticket or linked issues]
```

2. **If the service doesn't exist yet** — run the add-service logic:
   - Create `services/<name>/` from template
   - Add to `manifest.yaml` services list
   - Fill in CONTEXT.md with the ticket details

3. **Update `context/PROJECT.md`** if this feature introduces new business concepts or workflows not yet documented (append, don't overwrite).

### Step 5: Determine Phase Strategy

Based on the ticket scope and current project state, decide which phases to run:

| Scenario | Phases to Run |
|----------|---------------|
| **New service needed** | 1-discover → 2-architect → 3-specify → 4-contract → 5-build |
| **New feature on existing spec** | 3-specify (update) → 4-contract (if new APIs) → 5-build |
| **Small enhancement, spec exists** | 3-specify (update) → 5-build (or rebuild-service) |
| **UI-only change** | 3-specify (UI service only) → 5-build |
| **Multi-service coordinated feature** | 1-discover → full pipeline, consider --team mode |

Present the plan:
```
Phase Strategy for [TICKET-KEY]:
  1. Update spec for order-service (Phase 3 — incremental)
  2. Update spec for api-gateway (Phase 3 — incremental)
  3. Update contracts (Phase 4 — if new cross-service APIs)
  4. Build order-service (Phase 5)
  5. Build api-gateway (Phase 5)

Estimated complexity: [low/medium/high]
```

Ask: "Should I proceed with this plan? Or would you like to adjust the phases?"

### Step 6: Execute Phases with Jira Tracking

Run each phase, injecting the Jira key into all outputs:

#### Branch Naming
When Phase 5 (build) creates branches:
```
feat/{TICKET-KEY}-{short-description}
# Example: feat/GS-123-guest-entitlements
```

#### Spec Tagging
When Phase 3 updates specs, add a traceability header to new/modified sections:
```markdown
<!-- Ticket: GS-123 — Guest Entitlement Enrichment -->
### 4.7 Entitlement Enrichment Endpoint
...
```

#### Test Case IDs
Test cases generated for this feature use the ticket key:
```
TC-{SERVICE}-{TICKET-KEY}-001
# Example: TC-GUEST-GS123-001
```

#### Commit Messages
All commits reference the ticket:
```
feat(GS-123): add entitlement enrichment endpoint
feat(GS-123): add entitlement BFF aggregation
test(GS-123): add entitlement service unit tests
```

#### BUILD-REPORT.md
Add a ticket reference section:
```markdown
## Ticket Reference
- **Jira**: GS-123
- **Summary**: Add order enrichment
- **Acceptance Criteria Status**:
  - [x] AC-1: Guest entitlements returned in profile response
  - [x] AC-2: Entitlements cached for 5 minutes
  - [ ] AC-3: Admin UI shows entitlement badges (deferred — separate ticket)
```

### Step 7: Run Each Phase

For each phase in the strategy:

1. **Announce**: "Starting Phase [N] for [TICKET-KEY]..."
2. **Execute**: Run the phase command (follow the existing phase command instructions exactly)
3. **Track**: Ensure all outputs include the Jira key per Step 6 conventions
4. **Checkpoint**: After each phase, briefly summarize what was done and ask if the human wants to continue or pause

If `--team` flag was provided:
- Instead of running phases sequentially, call `/project:team-start` with the affected services
- The team will orchestrate phases 1-7 automatically
- The ticket context from Steps 1-4 will already be in place for the team to use

### Step 8: Update the Jira Ticket

After the build completes (or at meaningful milestones):

1. **Add a comment to the Jira ticket** using `addCommentToJiraIssue`:
```
🤖 Agent Build Report — [date]

Services built: [list]
Branch(es): feat/GS-123-guest-entitlements
PR: [link if created]

Build Status: ✅ Complete
Test Coverage: [N]%
Acceptance Criteria: [N/M] met

Details: See BUILD-REPORT.md in the planning repo.
```

2. **If a PR was created**: Add the PR link as a remote link on the Jira ticket (if the MCP supports it)

3. **Transition the ticket** (if appropriate):
   - If the ticket was "To Do" or "In Progress" → move to "In Review" or "Code Review" (use `getTransitionsForJiraIssue` to find available transitions, then `transitionJiraIssue`)
   - ASK the human before transitioning: "Should I move [TICKET-KEY] to [status]?"

### Step 9: Update Ticket Status in Manifest

Update the ticket entry in `manifest.yaml`:
```yaml
active_tickets:
  - key: "GS-123"
    type: "feature"
    summary: "Add order enrichment"
    priority: "High"
    services:
      - "order-service"
      - "api-gateway"
    branch_prefix: "feat/GS-123"
    started: "2026-03-30"
    status: "built"                    # updated from "in-progress"
    completed: "2026-03-30"
    pr_links:
      - "https://github.com/org/order-service/pull/42"
      - "https://github.com/org/api-gateway/pull/18"
    acceptance_criteria_met: "2/3"     # met/total — see BUILD-REPORT for detail
    notes: "AC-3 deferred to GS-456"
```

### Step 10: Summary

Present the final summary:
```
✅ Feature [TICKET-KEY] — Complete

Services Modified:
  - order-service: feat/GS-123-guest-entitlements → PR #42
  - api-gateway: feat/GS-123-api-gateway-entitlements → PR #18

Acceptance Criteria: 2/3 met (AC-3 deferred)
Test Coverage: order-service 87%, api-gateway 82%
Jira Updated: Comment added, status → In Review

Next Steps:
  - Review PRs
  - Run /project:6-validate for integration testing
  - Address AC-3 in follow-up ticket GS-456
```

## Important Rules

- **Jira key is sacred** — it must appear in EVERY branch name, commit message, spec section, test case ID, and report generated during this feature's lifecycle
- **Always ask before transitioning Jira tickets** — never auto-transition without confirmation
- **Respect existing specs** — when updating specs for a new feature, APPEND sections rather than rewriting existing ones. Use the ticket key as a marker so changes are traceable
- **Scope discipline** — only touch services confirmed in Step 2. If you discover additional services need changes during build, STOP and ask the human before expanding scope
- **Fallback gracefully** — if Atlassian MCP is unavailable, the command still works with manual input. Don't fail hard on MCP issues
- **Don't duplicate phases** — if a phase was already completed for the full project, only re-run the incremental parts needed for this ticket's scope
- **Track acceptance criteria** — every AC from the ticket must be explicitly addressed (implemented, deferred with reason, or marked out-of-scope with justification)
- **One ticket, one feature command** — don't try to batch multiple tickets. For multi-ticket work, use `/project:team-start` with ticket list
