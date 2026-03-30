# Contributing to Agent Architect

Thanks for your interest in contributing! This project is an open framework — contributions of all kinds are welcome.

## Ways to Contribute

### Use it and share feedback
The most valuable contribution right now is **using the framework on a real project** and reporting what works, what breaks, and what's missing. Open an issue with your experience.

### Improve the phase commands
The slash commands in `.claude/commands/` are the core of the framework. If you find a phase produces better results with different instructions, submit a PR.

### Add tech-stack templates
The `standards/` directory defaults to Java 21/Spring Boot. If your team uses a different stack, contribute a template pack (see [#7](https://github.com/your-org/agent-architect/issues/7)).

### Fix bugs
If an agent instruction is inconsistent, a file reference is wrong, or a phase prerequisite is missing — PRs welcome.

## Roadmap

These are the planned improvements, roughly prioritized. Pick one and contribute!

### High Priority

| Issue | Description | Status |
|-------|-------------|--------|
| [#1](https://github.com/your-org/agent-architect/issues/1) | **Distributed validation** — support validating across multiple developers' machines (remote URLs, docker images) | Open |
| [#2](https://github.com/your-org/agent-architect/issues/2) | **Dedicated test phase** — contract testing, e2e testing, performance baselines between Build and Validate | **Done** — TEST-PLAN.md (Phase 3), INTEGRATION-TEST-PLAN.md (Phase 4), TEST-REPORT.md (Phase 5) |
| [#5](https://github.com/your-org/agent-architect/issues/5) | **Incremental execution** — detect changes and only re-run affected specs/contracts | Open |
| [#8](https://github.com/your-org/agent-architect/issues/8) | **UI/Frontend standards** — component architecture, accessibility, performance budgets, UX patterns | Open |
| [#9](https://github.com/your-org/agent-architect/issues/9) | **Testing standards** — test pyramid, mocking strategy, contract testing, CI integration, coverage rules | **Done** — `standards/testing-standards.md` with edge case checklists, templates, quality gates |

### Medium Priority

| Issue | Description | Status |
|-------|-------------|--------|
| [#3](https://github.com/your-org/agent-architect/issues/3) | **Deployment phase** — generate CI/CD pipelines, IaC, K8s manifests | Open |
| [#4](https://github.com/your-org/agent-architect/issues/4) | **Monorepo support** — alternative layout with workspace-based tooling | Open |
| [#7](https://github.com/your-org/agent-architect/issues/7) | **Tech-stack templates** — pre-built standards for Spring Boot, FastAPI, Go, etc. | Open |
| [#10](https://github.com/your-org/agent-architect/issues/10) | **Agent team orchestration** — multi-agent team mode with specialized roles | **Done** — `/project:team-start` with 5-agent team |
| [#11](https://github.com/your-org/agent-architect/issues/11) | **Ticket-driven workflows** — Jira integration for features and bugfixes | **Done** — `/project:feature` + `/project:bugfix` with Atlassian MCP |

### Nice to Have

| Issue | Description | Status |
|-------|-------------|--------|
| [#6](https://github.com/your-org/agent-architect/issues/6) | **Web dashboard** — visual project status and dependency graph | Open |

## How to Submit a PR

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Make your changes
4. If you modified `.claude/commands/`, run `./scripts/sync-prompts.sh` to sync Copilot prompts
5. Commit with conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
6. Open a PR with a clear description of what and why

## Guidelines

- **Keep it markdown-only** — the framework's power is that it has zero runtime dependencies. Avoid adding npm packages, build steps, or custom tooling unless absolutely necessary.
- **Test with both tools** — if possible, verify your changes work with both Claude Code and GitHub Copilot.
- **Phase commands should be self-contained** — each `.claude/commands/project/*.md` file should work independently. An agent reading only that file + `manifest.yaml` + `standards/` should know exactly what to do.
- **Don't break the Ask & Remember pattern** — if an agent needs information, it should ask and persist the answer. Never require users to manually edit config files when the agent can do it.
