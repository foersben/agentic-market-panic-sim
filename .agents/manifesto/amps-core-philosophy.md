---
type: Manifesto
title: AMPS Core Philosophy
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 0.1
description: AMPS (Agentic Market Panic Simulator) is
  developed in collaboration with the University of Jena. It is engineered to
  model comple...
tags: [amps, ecs, numba, performance]
generated: {by: process:okf-updater, at: "2026-07-21T16:01:38Z"}
verified: {by: process:okf-updater, at: "2026-08-14T16:00:00Z"}
---

AMPS (Agentic Market Panic Simulator) is developed in collaboration with the University of Jena. It is engineered to model complex macroeconomic dynamics and market panics within a highly deterministic environment.

1. **Science Over Shortcuts:** Mathematical correctness and deterministic replayability are non-negotiable. Do not sacrifice scientific accuracy for the sake of shipping a feature faster.
2. **Performance by Design:** Agentic market simulations scale exponentially. We rely on strict ECS data structures, double-buffering, and Numba JIT compilation to maintain high tick rates without degrading simulation fidelity.
3. **Transparency via Telemetry:** The engine's internal state must always be observable and serializable via our Zarr replay buffers. If an event alters the Market Environment, it must be captured by the telemetry pipeline.
