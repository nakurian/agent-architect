# Phase 5: Build Service

You are the **Builder Agent**. Your job is to implement a single service based on its specification.

## Usage

This command is run PER SERVICE. The service name is passed as `$ARGUMENTS`:
```
/project:5-build order-service
```

Parse `$ARGUMENTS` to get the target service name. If `$ARGUMENTS` is empty, read `manifest.yaml` → `build_targets` to determine which services to build. If `build_targets` is also empty, list all non-skip services and ask the human which to build.

## Prerequisites
- `phases/3-specify.md` must exist (specs generated)
- `phases/4-contract.md` should exist (contracts validated) — if it doesn't, warn but proceed if the service has no cross-service dependencies
- Human must have approved specs. Check `approvals.spec_review` in manifest:
  - If `approvals.spec_review` exists → proceed
  - If not → ASK: "Specs need approval before building. Has someone reviewed the specs in services/*/specs/SPEC.md? If yes, who approved?" Then record it in `manifest.yaml` under `approvals.spec_review` with name and date
- The target service must have `services/<name>/specs/SPEC.md`

## Instructions

### Step 1: Load Context (Focused — Only What This Service Needs)

Read ONLY these files:
1. `manifest.yaml` — tech stack and this service's config
2. `standards/coding-standards.md` — coding rules to follow
3. `standards/api-design.md` — API conventions
4. `standards/testing-standards.md` — testing conventions and edge case checklists
5. `services/$SERVICE_NAME/specs/SPEC.md` — THE implementation blueprint
6. `services/$SERVICE_NAME/specs/TEST-PLAN.md` — test cases to implement (if exists)
7. Relevant contracts from `contracts/`:
   - API contracts where this service is provider OR consumer
   - Event contracts this service publishes or subscribes to
   - Shared models this service uses

Do NOT read other services' specs — you don't need them. The contracts are your interface.

### Step 2: Determine Build Directory

Check for the service's `local_path` in this order:
1. `manifest.local.yaml` (machine-specific, gitignored) — check this first
2. `manifest.yaml` (shared, committed)

**If `local_path` is set in either file** → use that directory. Verify it exists.

**If `local_path` is empty in both** → ASK the human:

```
I'm ready to build [service-name]. Where should the code live?

Options:
1. Enter an absolute path (e.g., /Users/you/projects/order-service)
2. Enter a relative path from this planning repo (e.g., ../order-service)
3. If this is an existing repo, I can clone from: [repo URL if set]

Path:
```

Once the human provides the path:
1. Save it to `manifest.local.yaml` (create the file if it doesn't exist) — this keeps machine-specific paths out of version control
2. If the path doesn't exist, create it
3. NEVER write service code inside this planning repo

### Step 2.5: Branch Hygiene (BEFORE writing any code)
1. `cd` to the service's local_path
2. `git fetch origin`
3. Determine the base branch (usually `develop` or `main`): `git remote show origin | grep 'HEAD branch'`
4. Create feature branch from latest: `git checkout -b feat/{ticket}-{feature} origin/{base-branch}`
5. Verify clean state: `git status` must show nothing
6. ALL work happens on this feature branch — never commit directly to develop/main

### Step 2.7: Analyze Config Repos and Existing Patterns
Before building:
1. If `manifest.yaml` lists a config repo for this service, read it to understand:
   - Environment URLs, secrets, and deployment patterns
   - K8s manifests (RBAC, volumes, probes, lifecycle hooks)
2. Check sibling service repos/configs for infrastructure patterns:
   - If introducing caching → how do other services configure it in K8s? (RBAC, discovery, config files)
   - If calling HTTPS endpoints → is there a `ca_trust` pattern? (trust configmap, deployment lifecycle hook)
   - If using a shared library → what version and modules do other services use?
3. Read the target codebase's existing patterns BEFORE writing new code:
   - How are WebClients configured? How are DTOs structured? How are tests organized?
   - Use proper imports — never use fully-qualified inline class names
   - **If Serena MCP (`plugin:serena:serena`) is available**: Use `get_symbols_overview` to map the codebase structure, `find_symbol` to read specific methods, and `find_referencing_symbols` to trace dependencies. This is 5-10x more context-efficient than reading entire files.
   - **If Serena is unavailable**: Use Grep for targeted pattern searches and Read with offset/limit for specific sections. Never read a 500-line file when you only need one 30-line method.

### Step 3: Scaffold the Project

If the service is `new`:
1. Navigate to the `local_path` directory
2. Create the project structure per `standards/coding-standards.md`
3. Initialize package.json / build config
4. Initialize a git repo (`git init`)
5. If the service has a `repo` URL in manifest, add it as remote (`git remote add origin <repo>`)
6. Set up the base framework (NestJS module, Express app, etc.)
7. Configure the database connection (skip if service has `database: null` in manifest)
8. Set up the health check endpoint
9. Create the Dockerfile
10. Create docker-compose.yml for local development (service + its database if applicable)
11. Verify the service starts and health check responds

If the service is `existing` or `enrich`:
1. If `local_path` exists and has code → use it directly
2. If `local_path` is empty and `repo` is set → ask the human where to clone, then `git clone <repo> <local_path>`
3. If `local_path` exists but is empty → clone into it from `repo`
4. Understand the existing code structure
5. Only add/modify what the SPEC.md describes

### Step 4: Implement Following the Spec's Sequence

Follow the **Implementation Sequence** from the SPEC.md exactly. For each step:

1. **Write the code** — follow standards strictly
2. **Write tests alongside** — not after. Test file goes in `__tests__/` next to the source
   - If TEST-PLAN.md exists, implement the test cases mapped to the current implementation step
   - Each test file MUST include a traceability comment: `// Covers: TC-SVC-ACC-001, TC-SVC-EDGE-003`
   - Prioritize: ALL P0 test cases must be implemented, 95%+ of P1 cases should be
3. **Run tests** — ensure they pass before moving to the next step
4. **Commit** — one commit per implementation step with a descriptive message

### Step 5: Implement Cross-Service Integration

When implementing calls to other services:
1. Generate types/interfaces from the contract YAML/JSON files
2. Implement the HTTP client with:
   - Circuit breaker
   - Retry with exponential backoff
   - Timeout configuration
   - Error mapping (external errors → domain errors)
3. Write integration tests using the contract for mock responses

When implementing event publishing:
1. Use the event contract JSON schema to validate outgoing events
2. Include eventId, timestamp, version, source in every event
3. Write tests that verify event payload matches contract schema

When implementing event consumption:
1. Validate incoming events against the contract schema
2. Implement idempotency (check if event was already processed)
3. Implement dead letter queue handling for failed events
4. Write tests for: happy path, duplicate event, malformed event, handler failure

### Step 6: Quality Checks

Before marking complete:
- [ ] All tests pass
- [ ] Test coverage meets minimum from `manifest.yaml` quality_gates (`test_coverage_minimum`)
- [ ] Test case coverage meets minimum from `manifest.yaml` quality_gates (`test_case_coverage_minimum`) — check P0+P1 cases from TEST-PLAN.md
- [ ] Contract tests exist for every API/event contract this service participates in (if `contract_test_required` gate is enabled)
- [ ] Linting passes (ESLint/Prettier or equivalent)
- [ ] No hardcoded secrets or credentials
- [ ] Health check endpoint works
- [ ] OpenAPI/Swagger docs generated (if API service)
- [ ] Dockerfile builds successfully
- [ ] Environment variables documented in .env.example
- [ ] README.md with setup and run instructions

### Step 7: Output Build Report and Test Report

Create `services/$SERVICE_NAME/specs/BUILD-REPORT.md`:

```markdown
# Build Report: [service-name]

## Status: complete | partial

## What Was Built
- [list of implemented features]

## Test Summary
- Unit tests: [N] passing
- Integration tests: [N] passing
- Coverage: [N]%

## Implementation Notes
- [anything the reviewer should know]
- [deviations from spec with justification]

## Known Gaps
- [anything not implemented with reason]

## How to Run
\`\`\`bash
[commands to start the service locally]
\`\`\`

## How to Test
\`\`\`bash
[commands to run the test suite]
\`\`\`
```

Also create `services/$SERVICE_NAME/specs/TEST-REPORT.md` following the template in `standards/testing-standards.md`:
- Map every implemented test back to its TEST-PLAN.md test case ID
- Report coverage percentages (line, branch, function)
- Report test case coverage (P0 implemented: N/M, P1 implemented: N/M)
- List any test cases deferred with reason
- List any unplanned tests added during implementation (bugs discovered, etc.)

### Step N: Local Verification (MANDATORY)
After building, verify the code works against real services:
1. Start the service locally (with appropriate env vars for TST)
2. Make real API calls to verify data flows end-to-end
3. Check logs for: proper INFO/ERROR levels, no hidden errors, correct correlation IDs
4. If any deserialization fails or data is wrong → fix code AND note in BUILD-REPORT.md
5. For UI services:
   - Start UI + BFF locally
   - Use Playwright to test key user journeys
   - Screenshot key screens and compare with Figma designs

### Step N+1: Code Review (MANDATORY — before PR)
1. Run code review on all changed files (use pr-review-toolkit:code-reviewer if available)
2. Check for: silent failures, missing error handling, incorrect serialization, blocking calls
3. Fix ALL critical and important findings
4. Re-run build + tests after fixes

### Step N+2: Documentation
1. If README.md doesn't have a "Local Development" section → add one with: env vars, setup scripts, how to run
2. If CLAUDE.md doesn't exist in the service repo → recommend creating one
3. Document any new infrastructure requirements (cache config, RBAC, trust certs)

### Step N+3: Single Commit and PR
1. `git add -A`
2. Squash all work into a single commit with descriptive message referencing the ticket
3. Push feature branch: `git push -u origin feat/{ticket}-{feature}`
4. Create PR via `gh pr create` with summary, changes list, and test plan

## Important Rules
- Follow the SPEC.md religiously — if something is ambiguous, check the contracts
- Do NOT add features not in the spec — no gold-plating
- Do NOT skip tests — every endpoint and business rule must have tests
- Commit frequently with meaningful messages
- If you discover a spec gap, document it in BUILD-REPORT.md but make a reasonable decision and continue
- If the spec says "implement X" but doesn't specify how, follow the standards and use the simplest approach
- The service must start and respond to health checks when you're done
