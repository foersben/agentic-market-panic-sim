---
type: Concept
title: Semantic Intent Architecture
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 1.0
description: The deterministic translation of qualitative LLM intent into exact mathematical ECS actions.
tags: [architecture, data-flow, simulation, ecs]
generated: {by: process:okf-updater, at: "2026-09-24T20:40:00Z"}
sources: []
---

# Semantic Intent Architecture

To prevent generative models from hallucinating impossible arithmetic (such as hallucinating absolute dollar sizes or bypassing margin requirements), AMPS strictly isolates qualitative intent from quantitative execution. 

Transformers are utilized purely for their cognitive reasoning capabilities, while the Entity-Component-System (ECS) engine handles all deterministic scaling and constraint resolution.

## 1. The Separation of Concerns

The decision cycle operates strictly across two distinct computational boundaries:

* **The Generative Phase:** The LLM receives the macroeconomic state and outputs a constrained JSON schema. Crucially, this schema uses only relative weightings and directional intents.
* **The Deterministic Phase:** The Numba JIT-compiled clearing engine multiplies these relative intents against the agent's absolute inventory arrays, calculating the exact integer share counts and dollar limits, and enforcing financial conservation laws.

## 2. Asynchronous Rejection (T+1 Feedback)

Because synchronous tool calling (ReAct loops) introduces unacceptable latency at the scale of 400+ agents per tick, AMPS uses delayed deterministic feedback.

If the ECS engine calculates that a semantic intent is mathematically impossible (e.g., the agent wants to liquidate 100% of a position it does not own), the engine silently drops the order array. In the subsequent simulation tick (T+1), the agent receives a strict system prompt containing the mathematical rejection reason, forcing it to cognitively pivot its strategy without blocking the active tick execution.

## Data-Flow Matrix Specifications

The following table documents the strict causal flow mapping qualitative JSON schema fields to quantitative ECS Component Arrays. 

| LLM Output Field | Data Type | ECS Array Target | Deterministic Transformation Rule |
| :---- | :--- | :--- | :--- |
| `action` | String (`BUY`, `SELL`) | `order_direction[agent_id]` | Enum mapped to +1 or -1 scalar mask. |
| `size_percentage` | Float (`0.0` to `1.0`) | `order_quantity[agent_id]` | `floor(inventory[agent_id, ticker] * size_percentage)` |
| `pricing_aggressiveness` | String (`MAKER`, `TAKER`) | `limit_price[agent_id]` | Derived from LOB best bid/ask with tick slippage factor. |
| `rationale` | String | *Telemetry (Zarr)* | Bypasses engine; logged directly to simulation trace buffer. |
