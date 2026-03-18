# Contributing to Agent Architect

Thanks for your interest in contributing! This project is an open framework — contributions of all kinds are welcome.

## Ways to Contribute

### Use it and share feedback
The most valuable contribution right now is **using the framework on a real project** and reporting what works, what breaks, and what's missing. Open an issue with your experience.

### Improve the phase commands
The slash commands in `.claude/commands/` are the core of the framework. If you find a phase produces better results with different instructions, submit a PR.

### Add tech-stack templates
The `standards/` directory defaults to NestJS/TypeScript. If your team uses a different stack, contribute a template pack (see [#7](https://github.com/nakurian/agent-architect/issues/7)).

### Fix bugs
If an agent instruction is inconsistent, a file reference is wrong, or a phase prerequisite is missing — PRs welcome.

## Roadmap

These are the planned improvements, roughly prioritized. Pick one and contribute!

### High Priority

| Issue | Description |
|-------|-------------|
| [#1](https://github.com/nakurian/agent-architect/issues/1) | **Distributed validation** — support validating across multiple developers' machines (remote URLs, docker images) |
| [#2](https://github.com/nakurian/agent-architect/issues/2) | **Dedicated test phase** — contract testing, e2e testing, performance baselines between Build and Validate |
| [#5](https://github.com/nakurian/agent-architect/issues/5) | **Incremental execution** — detect changes and only re-run affected specs/contracts |

### Medium Priority

| Issue | Description |
|-------|-------------|
| [#3](https://github.com/nakurian/agent-architect/issues/3) | **Deployment phase** — generate CI/CD pipelines, IaC, K8s manifests |
| [#4](https://github.com/nakurian/agent-architect/issues/4) | **Monorepo support** — alternative layout with workspace-based tooling |
| [#7](https://github.com/nakurian/agent-architect/issues/7) | **Tech-stack templates** — pre-built standards for Spring Boot, FastAPI, Go, etc. |

### Nice to Have

| Issue | Description |
|-------|-------------|
| [#6](https://github.com/nakurian/agent-architect/issues/6) | **Web dashboard** — visual project status and dependency graph |

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
- **Phase commands should be self-contained** — each `.claude/commands/*.md` file should work independently. An agent reading only that file + `manifest.yaml` + `standards/` should know exactly what to do.
- **Don't break the Ask & Remember pattern** — if an agent needs information, it should ask and persist the answer. Never require users to manually edit config files when the agent can do it.
