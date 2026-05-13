# ADR-001: GraphQL Server - Pothos + Yoga

Status: Accepted

Date: 2026-05-11

## Context

Dahdit needs a GraphQL API over Postgres, but most writes are not generic CRUD. Lesson completion needs grading, anti-cheat validation, XP, hearts, streaks, unlocks, and SRS scheduling in one transaction.

## Decision

Use a Bun service with Hono, GraphQL Yoga, Pothos, Drizzle, and pure domain modules. Do not use Hasura for MVP.

## Consequences

- Business logic is ordinary TypeScript and can be tested without GraphQL.
- The API deploys as one process.
- Drizzle remains the database source of truth.
- Authorization is resolver-level code using Pothos scope auth instead of metadata YAML.

