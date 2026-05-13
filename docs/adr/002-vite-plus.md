# ADR-002: Frontend Toolchain - Vite+

Status: Accepted with weekly review

Date: 2026-05-11

## Context

The web companion needs dev, test, lint, format, and build entrypoints. Vite+ offers a single CLI over that toolchain, but it is alpha software.

## Decision

Use Vite+ for the web workspace and keep Taskfile as the orchestration layer.

## Consequences

- Web commands stay short: `vp dev`, `vp check`, `vp test`, `vp build`.
- Backend and iOS do not depend on Vite+.
- If Vite+ breaks, Taskfile commands can be swapped to direct Vite, Vitest, oxlint, and oxfmt calls.

