# Team Status Dashboard

You are the **Status Agent**. Display the current project status with team orchestration context.

## Instructions

### Step 1: Read Project State

1. Read `manifest.yaml` — project info, services, framework section, quality gates, approvals
2. Read `manifest.local.yaml` if it exists — local path overrides
3. Scan `phases/` directory — which phases are complete
4. Scan `services/*/specs/` — which services have SPEC.md, TEST-PLAN.md, BUILD-REPORT.md, TEST-REPORT.md
5. Scan `contracts/` — CONTRACT-MATRIX.md, INTEGRATION-TEST-PLAN.md existence
6. Check `context/decisions/` — ADR count

### Step 2: Determine Framework Mode

Read `manifest.yaml` → `framework`:
- If `framework` section is missing → mode is "sequential (v1)"
- If `framework.mode` is "sequential" → "sequential (v2 — teams available)"
- If `framework.mode` is "teams" → "teams active"

### Step 3: Display Dashboard

```
╔══════════════════════════════════════════════════════════════╗
║  PROJECT: [project.name]                                     ║
║  Domain: [business_domain]   Team: [team]                    ║
║  Framework: v[version] — Mode: [mode]                        ║
╠══════════════════════════════════════════════════════════════╣
║  PHASE PROGRESS                                              ║
║  ─────────────────────────────────────────────────           ║
║  [✓] Phase 0: Setup                                         ║
║  [✓] Phase 1: Discovery                                     ║
║  [▸] Phase 2: Architecture  ← current                       ║
║  [ ] Phase 3: Specification                                  ║
║  [ ] Phase 4: Contracts                                      ║
║  [ ] Phase 5: Build                                          ║
║  [ ] Phase 6: Validation                                     ║
║  [ ] Phase 7: Review                                         ║
╠══════════════════════════════════════════════════════════════╣
║  SERVICES                                                     ║
║  ─────────────────────────────────────────────────           ║
║  Service            Type     Status    Spec  Tests  Built    ║
║  ─────────────────  ───────  ────────  ────  ─────  ─────   ║
║  web-ui             ui       new       [ ]   [ ]    [ ]      ║
║  bff-gateway        bff      new       [ ]   [ ]    [ ]      ║
║  order-service      domain   new       [ ]   [ ]    [ ]      ║
║  payment-service    domain   existing  [✓]   [ ]    [✓]      ║
╠══════════════════════════════════════════════════════════════╣
║  TEST COVERAGE                                                ║
║  ─────────────────────────────────────────────────           ║
║  Service            TEST-PLAN  TEST-REPORT  Coverage  Cases  ║
║  ─────────────────  ─────────  ───────────  ────────  ───── ║
║  order-service      [✓] 42tc   [✓]          87%      38/42  ║
║  bff-gateway        [✓] 28tc   [ ]          —        —      ║
╠══════════════════════════════════════════════════════════════╣
║  QUALITY GATES                                                ║
║  ─────────────────────────────────────────────────           ║
║  spec_review:           [pending]                             ║
║  contract_review:       [pending]                             ║
║  test_plan_review:      [pending]                             ║
║  test_coverage (80%):   [order: 87% ✓]                       ║
║  test_cases (95%):      [order: 90% ✗]                       ║
╠══════════════════════════════════════════════════════════════╣
║  ARTIFACTS                                                    ║
║  ─────────────────────────────────────────────────           ║
║  ADRs: [N] in context/decisions/                              ║
║  Contracts: [N] API, [N] events, [N] shared models           ║
║  Integration Test Plan: [exists/missing]                      ║
╠══════════════════════════════════════════════════════════════╣
║  RECOMMENDATIONS                                              ║
║  ─────────────────────────────────────────────────           ║
║  → Run /project:2-architect to continue                      ║
║  → Or /project:team-start to activate team orchestration     ║
╚══════════════════════════════════════════════════════════════╝
```

### Step 4: Smart Recommendations

Based on current state, recommend the next action:

- If no phases complete → "Run /project:0-setup to start"
- If setup done but no discovery → "Run /project:1-discover"
- If specs exist but no test plans → "Re-run /project:3-specify to generate TEST-PLAN.md files"
- If test plans exist but not approved → "Review TEST-PLAN.md files and record approval"
- If contracts exist but no integration test plan → "Re-run /project:4-contract to generate INTEGRATION-TEST-PLAN.md"
- If all phases done but critical issues in review → "Fix critical issues and run /project:rebuild-service"
- If framework mode is sequential and project is complex (4+ services) → "Consider /project:team-start for parallel builds"

## Important Rules
- This command is READ-ONLY — never modify any files
- Show actual counts and percentages where possible (read TEST-REPORT.md for numbers)
- If a file doesn't exist, show it as missing rather than guessing
- Adapt the dashboard sections to what actually exists (skip Test Coverage section if no TEST-PLAN.md files exist yet)
