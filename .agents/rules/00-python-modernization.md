---
type: Agent Rule
title: Mandates
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 0.1
description: "- **Execution:** Ban `pip`, `poetry`, `python`. Execute ALL commands
  via `pixi run` or `just`."
tags: [python]
generated: {by: process:okf-updater, at: "2026-07-21T16:01:38Z"}
verified: {by: process:okf-updater, at: "2026-08-14T16:00:00Z"}
trigger: always_on
rule_id: python-modernization
severity: critical
---

## Mandates

- **Execution:** Ban `pip`, `poetry`, `python`. Execute ALL commands via `pixi run` or `just`.
- **Types & Docs:** Enforce strict `mypy`. Type all function signatures, generics, and variable assignments explicitly. Every class, public endpoint, and workflow component MUST have comprehensive Google-style docstrings (for `mkdocstrings` extraction).
- **Linting:** Validate all code via `pixi run ruff check` and `pixi run ruff format`. Ban `flake8`, `black`, `isort`.
- **Vertical Slices & MLOps:** When designing a feature or pipeline inside `app/pipelines/`, all code (logic, data transformation, router registration) must remain isolated in that folder.
