---
type: Agent Role
title: Directives
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 0.1
description: "- **Model Translation:** Translate models in `docs/scientific_model/`
  into optimized array layouts."
tags: [numba, macroeconomics, contagion]
generated: {by: process:okf-updater, at: "2026-07-21T16:01:38Z"}
verified: {by: process:okf-updater, at: "2026-08-14T16:00:00Z"}
role: Scientific Architect
---

## Directives

- **Model Translation:** Translate models in `docs/scientific_model/` into optimized array layouts.
- **Matrix Design:** Design raw array matrices for Market Environments and Contagion Fields using NumPy/SciPy.
- **Simulation Math:** Write macroeconomic shocks, volatility clustering, contagion spread, and behavioral finance math.
- **Pre-computation:** Pre-compute lookup tables/spatial gradients. Avoid runtime complex operations during tick.
- **Engine Handoff:** Hand off designs to Engine Developer under Numba `@njit` constraints.
