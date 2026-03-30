# Project Status Dashboard

Show the current state of the project across all phases and services.

## Instructions

### Step 1: Read State
1. `manifest.yaml` — project info and services
2. `manifest.local.yaml` — check if local paths are configured
3. Check which phase files exist in `phases/` (including `0-setup.md`)
4. Check which services have specs in `services/*/specs/SPEC.md`
5. Check which services have build reports in `services/*/specs/BUILD-REPORT.md`

### Step 2: Display Dashboard

```
╔══════════════════════════════════════════════════════════╗
║                   PROJECT STATUS                         ║
╠══════════════════════════════════════════════════════════╣
║ Project: [name]                                          ║
║ Services: [N total] | [N new] | [N enrich] | [N skip]   ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  PHASES                                                  ║
║  ─────                                                   ║
║  [✓] 0. Setup          — completed [date]                ║
║  [✓] 1. Discovery      — completed [date]                ║
║  [✓] 2. Architecture   — completed [date]                ║
║  [▸] 3. Specification  — in progress (3/5 services)     ║
║  [ ] 4. Contracts                                        ║
║  [ ] 5. Build                                            ║
║  [ ] 6. Validation                                       ║
║  [ ] 7. Review                                           ║
║                                                          ║
║  SERVICES                                                ║
║  ────────                                                ║
║  Service            Type     Status    Spec    Built     ║
║  ─────────────────  ───────  ────────  ──────  ──────   ║
║  web-ui             ui       new       [ ]     [ ]       ║
║  bff-gateway        bff      new       [✓]     [ ]       ║
║  order-service      domain   new       [✓]     [▸]       ║
║  payment-service    domain   existing  [—]     [—]       ║
║                                                          ║
║  BUILD TARGETS: [list or "all"]                          ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
```

### Step 3: Recommendations
Based on the current state, suggest:
- What phase to run next
- Any blocking issues (e.g., unanswered questions from discovery)
- Which services are ready to build
