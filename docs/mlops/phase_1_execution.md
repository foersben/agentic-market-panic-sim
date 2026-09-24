---
type: Concept
title: MLOps Execution Plan (Phase 1)
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 2.0
description: Chronological, step-by-step physical server provisioning guide for Phase 1 of the MLOps deployment pipeline.
tags: [mlops, deployment, infrastructure, cicd, guide]
generated: {by: process:okf-updater, at: "2026-09-24T21:40:00Z"}
sources: []
---

# Phase 1: Server Provisioning & MLOps Execution Guide

This document is the chronological, step-by-step implementation guide for Phase 1 of the AMPS project. It translates the architectural requirements of the edge server (i7-14700K, 128GB RAM, 16GB RTX 5070 Ti) into a strict deployment sequence.

**Do not deviate from the order of these steps.** Skipping the `nouveau` blacklist or delaying the BTRFS compression setup will result in kernel panics or immediate SSD degradation.

---

## Step 1: Base Operating System & Storage Subsystem

The foundation relies on a bare-metal installation to maximize P-Core CPU cycles.

1. **Install Ubuntu 26.04 LTS (Resolute Raccoon):** Boot from a USB installer. Select a minimal installation.
2. **Format as BTRFS:** During the storage configuration step, explicitly override the default `ext4` or `LVM` setup and format the root partition (`/`) as **BTRFS**.
3. **Enable `zstd` Transparent Compression:** Immediately after the first boot, you must enable compression to protect the consumer NVMe SSD from the massive Zarr telemetry arrays.

    * Open `/etc/fstab`.
    * Find the BTRFS mount point for the root filesystem.
    * Append `compress=zstd:3` to the mount options (e.g., `defaults,subvol=@,compress=zstd:3`).
    * Run `sudo mount -o remount /` to apply the compression instantly.
    * *Rationale:* This ensures all massive float-arrays dumped by the engine are compressed in RAM before hitting the SSD's NAND flash, extending its lifespan.

---

## Step 2: Zero-Ingress Networking (Tailscale)

Before opening the server to the internet or installing external dependencies, we secure the perimeter.

1. **Install Tailscale:** `curl -fsSL https://tailscale.com/install.sh | sh`
2. **Authenticate & Enable SSH:** Run `sudo tailscale up --ssh`.
3. **Lock Down the Firewall:** Use `ufw` to deny all incoming traffic (`sudo ufw default deny incoming`). Tailscale's WireGuard mesh bypasses this natively, ensuring you can SSH into the machine via its `100.x.y.z` Tailnet IP despite your ISP's Double NAT/CGNAT.

---

## Step 3: The NVIDIA Open-Source Drivers

Ubuntu 26.04 LTS ships with the Linux 7.0 kernel, formally promoting Rust support to stable. This allows NVIDIA's open-source kernel modules (`-open`) to interface seamlessly with the RTX 5070 Ti hardware out-of-the-box, bypassing the old `nouveau` traps and DKMS compilation issues.

1. **BIOS Preparation:** Ensure Resizable BAR (ReBAR) is enabled and the Compatibility Support Module (CSM) is disabled in the motherboard BIOS.
2. **Install Open Drivers:** Pull the latest open drivers directly from the native repositories via `sudo apt install nvidia-driver-580-open`.
3. **Verify:** Run `nvidia-smi` to ensure the RTX 5070 Ti is recognized and VRAM reads `16384 MiB`.

---

## Step 4: Container Runtime & GPU Passthrough

The cognitive engine (`llama-server`) runs in Docker to prevent library conflicts with the Numba engine.

1. **Install Docker Engine:** Use the official Docker apt repository (do not use Snap).
2. **Install NVIDIA Container Toolkit:** This acts as the bridge between Docker and the host GPU.

    * Install `nvidia-container-toolkit` via `apt`.
    * Configure the Docker daemon: `sudo nvidia-ctk runtime configure --runtime=docker`
    * Restart Docker: `sudo systemctl restart docker`

3. **Validate CDI:** Run a test container (`docker run --rm --gpus all ubuntu nvidia-smi`) to ensure Docker has root access to the GPU.

---

## Step 5: CPU Topology Pinning (Heterogeneous Compute)

The 70B God Agent will starve the Numba ECS Engine if allowed to roam free across the i7-14700K. We must isolate them.

1. **Isolate the P-Cores:** Using Linux `cgroups` or `taskset`, reserve **P-Core 0 and P-Core 1** exclusively for the Numba JIT loop.
2. **Constrain the System:** Modify the Docker daemon or `docker-compose.yml` to use `cpuset` flags, restricting the `llama-server` (God Agent) and background observability tools (Prometheus) to the **12 E-Cores**.
3. *Rationale:* This ensures the critical simulation tick rate never drops, even when the CPU is running at 100% load generating a macro-economic shock.

---

## Step 6: Dependency Management & Bootstrapping

With the hardware tuned, constrained, and secured, we bootstrap the AMPS engine.

1. **Install Pixi:** `curl -fsSL https://pixi.sh/install.sh | bash`
2. **Clone the Repository:** Over the Tailscale SSH connection, clone the AMPS repository.
3. **Install Dependencies:** Run `pixi install -e dev` in the root directory. This downloads the exact, locked versions of Numba, Cython, and `uvloop`.
4. **VRAM Safety Check:** Edit your `docker-compose.yml` to ensure the `llama-server` command includes `--mem-fraction-static 0.90`. This guarantees the 27B Swarm model leaves 1.6GB of VRAM free for the host OS and GBNF FSM masks.
5. **Start the Proxy Model:** During this Phase 1 development, update your environment variables to load a lightweight 8B proxy model instead of the full 70B model. This reduces prefill latency to seconds, allowing for rapid iteration of the Numba Limit Order Book.
6. **Launch:** Run `pixi run just serve` (or `docker compose up -d`) to launch the unified stack.
