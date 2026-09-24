---
type: Concept
title: MLOps Execution Plan (Phase 1)
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 2.1
description: Architectural overview of the physical server provisioning for Phase 1 of the MLOps deployment pipeline.
tags: [mlops, deployment, infrastructure, cicd]
generated: {by: process:okf-updater, at: "2026-09-24T22:15:00Z"}
sources: []
---

# Phase 1: Server Provisioning & MLOps Architecture

This document describes the foundational implementation of Phase 1 for the AMPS project. It translates the theoretical requirements of the edge server (i7-14700K, 128GB RAM, 16GB RTX 5070 Ti) into the concrete infrastructure deployment utilized by the engine.

## 1. Base Operating System & Storage Subsystem

The foundation relies on a bare-metal installation to maximize P-Core CPU cycles and ensure deterministic execution of the Numba JIT loops.

* **Operating System:** The server runs Ubuntu 26.04 LTS (Resolute Raccoon) deployed directly on bare metal to eliminate virtualization overhead.
* **Storage Topology (BTRFS):** The root partition utilizes the BTRFS filesystem. This allows the system to leverage transparent `zstd` compression at the block level.
* **Storage Compression:** Because the Numba engine writes massive float-arrays to Zarr telemetry buffers, enabling `zstd` compression ensures the data is compressed in RAM before hitting the SSD's NAND flash. This drastically reduces write amplification and extends the endurance of the consumer-grade NVMe drive.

## 2. Zero-Ingress Networking (Tailscale)

To overcome the hostile routing topologies inherent to edge environments (such as Carrier-Grade NAT), the server maintains a strict zero-ingress perimeter.

* **Tailscale Mesh:** The node connects to a private WireGuard mesh via Tailscale, avoiding the need for public IPs or manual cloud bastions.
* **Firewall Policy:** All incoming external traffic is dropped at the firewall level. Administrative access is routed exclusively through the encrypted Tailnet interface (`100.x.y.z`).

## 3. The NVIDIA Open-Source Driver Stack

Ubuntu 26.04 LTS ships with the Linux 7.0 kernel, formally promoting Rust support to stable. This architectural shift fundamentally simplifies GPU integration.

* **Open Kernel Modules:** The system leverages NVIDIA's open-source kernel modules (`nvidia-driver-580-open`). This interfaces seamlessly with the RTX 5070 Ti hardware without relying on external PPAs or triggering legacy DKMS compilation conflicts.
* **Hardware Prerequisites:** Resizable BAR (ReBAR) is enabled and the Compatibility Support Module (CSM) is disabled in the motherboard BIOS to provide the host OS with unimpeded access to the GPU's memory address space.

## 4. Container Runtime & GPU Passthrough

The cognitive engine (`llama-server`) runs within a containerized environment to strictly isolate its dependencies from the Numba simulation engine.

* **Docker Engine:** The system utilizes the official Docker Engine Debian packages to guarantee compatibility and predictable daemon behavior.
* **NVIDIA Container Toolkit:** The official container toolkit bridges the Docker runtime to the host GPU, enabling the Container Device Interface (CDI) passthrough required for high-throughput LLM inference.

## 5. CPU Topology Pinning (Heterogeneous Compute)

The i7-14700K features an asymmetric architecture (8 P-Cores and 12 E-Cores). Mixing heavy background tasks with latency-sensitive engine loops on this architecture causes fatal CPU starvation.

* **Engine Isolation:** Using Linux `cgroups`, **P-Core 0 and P-Core 1** are reserved exclusively for the Numba JIT loop, guaranteeing deterministic, single-threaded execution.
* **Orchestrator Constriction:** The `llama-server` container (hosting the 70B God Agent) and all background observability tools (such as Prometheus) are pinned strictly to the **12 E-Cores**. This prevents the God Agent from starving the simulation's primary performance cycles during massive macro-economic calculations.

## 6. Dependency Management & Bootstrapping

The execution environment is designed to be highly reproducible, completely bypassing the fragility of standard Python package managers.

* **Package Management:** The repository utilizes `pixi` to lock Python, C++, and Rust binaries. This ensures the Numba JIT compilers and Cython `uvloop` bindings compile identically across both local development machines and the production server.
* **VRAM Safety Margin:** The deployment stack explicitly configures the `llama-server` with `--mem-fraction-static 0.90`. This guarantees the 27B Swarm model leaves 1.6GB of VRAM free for the host OS and GBNF FSM masks, preventing Out-Of-Memory (OOM) crashes during concurrent tick cascades.
* **Development Velocity:** During initial validation, the orchestrator utilizes a lightweight proxy model (e.g., Llama-3.1-8B) in place of the full 70B model. This reduces prefill latency to seconds, preserving development velocity during Limit Order Book integration.
