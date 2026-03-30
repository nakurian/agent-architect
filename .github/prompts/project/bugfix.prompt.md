# Ticket-Driven Bugfix: Jira → Diagnose → Fix → Verify

You are the **Bugfix Agent**. Your job is to take a Jira bug ticket, diagnose the issue, apply a targeted fix to the affected service(s), verify the fix, and track everything back to the Jira key.

Unlike `/project:feature` (which may run multiple phases), bugfixes are surgical — you read the bug, find the root cause, fix it, test it, and ship it.

## Usage
```
/project:bugfix GS-456
```

Parse `$ARGUMENTS` to extract the **Jira key** (required). If `$ARGUMENTS` is empty, ask the human for the Jira ticket key.

## Prerequisites
- `manifest.yaml` must exist
- At least one service must have been built (there must be code to fix)
- Atlassian MCP must be available (`mcp__plugin_atlassian_atlassian__*` tools)
  - If Atlassian MCP is NOT available: warn the human, then ask them to paste the bug details manually (summary, steps to reproduce, expected vs actual behavior, affected service, severity). Continue with manual input.

## Instructions

### Step 0: Initialize Serena MCP (Context Efficiency)

Follow the **Agent Startup Protocol** from CLAUDE.md:
1. Check if `plugin:serena:serena` MCP tools are available
2. If available: call `check_onboarding_performed`, then `activate_project` with this planning repo's path
3. If not available: note it, use Grep/Glob/Read with offset+limit as fallbacks
4. In Step 3 (Diagnose), **re-activate Serena** on the service's `local_path` — this is where Serena saves the most context (reading specific methods vs entire files)

### Step 1: Read the Bug Ticket

Use the Atlassian MCP to fetch the ticket:
1. Call `getJiraIssue` with the ticket key from `$ARGUMENTS`
2. Extract these fields:
   - **Summary** — bug title
   - **Description** — full description with steps to reproduce
   - **Severity/Priority** — Critical/High/Medium/Low
   - **Environment** — where the bug was found (prod, staging, dev, local)
   - **Steps to Reproduce** — exact steps
   - **Expected Behavior** — what should happen
   - **Actual Behavior** — what actually happens
   - **Affected Service/Component** — from labels, components, or description
   - **Stack Trace / Logs** — if attached or in description
   - **Linked Issues** — related bugs, parent story

Present a summary to the human:
```
🐛 [TICKET-KEY]: [Summary]
Severity: [severity] | Environment: [environment]

Steps to Reproduce:
[numbered steps]

Expected: [expected]
Actual: [actual]

Stack Trace / Error:
[if available, first ~20 lines]

Affected: [service/component from ticket]
```

Ask: "Does this capture the bug correctly? Any additional reproduction details?"

### Step 2: Identify the Affected Service

1. **Read `manifest.yaml`** — get the service list
2. **Match from ticket content**:
   - Check labels/components against service names
   - Parse stack traces for package names, class names, or service identifiers
   - Check error messages for API paths that map to specific services
   - If the bug is in a BFF or UI, determine if the root cause is in the BFF itself or a downstream domain service
3. **Check `manifest.local.yaml`** then `manifest.yaml` for the service's `local_path`
   - If `local_path` is empty, ask the human for the path to the service code

Present:
```
Root Cause Analysis — Initial Assessment:
  Service: order-service
  Likely area: [controller/service/dao/config/integration]
  Confidence: [high/medium/low]
  Reasoning: [why you think this is the affected area]
```

Ask: "Is this the right service? Should I look elsewhere?"

### Step 2.5: Register the Ticket Early

After the human confirms the affected service, immediately register the ticket in `manifest.yaml` so work is tracked even if the session is interrupted:

1. **Check for duplicate/conflicting tickets**: Read `active_tickets` for:
   - An existing entry with the **same Jira key** — if found and status is `in-progress`, ask: "This ticket is already registered. Resume or restart?"
   - Other `in-progress` tickets targeting the **same service** — warn about potential conflicts

2. Add to `active_tickets`:
```yaml
active_tickets:
  - key: "GS-456"
    type: "bugfix"
    summary: "[from ticket]"
    priority: "[from ticket]"
    services:
      - "order-service"
    branch_prefix: "fix/GS-456"
    started: "2026-03-30"
    status: "diagnosing"
```

### Step 3: Diagnose the Root Cause

Navigate to the service's `local_path` and investigate:

1. **Read existing specs** — `services/<service-name>/specs/SPEC.md` to understand intended behavior
2. **Read existing tests** — check if there are tests that should have caught this
3. **Search the codebase** for the affected area:
   - Use Grep/Serena to find the relevant code (endpoint, service method, event handler)
   - Read ONLY the affected files — not the entire codebase
   - Trace the code path from the entry point (API endpoint, event consumer) through to the bug
4. **Check recent changes** — `git log --oneline -20` to see if a recent commit might have introduced the bug
5. **Reproduce mentally** — walk through the code path with the reproduction steps to identify where it breaks

Present the diagnosis:
```
🔍 Root Cause Diagnosis:

File: src/main/java/com/example/order/service/EntitlementService.java
Line: ~87
Issue: [clear description of what's wrong]

Code path:
  1. Request hits GET /api/v1/orders/{id}/entitlements
  2. Controller calls EntitlementService.getForOrder(id)
  3. Service queries Couchbase — but uses wrong view name "entitlements_by_order"
     (should be "entitlements_by_order_id" per the Couchbase index)
  4. Returns empty result instead of 404 or actual data

Root cause: [one sentence]
Fix approach: [one sentence]
Risk: [low/medium/high — what else might this change affect?]
```

Ask: "Does this diagnosis make sense? Should I proceed with the fix?"

### Step 4: Create Feature Branch

1. `cd` to the service's `local_path`
2. `git fetch origin`
3. Determine the base branch: `git remote show origin | grep 'HEAD branch'`
4. Create bugfix branch: `git checkout -b fix/{TICKET-KEY}-{short-description} origin/{base-branch}`
   - Example: `fix/GS-456-entitlement-view-name`
5. Verify clean state: `git status`

### Step 5: Write the Fix

Apply the targeted fix:

1. **Fix the code** — make the minimum change needed to resolve the bug
   - Do NOT refactor surrounding code
   - Do NOT add unrelated improvements
   - Do NOT change APIs or interfaces unless the bug is in the interface itself
2. **Add a regression test** — write a test that:
   - Reproduces the exact bug scenario (would fail before the fix)
   - Verifies the correct behavior after the fix
   - Includes traceability: `// Regression: {TICKET-KEY} — {one-line description}`
   - If a TEST-PLAN.md exists, add the new test case with ID: `TC-{SERVICE}-{TICKET-KEY}-REG-001`
3. **Check related tests** — run existing tests to ensure the fix doesn't break anything
4. **If the bug reveals a gap in existing tests** — add additional test cases but keep them focused

### Step 6: Verify the Fix

1. **Run the full test suite** for the affected service
2. **Run the specific regression test** in isolation to confirm it passes
3. **If possible, test locally**:
   - Start the service
   - Execute the steps to reproduce from the ticket
   - Confirm the expected behavior now occurs
4. **Check for side effects**:
   - If this service has consumers (check `manifest.yaml` depends_on), verify the contract still holds
   - If this service publishes events, verify event schema hasn't changed unintentionally
   - Run contract tests if they exist

### Step 7: Update Reports

1. **Update `services/<service-name>/specs/BUILD-REPORT.md`** — append a bugfix section:
```markdown
## Bugfix: [TICKET-KEY] — [Summary]
<!-- Date: [today] -->

### Root Cause
[Brief description of what was wrong]

### Fix Applied
[What was changed and why]

### Regression Test
- Test: [test class/file and method name]
- Test Case ID: TC-{SERVICE}-{TICKET-KEY}-REG-001
- Covers: [the specific scenario that was broken]

### Verification
- Unit tests: ✅ [N] passing
- Regression test: ✅ passing
- Local verification: ✅ | ⬚ (not possible locally)
- Side effects checked: ✅ none detected
```

2. **Update `services/<service-name>/specs/TEST-REPORT.md`** — add the new test case:
```markdown
| TC-{SERVICE}-{TICKET-KEY}-REG-001 | Regression | [description] | ✅ | P0 |
```

### Step 8: Commit and PR

1. **Update the ticket entry in `manifest.yaml`** — change `status` from `"diagnosing"` to `"built"` and add:
```yaml
    status: "built"
    root_cause: "Wrong Couchbase view name in EntitlementService"
```

2. **Stage only the files you changed** — do NOT use `git add -A`. Bugfixes must be precise:
```bash
git add src/main/java/com/example/order/service/EntitlementService.java
git add src/test/java/com/example/order/service/EntitlementServiceTest.java
# Only the files you actually modified for this fix
```

3. **Commit the fix** with conventional commit format:
```
fix(GS-456): correct Couchbase view name for entitlement queries

The entitlement lookup used view "entitlements_by_order" instead of
"entitlements_by_order_id", causing empty results for valid orders.

Added regression test TC-ORDER-GS456-REG-001.
```

4. **Push and create PR**:
```
git push -u origin fix/GS-456-entitlement-view-name
gh pr create --title "fix(GS-456): correct entitlement query view name" --body "..."
```

PR body should include:
```markdown
## Bug Fix: [TICKET-KEY]

**Root Cause**: [one sentence]
**Fix**: [one sentence]
**Regression Test**: TC-{SERVICE}-{TICKET-KEY}-REG-001

### Verification
- [x] Regression test passes
- [x] Full test suite passes
- [x] Local verification (if applicable)
- [x] No side effects on dependent services

### Jira
[TICKET-KEY]: [link]
```

5. **Append to bugfix log** — create or append to `phases/bugfixes.md` so the retrospective agent can track bugfix work:
```markdown
## [TICKET-KEY]: [Summary] — [date]
- Service: [service-name]
- Root Cause: [one sentence]
- Branch: fix/[TICKET-KEY]-[description]
- PR: [link]
- Regression Test: TC-{SERVICE}-{TICKET-KEY}-REG-001
```

### Step 9: Update the Jira Ticket

1. **Add a comment to the Jira ticket** using `addCommentToJiraIssue`:
```
🤖 Bugfix Applied — [date]

Root Cause: [one sentence]
Fix: [one sentence]
Branch: fix/GS-456-entitlement-view-name
PR: [link]
Regression Test: TC-ORDER-GS456-REG-001

All tests passing. Ready for review.
```

2. **Transition the ticket** (after asking the human):
   - Use `getTransitionsForJiraIssue` to find available transitions
   - Suggest moving to "In Review" or "Code Review"
   - ASK: "Should I move [TICKET-KEY] to [status]?"

### Step 10: Summary

Present:
```
✅ Bugfix [TICKET-KEY] — Complete

Root Cause: [one sentence]
Fix Applied: [file:line — what changed]
Regression Test: TC-{SERVICE}-{TICKET-KEY}-REG-001
Branch: fix/GS-456-entitlement-view-name
PR: [link]
Jira Updated: Comment added, status → [new status]

Next Steps:
  - Review PR
  - Merge after approval
  - Verify in [environment] after deployment
```

## Important Rules

- **Surgical fixes only** — fix the bug, nothing else. No refactoring, no improvements, no cleanup. The `--team` flag is not supported for bugfixes; if the fix spans multiple services, escalate to `/project:feature`
- **Jira key in everything** — branch name, commit message, test case ID, PR title, report entries
- **Always write a regression test** — a bugfix without a regression test is incomplete
- **Diagnose before fixing** — present the root cause analysis and get confirmation before writing code
- **Always ask before Jira transitions** — never auto-transition without human confirmation
- **Check for cascading impact** — if the bug is in a shared service, check if the fix affects consumers
- **Fallback gracefully** — if Atlassian MCP is unavailable, accept manual input and continue
- **Preserve git history** — create a new branch, don't amend existing commits on shared branches
- **If the fix is larger than expected** — if diagnosis reveals the fix requires architectural changes or touches multiple services, STOP and suggest converting to a `/project:feature` workflow instead
