---
type: Concept
title: Semantic RAG Caching Pipeline
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 1.0
description: Caching LLM logic using Knowledge Graphs and Hybrid Search to upscale agent capacity.
tags: [architecture, machine-learning, performance, caching]
generated: {by: process:okf-updater, at: "2026-09-24T20:34:00Z"}
sources: []
---

# Semantic RAG Caching Pipeline

While Phase 1 and 2 of the AMPS architecture use **Slot Prefix Caching** (via `llama.cpp` Radix Trees) to save VRAM on prompt loading, exact-token caching still requires full GPU forward passes for agent generation. To upscale the simulation from 400 to thousands of concurrent agents on a single GPU, AMPS implements a **Semantic RAG-based Caching Pipeline**.

By treating the vector database (LanceDB) as a semantic cache, the engine short-circuits the LLM entirely if an agent finds itself in a macroeconomic state highly similar to one that has already been computed.

## 1. The Upscale Potential

In a market panic simulation, herd behavior and contagion are dominant. During a flash crash, a massive percentage of retail agents will arrive at the exact same logical conclusion.

* **Current Baseline:** ~400 concurrent agents executing full LLM forward passes on an RTX 5070 Ti.
* **Semantic Cache Impact:** Assuming an 80% cache hit rate (where panicked agents cluster into identical behavioral trajectories):
    * 20% of agents execute the full LLM pipeline (the vanguard).
    * 80% of agents bypass the GPU, retrieving their actions directly from a sub-millisecond database lookup.
* **Upscale Result:** The generative swarm scales to **2,000-3,000 LLM agents** on the exact same hardware compute budget.

## 2. Knowledge Graph & Thesaurus Normalization

The primary threat to semantic caching is vocabulary variance. If one agent's news feed reads "market plummeting" and another reads "stocks tanking", the raw semantic distance might cause a cache miss despite the scenario being identical.

To maximize the cache hit rate, raw text is passed through a CPU-bound Knowledge Graph (KG) or Thesaurus Normalizer before being embedded by `FastEmbed`:

* **Event Normalization:** "tanking", "plummeting", "crashing" are mapped to `MARKET_CRASH_SEV_5`.
* **Persona Normalization:** "hedger", "risk-averse", "safe" are mapped to `PERSONA_INSTITUTIONAL_DEFENSIVE`.
* **Impact:** This flattening of semantic entropy artificially coerces highly similar scenarios into mathematically identical vectors, dramatically increasing the likelihood of a cache hit.

## 3. Hybrid Search & Complex Indexing

AMPS utilizes **LanceDB** to manage the trace states, utilizing a tiered hybrid search approach to balance speed and memory usage:

* **Top-Level Index (HNSW):** Hierarchical Navigable Small World graphs are used for the "hot cache" of recent states. It provides blindingly fast vector search but is highly memory-intensive.
* **Deep Index (IVF-PQ):** As the historical trace log grows into the millions, HNSW becomes prohibitive. Older traces are offloaded to an Inverted File Index with Product Quantization (IVF-PQ), compressing the vectors and efficiently backing them to disk.
* **Hybrid Retrieval (Dense + BM25):** The engine executes a dual-search:
    * *Dense Search:* Measures geometric similarity of the `FastEmbed` state vectors.
    * *Sparse Search (BM25):* Enforces exact keyword matching (e.g., `TICKER_AAPL`). This prevents the system from caching a "buy" action for a "sell" scenario just because the vectors were positioned closely in latent space.

## 4. Preventing Mode Collapse

A critical risk of aggressive semantic caching is **Mode Collapse** - if 1,000 unique agents hit the exact same cached trace, they will all place the exact same limit order at the exact same microsecond, destroying the noisy, heterogeneous diversity that AMPS was designed to capture.

* **Stochastic Retrieval:** The cache does not blindly return the Top-1 match. Instead, it retrieves the Top-$K$ actions taken in similar historical scenarios.
* **Temperature Sampling:** The engine samples an action from the Top-$K$ results based on a probability distribution (temperature). This preserves the chaotic, irrational noise of a real stock market while still bypassing the LLM generation overhead.
