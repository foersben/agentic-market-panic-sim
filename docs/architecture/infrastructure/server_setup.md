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

The AMPS engine executes massive LLM swarm calculations alongside high-frequency limit order book (LOB) matching. Our infrastructure relies on a dedicated edge server built around consumer/prosumer hardware (Intel Core i7-14700K, 128GB RAM, RTX 5070 Ti, and a consumer-grade NVMe SSD).

Operating in a decentralized edge environment requires overcoming hostile network topologies while extracting maximum performance without destroying consumer-grade hardware.

## 1. Base Provisioning & Security Foundation

### Storage & Operating System Foundation

* Installed Ubuntu 26.04 on the Seagate FireCuda, provisioning a BTRFS root filesystem over a LUKS-encrypted LVM volume.
* Skipped extraneous Snap packages to ensure the AMPS engine telemetry and local models can be orchestrated cleanly via Docker without external hypervisor overhead.

### Pre-Boot Decryption Environment (Dropbear)

* Installed `dropbear-initramfs` to host an ephemeral SSH server strictly during the boot sequence.
* Copied your GitHub-imported SSH keys into Dropbear's `authorized_keys` to enable passwordless entry.
* Migrated the pre-boot service to port 2222 via `dropbear.conf` and recompiled the boot image, effectively isolating it to prevent Man-in-the-Middle host-key collisions with the primary OS.

### Client-Side Cryptography & Networking

* Structured your Arch Linux workstation's `~/.ssh/config` with distinct `amps-unlock` and `amps-main` host profiles.
* Removed physical private key file paths from the configuration, delegating authentication entirely to the KeePassXC SSH agent running over D-Bus.

### Automation & Workspace Integration

* Engineered a Bash deployment script that dynamically locates the server on the `192.168.178.0/24` subnet and fetches the LUKS passphrase securely via `secret-tool`.
* Programmed the script to pipe the decryption key, absorb the deliberate Dropbear disconnect, and seamlessly bridge the connection to OpenSSH once the OS loads.
* Deployed a headless-optimized Zsh environment with persistent history, Vi mode bindings, and an ergonomic Tmux configuration.

## 2. Zero-Ingress Network Topology (Tailscale)

Edge environments often sit behind Carrier-Grade NAT (CGNAT) or complex double-NAT routing layers that strictly prohibit traditional inbound port forwarding.

### The Solution: Tailscale (WireGuard)

To bypass inbound constraints natively, we implement a **zero-ingress Tailscale mesh network**. The server never exposes open ports to the edge network or public internet.

* **Why Tailscale:** It uses WireGuard to seamlessly punch through the ISP's Double NAT and CGNAT without requiring manual public cloud bastions or keep-alive cron jobs. The daemon's memory overhead is negligible on a 128GB system and does not touch the critical GPU VRAM.
* **No Reverse Proxy:** Because Tailscale provides end-to-end encryption within the Tailnet, we eliminate overhead daemons like Nginx. Internal Docker containers communicate over plain HTTP locally, and ports are exposed directly via the Tailscale interface (`100.x.y.z`).

## 3. Heterogeneous Compute (CPU Topology)

The i7-14700K features an asymmetric architecture (8 P-Cores and 12 E-Cores). Mixing heavy background tasks with latency-sensitive game engine loops on this architecture causes fatal CPU starvation.

### The Threat: The God Agent Starving the Engine

The 70B God Agent (which orchestrates macro-shocks) must run in system RAM because it heavily exceeds the RTX 5070 Ti's 16GB VRAM limit. When `llama.cpp` evaluates a 500-token macro prompt, it attempts to peg all 20 threads to 100%. If allowed, this starves the Numba JIT ECS engine, plummeting the simulation tick rate.

### The Solution: Strict Thread Pinning

We exploit the heterogeneous topology using Linux `taskset` and Docker CPU sets:

* **The Numba ECS Engine:** Strictly pinned to **P-Core 0 and P-Core 1**. This guarantees the deterministic, single-threaded JIT execution path is never interrupted.
* **The 70B God Agent:** `llama-server` is bound entirely to the **12 E-Cores** (and remaining P-Cores). The God Agent calculates macro-shocks over several minutes in the background without stealing the engine's primary performance cycles.

## 4. Memory & Storage: Saving the SSD

AMPS generates terabytes of semantic trace buffers during panic cascades. Blasting raw trace telemetry to a consumer NVMe drive will rapidly exhaust its Terabytes Written (TBW) endurance.

### The 30GB In-Memory Telemetry Buffer

With 128 GB of total RAM, we have roughly **67 GB of completely free RAM** remaining after loading the 70B God Agent, OS overhead, and LLM caches.

* We pre-allocate a **30 GB ring buffer** purely in RAM for the Numba engine to write tick outcomes.
* At ~30 KB per tick (for 400 agents), 30 GB holds exactly **1,000,000 simulation ticks** (over 27 hours at 10 ticks/sec).
* **Chunked Async Flushes:** When the 30 GB buffer nears capacity, an asynchronous thread compresses it using Blosc (Zstd) and writes it sequentially to the SSD as a massive Zarr chunk.

### BTRFS Transparent Compression

The storage pool runs on BTRFS with transparent `zstd` block compression. Because our trace logs are sparse float arrays and JSON strings, they compress down to 10-20% of their original size. This combination of RAM-buffering and filesystem compression ensures the consumer SSD rarely sees raw I/O, extending its lifespan indefinitely.

## 5. Memory Management (HugePages & THP)

We configure Transparent HugePages (THP) by changing the kernel's default behavior from `always` to `madvise` via the GRUB bootloader (`transparent_hugepage=madvise`).

### The Mechanics of THP and the TLB

By default, the Linux kernel manages memory in blocks called "pages," which are typically 4KB in size. When the CPU needs to access memory, it must translate virtual memory addresses into physical RAM addresses using a hardware cache called the Translation Lookaside Buffer (TLB).

* **The Problem:** Modern LLMs (like our 70B God Agent) load massive contiguous arrays of neural network weights spanning tens of gigabytes. Tracking these weights in tiny 4KB chunks rapidly exhausts the CPU's TLB cache, causing high "TLB miss" rates that severely degrade inference performance.
* **The HugePage Solution:** A "HugePage" collapses 512 standard 4KB pages into a single massive 2MB page. This allows the CPU to track 512 times more memory per TLB cache entry, drastically accelerating memory-bound workloads like LLM token generation.

### Why We Use `madvise` Instead of `always`

While HugePages are vital for the LLM, setting the kernel's THP policy to `always` is catastrophic for the simulation engine. This reasoning is rooted in the strict hardware determinism and latency requirements of the AMPS environment:

* **Preventing Unpredictable Interrupts:** When THP is set to the default `always`, the Linux kernel runs a background thread (`khugepaged`) that aggressively scans RAM, attempting to collapse standard 4KB memory pages into 2MB hugepages. This background coalescing operation causes unpredictable micro-stutters, memory locks, and CPU interrupts.
* **Protecting the Numba JIT Engine:** Our architecture relies on a highly optimized, single-threaded Limit Order Book (LOB) compiled with Numba JIT, pinned to P-Core 0 and P-Core 1. If the kernel arbitrarily pauses memory access to defragment pages, it introduces latency spikes that destroy the precise timing required by the simulation's event bus.
* **Opt-in Memory Management (`madvise`):** By restricting THP to `madvise`, we stop the kernel from autonomously reorganizing memory in the background. The OS will only allocate hugepages if a specific application explicitly requests them via the `madvise()` system call (which `llama-server` does). This guarantees that our simulation engine retains absolute control over its memory access times without being undermined by background OS overhead.

## 6. Secure CI/CD Deployment

Deploying to an edge server via GitHub Actions introduces a security risk if not heavily restricted. We combine Tailscale with GitHub Environment protection rules and fork isolation.

### Preventing Malicious Fork Execution

To prevent arbitrary code execution on the physical hardware via malicious Pull Requests, the GitHub Actions settings are configured to **"Require approval for all outside collaborators"**. This guarantees that no workflow runs on the self-hosted runner from a fork until explicitly authorized by a repository administrator.

### Outbound-Only Polling (Self-Hosted Runner)

The physical server is never exposed to GitHub's IP ranges. Instead of opening firewall ports or relying on Ephemeral Tailscale Auth Keys for cloud runners to SSH inward, the server runs a **Local Self-Hosted GitHub Actions Runner daemon**.

* The local daemon establishes a secure, outbound-only long-polling connection to GitHub over standard HTTPS.
* When a CI/CD job is triggered, the local runner pulls the code down natively and executes the deployment entirely from within the secure perimeter, eliminating the need for inbound network traversals.

### The Deployment Admin Wall

To prevent unauthorized code from reaching the hardware (e.g., if a team member pushes to `main`), the deployment pipeline is locked behind a strict admin approval gate.

* **GitHub Environments:** Deployment credentials (the Tailscale Auth Key) are isolated inside an `edge-production` GitHub Environment.
* **Required Reviewers:** The `edge-production` environment requires explicit manual approval. When the CI pipeline reaches the deployment stage, execution freezes until the administrator physically approves the workflow in the GitHub UI.
