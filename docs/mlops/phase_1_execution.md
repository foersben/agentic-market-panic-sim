---
type: Concept
title: MLOps Execution Plan
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 1.0
description: Validated setup for Phase 1 of the MLOps deployment pipeline based on the LaTeX project proposal.
tags: [mlops, deployment, infrastructure, cicd]
generated: {by: process:okf-updater, at: "2026-09-24T21:15:00Z"}
sources: []
---

# MLOps Execution Plan

This document outlines the exact, hardware-validated deployment steps for Phase 1 of the AMPS project, translating the MLOps Project Proposal into actionable infrastructure configurations for the edge environment (i7-14700K, 128GB RAM, 16GB RTX 5070 Ti).

## 1. Base OS & Driver Layer

The foundation relies on a bare-metal installation to maximize P-Core CPU cycles for the Numba JIT loops by eliminating virtualization overhead.

* **OS:** Ubuntu 24.04 LTS (Bare-Metal).
* **The `nouveau` Trap:** Ubuntu ships with open-source `nouveau` drivers that conflict aggressively with CUDA. These must be blacklisted via `/etc/modprobe.d/` before installing the NVIDIA 550+ driver to prevent fatal kernel panics.
* **Docker Passthrough:** The `nvidia-container-toolkit` is installed to enable the `--gpus all` / `cdi` flag in Docker Compose, allowing the `llama-server` container to map directly to the RTX 5070 Ti.

## 2. Networking Topology: Tailscale Authentication

While manual reverse SSH tunnels are a valid zero-ingress strategy, **Tailscale** is the chosen production solution for the edge node.

* **Why Tailscale:** It uses WireGuard to seamlessly punch through the ISP's Double NAT and Carrier-Grade NAT (CGNAT) without requiring manual public cloud bastions or keep-alive cron jobs. The daemon's memory overhead is negligible on a 128GB system and does not touch the critical GPU VRAM.
* **CI/CD Integration:** GitHub Actions utilizes a Tailscale Ephemeral Auth Key to connect to the private Tailnet, deploy the application, and disconnect, functioning as an un-bypassable admin wall without exposing a public IP.

## 3. LLM Inference & VRAM Allocation

The cognitive engine relies on `llama-server` running the Bonsai 2 27B (1.58-bit ternary) model, completely constrained within the 16GB VRAM boundary.

* **VRAM Configuration:** The startup flag is strictly locked to `--mem-fraction-static 0.90`.
* **Mathematical Validation:** 90% of 16GB allocates exactly 14.4GB to the `llama-server` process. The model weights consume roughly 7.5GB, leaving 6.9GB exclusively for the Radix KV-Cache. This accommodates the target of $\sim$400 concurrent agents.
* **Safety Margin:** The remaining 10% (1.6GB) remains free for the host OS, CUDA context instantiation, and the GBNF/JSON Finite-State Machine masks. Exceeding a 0.90 fraction risks dynamic allocation failures and fatal Out-Of-Memory (OOM) crashes during tick cascades.

## 4. Development Velocity (The Proxy Model Strategy)

During Phase 1, the event bus, the Numba Limit Order Book, and asynchronous batching logic are heavily tested.

* **The Bottleneck:** The full 70B God Agent executes on the CPU/RAM, requiring 3-4 minutes to process a 500-token macro shock. Waiting 4 minutes per tick during active development destroys velocity.
* **The Solution:** A lightweight proxy model (e.g., Llama-3.1-8B) replaces the 70B model during the debugging loop, reducing prefill latency to seconds. The 70B model is swapped back into production strictly via environment variables for final benchmarks.

## 5. Dependency Management

The execution environment avoids the fragility of standard Python package managers.

* **`pixi`:** Used to lock Python, C++, and Rust binaries. This guarantees the Numba JIT compilers and Cython `uvloop` bindings compile identically on local development machines and the production server.
* **`docker compose`:** The entire infrastructure (Redis, LanceDB, Prometheus, Grafana, and `llama-server`) launches with a single command, matching the lean execution strategy required for the 160-hour project budget.
