# Agentic Market Panic Simulator (AMPS)

A high-throughput, generative agent-based simulator modeling irrational panic, liquidity spirals, and behavioral contagion.

By coupling the bounded rationality of Large Language Models (LLMs) with a hyper-optimized Numba financial matching engine, AMPS bridges the gap between traditional quantitative finance (which struggles to model human irrationality) and generative AI (which struggles with scale and speed).

## Core Capabilities

* **Hardware-Bound Swarm Scaling:** Sustains a cognitive swarm of 400 active LLM agents simultaneously on a single 16GB consumer GPU (e.g., RTX 5070 Ti) without encountering Out-Of-Memory (OOM) block evictions.
* **1.58-Bit Ternary Precision:** Deploys the Qwen3.8-based **Bonsai 2 27B** model natively trained in 1.58-bit ternary precision (`BITCOS/PQ2_0`). The ~75% linear hybrid-attention architecture drastically reduces KV-cache memory footprints over long horizons.
* **Slot Prefix Caching:** Maximizes GPU VRAM efficiency by rendering the 2,000-token macro environment (order book state and news shocks) strictly once as a shared root node in the Radix tree, allowing all 400 agents to evaluate the exact same market snapshot instantly.
* **Frequent Batch Auction Engine:** Bypasses the Python Global Interpreter Lock (GIL) utilizing a Numba JIT-compiled matching engine. It operates a discrete Call Market at the tick boundary ($t \to t+1$), calculating uniform clearing prices and pro-rata volume allocations to completely eliminate latency arbitrage.
* **Zero-Overhead Constrained Decoding:** Enforces strict trading JSON schema adherence directly at the logit generation level via `llama-server` GBNF constrained decoding, eliminating retry latency.

## System Architecture

The simulation is decoupled into three distinct asynchronous layers to ensure generative bottlenecks do not block the financial tick clock:

1. **The Macro-Orchestrator (God Agent):**
    A 70B dense model quantized into GGUF and pinned entirely to the Host CPU RAM. It acts once per simulation episode to generate exogenous geopolitical and macroeconomic shocks.

2. **The Agent Cognitive Engine (llama-server):**
    The micro-agent swarm utilizing the Bonsai 2 27B model on the GPU. Agents ingest the shared state prefix, evaluate their individual risk personas (e.g., retail panic trader, institutional hedger), and emit structured trading decisions.

3. **Meso-Scale Aggregation & Routing (uvloop):**
    The central event bus drops standard Python `asyncio` in favor of Cython-based `uvloop`. It ingests the JSON payloads, batches them into discrete ticks, and routes them to the Numba JIT Frequent Batch Auction engine for clearing. Redis coordinates the tick-boundary state, while LanceDB archives the agents' semantic reasoning traces for post-simulation analysis.

## Lean MLOps Pipeline

AMPS strictly follows a lean, zero-server-overhead MLOps strategy designed for high-impact local execution:

* **Single-Command Containerization:** The entire stack (`llama-server`, FastAPI, Redis, Prometheus) orchestrates via a single `docker compose up` command.
* **Embedded MLflow Tracking:** Tracks generative model runs and parameter sweeps using a local-file MLflow backend (`backend_store_uri="./mlruns"`), removing the need for heavy Postgres or MinIO instances.
* **Local DVC Data Versioning:** Versions large market seed files, starting order book states, and prompt registries entirely on local disk storage (`/var/dvc_store`).
* **Hardware Telemetry:** Monitors critical generation SLAs (Time-To-First-Token, Inter-Token Latency) alongside financial metrics (Herding Index) via Prometheus and Grafana.

## Technology Stack

* **Environment Management:** `pixi` (Strict lockfiles, no `uv` or `pip`)
* **Core Event Loop:** Python 3.12 + `uvloop`
* **Serving Node:** `PrismML-Eng/llama.cpp` (`llama-server`)
* **High-Performance Compute:** Numba JIT
* **State Management:** Redis (Tick-Boundary Ledger) + LanceDB (Vector Semantic Memory)
* **Data Validation:** Pydantic V2 + GBNF
* **CI/CD:** Local self-hosted GitHub Actions + `act` for local rehearsal

## Getting Started

All interactions with the project environment must be executed via `pixi run` or `just` commands. Global Python or pip usage is strictly prohibited.

To explore available developer commands, run:

```bash
just --list
```
