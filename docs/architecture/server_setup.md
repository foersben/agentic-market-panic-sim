---
type: Concept
title: Server Infrastructure and Edge Networking
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 1.1
description: Hardware mapping, storage tuning for consumer SSDs, and zero-ingress edge networking.
tags: [infrastructure, devops, networking, performance, hardware]
generated: {by: process:okf-updater, at: "2026-09-24T20:53:00Z"}
sources: []
---

# Server Infrastructure and Edge Networking

The AMPS engine executes massive LLM swarm calculations alongside high-frequency limit order book (LOB) matching. Our infrastructure relies on a dedicated edge server built around consumer/prosumer hardware (Intel Core i7-14700K, 128GB RAM, RTX 5070 Ti, and a consumer-grade NVMe SSD).

Operating in a decentralized edge environment requires overcoming hostile network topologies while extracting maximum performance without destroying consumer-grade hardware.

## 1. Zero-Ingress Network Topology

Edge environments often sit behind Carrier-Grade NAT (CGNAT) or complex double-NAT routing layers that strictly prohibit traditional inbound port forwarding.

### The Solution: Reverse Outbound Tunneling

To bypass inbound constraints natively, we implement a **zero-ingress reverse tunneling strategy**. The server never exposes open ports to the edge network.

* **Dropbear over OpenSSH:** We utilize `dropbear` as the tunneling client. Because the RTX 5070 Ti limits us to 16GB of VRAM and we rely heavily on system RAM for Numba arrays, minimizing daemon memory footprints is critical. Dropbear is exceptionally lightweight and maintains persistent outbound sockets more reliably in unstable edge environments than a full OpenSSH server.
* **Persistent Reverse SSH (`ssh -R`):** The server initiates a secure, outbound-only connection to an external cloud bastion. External telemetry consumers or UI dashboards connect to the bastion, which routes traffic securely back down the established socket into the AMPS orchestration plane.

## 2. Hardware-Aware Tuning (Memory & Storage)

Deploying a high-frequency trading simulation on an i7-14700K and a consumer NVMe SSD requires strict I/O and memory management to prevent hardware degradation and latency spikes.

### Memory: Physical Pinning over zRAM Compression

While memory compression (zRAM) is a popular Linux optimization, we **actively reject zRAM** in favor of direct hardware pinning via **Hugepages**.

* **The Argument Against zRAM:** The simulation relies on tight JIT-compiled Numba loops executing over NumPy float arrays. zRAM introduces CPU overhead when compressing/decompressing memory pages, which would steal vital cycles from the i7-14700K's P-Cores during a tick cascade.
* **The Argument For Hugepages:** Instead, we allocate physical 1GB hugepages directly via kernel parameters, mapping them transparently into the orchestration layer. This eliminates Translation Lookaside Buffer (TLB) misses during massive array scans, guaranteeing deterministic microsecond latency that zRAM would otherwise jeopardize.

### Storage: BTRFS for Consumer SSD Survival

AMPS generates terabytes of semantic trace buffers (via LanceDB/Zarr) during panic cascades.

* **The Consumer SSD Bottleneck:** Consumer NVMe drives suffer from relatively low endurance (TBW - Terabytes Written) and small SLC caches. Blasting raw, uncompressed trace telemetry to the disk would rapidly wear out the NAND flash and trigger severe write-throttling.
* **The Argument For BTRFS (`zstd`):** We deploy the storage pool on BTRFS with transparent `zstd` block compression. Because our trace logs (JSON strings and float arrays) are highly compressible, `zstd` squashes the data in-memory before it ever hits the storage controller. This drastically reduces write amplification, saves the consumer SSD's lifespan, and actually increases effective write throughput, as the CPU compresses data much faster than the NVMe drive can write raw blocks.

## 3. Secure CI/CD Deployment (GitHub Actions)

Deploying to an edge server via GitHub Actions introduces a security risk if not heavily restricted. We combine our Zero-Ingress topology with GitHub Environment protection rules to maintain absolute control over the physical server.

### Bypassing Ingress

The physical server is never exposed to GitHub's IP ranges. When a GitHub Action triggers a deployment:

* The Action SSHs into the external Cloud Bastion.
* The Bastion securely routes the payload down the persistent reverse tunnel.

This ensures the edge hardware remains cloaked from the public internet. 

### The Deployment Admin Wall

To prevent unauthorized code from reaching the hardware (e.g., if a team member pushes to `main`), the deployment pipeline is locked behind a strict admin approval gate.

* **GitHub Environments:** Deployment credentials (bastion SSH keys) are isolated inside a specific GitHub Environment (e.g., `edge-production`) rather than repository-wide secrets.
* **Required Reviewers:** The `edge-production` environment requires explicit manual approval. When the CI pipeline reaches the deployment stage, execution freezes. No code can connect to the bastion until the system administrator physically clicks "Approve" in the GitHub UI, ensuring total authority over the physical hardware.
