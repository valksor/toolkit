---
name: stack-context
description: >-
  Auto-detects project tech stack and injects actionable coding conventions.
  Triggered automatically on session start or manually via skill invocation.
  Covers Go, Python, React, and TypeScript stacks.
---

# Stack Context

Detects the project's tech stack and provides stack-specific coding conventions. Two modes:

- **Automatic:** The session-start hook detects marker files and injects relevant sections below
- **Manual:** When invoked as a skill, scan the project and read 2-3 source files per stack to detect actual conventions before applying guidance

## Manual Invocation

When invoked manually, do the following before applying guidance:

1. Check for marker files (`go.mod`, `package.json`, `pyproject.toml`, `tsconfig.json`, `Makefile`, `Dockerfile`)
2. For each detected stack, read 2-3 source files to observe actual conventions (error handling style, naming patterns, test framework, state management)
3. Present the detected stack and any convention adjustments to the user
4. Apply only the relevant sections below, adjusted for what was observed

---

## Guidance Blocks

<!-- begin:go -->
### Go Conventions

- **Error handling:** Wrap errors with context: `fmt.Errorf("operation: %w", err)`. Never discard errors with `_`. Check errors immediately after the call.
- **Naming:** Use MixedCaps (not underscores). Receiver names are 1-2 characters (`s` not `self` or `this`). Exported names start with uppercase.
- **Interfaces:** Accept interfaces, return concrete types. Keep interfaces small (1-3 methods). Define interfaces where they are used, not where they are implemented.
- **Concurrency:** Use channels for communication between goroutines. Use `sync.WaitGroup` for fan-out/fan-in. Always respect `context.Context` for cancellation. Protect shared state with `sync.Mutex` — prefer it over channels for simple state protection.
- **Testing:** Table-driven tests are the default pattern. Test file lives next to the source file (`foo_test.go`). Use `t.Helper()` in test helpers. Use `t.Parallel()` where safe.
- **Project structure:** Follow standard Go project layout. `internal/` for private packages. `cmd/` for entry points.
<!-- end:go -->

<!-- begin:python -->
### Python Conventions

- **Type hints:** Add type annotations to all function signatures (parameters and return types). Use `from __future__ import annotations` for forward references.
- **Error handling:** Catch specific exception types, never bare `except:` or `except Exception:` without re-raising. Use custom exception classes for domain errors.
- **Modern idioms:** Use `pathlib.Path` over `os.path`. Use f-strings over `.format()` or `%`. Use `dataclasses` or `pydantic` for data containers. Use `|` union syntax for type hints (3.10+).
- **Testing:** pytest is the default framework. Use fixtures over setup/teardown. Use `parametrize` for data-driven tests. Test file naming: `test_module.py`.
- **Async:** If async code is present, use `asyncio` patterns consistently. Use `async with` and `async for`. Don't mix sync and async I/O.
- **Dependencies:** Prefer `pyproject.toml` for project metadata. Pin dependencies. Use virtual environments.
<!-- end:python -->

<!-- begin:react -->
### React Conventions

- **Components:** Functional components only. Use hooks for state (`useState`), effects (`useEffect`), and context. No class components.
- **Props:** Define props as TypeScript interfaces, exported alongside the component. Destructure props in function signature.
- **State management:** Use the project's established pattern (Redux, Zustand, Context, or local state). Don't introduce a new state management approach without discussion.
- **Effects:** Include all dependencies in `useEffect` dependency arrays. Extract complex effects into custom hooks. Clean up subscriptions and timers in effect cleanup.
- **Memoization:** Use `useMemo` and `useCallback` only when there is a measurable performance need, not by default. Prefer restructuring to avoid unnecessary renders.
- **Testing:** Match the project's test framework (Jest, Vitest). Use Testing Library (`@testing-library/react`) for component tests. Test behavior, not implementation details.
<!-- end:react -->

<!-- begin:typescript -->
### TypeScript Conventions

- **Strictness:** Respect the project's `tsconfig.json` strict mode settings. Never weaken type checking.
- **Types over `any`:** Use `unknown` instead of `any` for truly unknown types. Use proper generics. Use discriminated unions for variant types.
- **Interfaces vs types:** Follow the project's existing convention. If no convention, prefer `interface` for object shapes and `type` for unions/intersections.
- **Null handling:** Use optional chaining (`?.`) and nullish coalescing (`??`). Avoid non-null assertions (`!`) unless the invariant is documented.
- **Enums:** Prefer `as const` objects or union types over `enum`. Use string literal unions for simple cases.
<!-- end:typescript -->

<!-- begin:makefile -->
### Makefile Conventions

- **Prefer make:** If the project has a `Makefile`, run `make <target>` instead of calling tools directly. Check available targets with `make help` or by reading the Makefile.
- **Common targets:** `make build`, `make test`, `make lint`, `make clean`, `make dev`, `make docker`.
<!-- end:makefile -->

<!-- begin:docker -->
### Docker Conventions

- **Compose:** If `docker-compose.yml` exists, prefer `docker compose up` for local development.
- **Builds:** Use multi-stage builds. Don't copy unnecessary files (respect `.dockerignore`).
<!-- end:docker -->

---

## Sub-Detection Notes

The session-start hook appends additional notes based on detected tooling:

- **Go + testify:** "This project uses testify — use `assert` and `require` packages for test assertions."
- **Python + pytest:** "This project uses pytest — use fixtures, parametrize, and pytest idioms."
- **React + Redux:** "This project uses Redux — follow existing slice/action patterns."
- **React + Zustand:** "This project uses Zustand — follow existing store patterns."
- **React + Jest:** "Tests use Jest — use `describe`/`it`/`expect` patterns."
- **React + Vitest:** "Tests use Vitest — use `describe`/`it`/`expect` patterns."
- **React + Testing Library:** "Component tests use Testing Library — test user behavior, not implementation."
