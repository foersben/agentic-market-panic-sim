---
type: Concept
title: Server Infrastructure and Hardware Topology
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 1.2
description: Hardware mapping, heterogeneous compute pinning, and zero-ingress edge networking based on the MLOps Project Proposal.
tags: [infrastructure, devops, networking, performance, hardware]
generated: {by: process:okf-updater, at: "2026-09-24T21:40:00Z"}
sources: []
---

# Server Infrastructure and Hardware Topology

The AMPS engine executes massive LLM swarm calculations alongside high-frequency limit order book (LOB) matching. Our infrastructure relies on a dedicated edge server built around consumer/prosumer hardware (Intel Core i7-14700K, 128GB RAM, RTX 5070 Ti, and a consumer-grade NVMe SSD).

Operating in a decentralized edge environment requires overcoming hostile network topologies while extracting maximum performance without destroying consumer-grade hardware.

## 1. Zero-Ingress Network Topology (Tailscale)

Edge environments often sit behind Carrier-Grade NAT (CGNAT) or complex double-NAT routing layers that strictly prohibit traditional inbound port forwarding.

### The Solution: Tailscale (WireGuard)

To bypass inbound constraints natively, we implement a **zero-ingress Tailscale mesh network**. The server never exposes open ports to the edge network or public internet.

* **Why Tailscale:** It uses WireGuard to seamlessly punch through the ISP's Double NAT and CGNAT without requiring manual public cloud bastions or keep-alive cron jobs. The daemon's memory overhead is negligible on a 128GB system and does not touch the critical GPU VRAM.
* **No Reverse Proxy:** Because Tailscale provides end-to-end encryption within the Tailnet, we eliminate overhead daemons like Nginx. Internal Docker containers communicate over plain HTTP locally, and ports are exposed directly via the Tailscale interface (`100.x.y.z`).

## 2. Heterogeneous Compute (CPU Topology)

The i7-14700K features an asymmetric architecture (8 P-Cores and 12 E-Cores). Mixing heavy background tasks with latency-sensitive game engine loops on this architecture causes fatal CPU starvation.

### The Threat: The God Agent Starving the Engine

The 70B God Agent (which orchestrates macro-shocks) must run in system RAM because it heavily exceeds the RTX 5070 Ti's 16GB VRAM limit. When `llama.cpp` evaluates a 500-token macro prompt, it attempts to peg all 20 threads to 100%. If allowed, this starves the Numba JIT ECS engine, plummeting the simulation tick rate.

### The Solution: Strict Thread Pinning

We exploit the heterogeneous topology using Linux `taskset` and Docker CPU sets:

* **The Numba ECS Engine:** Strictly pinned to **P-Core 0 and P-Core 1**. This guarantees the deterministic, single-threaded JIT execution path is never interrupted.
* **The 70B God Agent:** `llama-server` is bound entirely to the **12 E-Cores** (and remaining P-Cores). The God Agent calculates macro-shocks over several minutes in the background without stealing the engine's primary performance cycles.

## 3. Memory & Storage: Saving the SSD

AMPS generates terabytes of semantic trace buffers during panic cascades. Blasting raw trace telemetry to a consumer NVMe drive will rapidly exhaust its Terabytes Written (TBW) endurance.

### The 30GB In-Memory Telemetry Buffer

With 128 GB of total RAM, we have roughly **67 GB of completely free RAM** remaining after loading the 70B God Agent, OS overhead, and LLM caches. 

* We pre-allocate a **30 GB ring buffer** purely in RAM for the Numba engine to write tick outcomes. 
* At ~30 KB per tick (for 400 agents), 30 GB holds exactly **1,000,000 simulation ticks** (over 27 hours at 10 ticks/sec).
* **Chunked Async Flushes:** When the 30 GB buffer nears capacity, an asynchronous thread compresses it using Blosc (Zstd) and writes it sequentially to the SSD as a massive Zarr chunk.

### BTRFS Transparent Compression

The storage pool runs on BTRFS with transparent `zstd` block compression. Because our trace logs are sparse float arrays and JSON strings, they compress down to 10-20% of their original size. This combination of RAM-buffering and filesystem compression ensures the consumer SSD rarely sees raw I/O, extending its lifespan indefinitely.

## 4. Secure CI/CD Deployment

Deploying to an edge server via GitHub Actions introduces a security risk if not heavily restricted. We combine Tailscale with GitHub Environment protection rules.

### Ephemeral Tailscale Authentication

The physical server is never exposed to GitHub's IP ranges. When a GitHub Action triggers a deployment:

* The Action uses a short-lived Tailscale Ephemeral Auth Key to instantly join the private Tailnet.
* It deploys the code via the Tailnet IP and immediately disconnects and destroys the key.

### The Deployment Admin Wall

To prevent unauthorized code from reaching the hardware (e.g., if a team member pushes to `main`), the deployment pipeline is locked behind a strict admin approval gate.

* **GitHub Environments:** Deployment credentials (the Tailscale Auth Key) are isolated inside an `edge-production` GitHub Environment.
* **Required Reviewers:** The `edge-production` environment requires explicit manual approval. When the CI pipeline reaches the deployment stage, execution freezes until the administrator physically approves the workflow in the GitHub UI.
