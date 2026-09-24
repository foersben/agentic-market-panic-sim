# Agentic Market Panic Simulator

Welcome to the documentation for the **Agentic Market Panic Simulator (AMPS)**.

This project implements a high-concurrency Limit Order Book (LOB) matching engine powered by generative LLM agents, leveraging an Entity-Component-System (ECS) architecture, Cython/uvloop event buses, and Numba-JIT acceleration.

## Project Plan

The comprehensive academic and technical architecture for this simulator is documented in our MLOps Project Plan:

* [View the MLOps Project Plan (PDF)](latex/mlops_project_plan/project_proposal.pdf)

*(Note: Ensure you have built the LaTeX document in `docs/latex/mlops_project_plan` to generate the PDF).*

## Simulation Scenarios

* [The Flash Crash Benchmark](scenarios/flash_crash_benchmark.md)

## System Architecture

### Infrastructure Layer
* [Server Infrastructure & NAT Traversal](architecture/infrastructure/server_setup.md)

### Cognitive Engine Layer
* [Semantic RAG Caching Pipeline](architecture/cognitive_engine/semantic_caching.md)
* [Reinforcement Learning Distillation](architecture/cognitive_engine/reinforcement_learning.md)

### Simulation Engine Layer
* [Semantic Intent Architecture](architecture/simulation_engine/semantic_intent_translation.md)

## MLOps & Operations

* [MLOps Execution Plan (Phase 1)](mlops/phase_1_execution.md)
