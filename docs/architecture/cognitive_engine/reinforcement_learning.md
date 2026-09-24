---
type: Concept
title: Reinforcement Learning Distillation
status: stable
stale_after: "2027-01-01T00:00:00Z"
version: 1.0
description: Distillation of LLM agent reasoning into high-throughput RL policies.
tags: [architecture, machine-learning, reinforcement-learning, scaling]
generated: {by: process:okf-updater, at: "2026-09-24T20:20:00Z"}
sources: 
  - resource: "docs/latex/mlops_project_plan/main.tex"
---

In the **AMPS (Agentic Market Panic Simulator)** architecture, Reinforcement Learning (RL) is not used in the traditional quantitative finance sense (i.e., training agents to maximize profit). Instead, it is deployed as an **RL Distillation Pipeline** designed to bridge the gap between cognitive realism and cloud-scale throughput.

## The Scalability vs. Realism Dilemma

* **Traditional RL Agents:** Fast (microsecond inference) and horizontally scalable to millions of entities, but rely on rigid mathematical reward functions (e.g., maximizing PnL or Sharpe ratio) that cannot reproduce bounded rationality, emotional panic, or rumor contagion during a financial crash.
* **Generative LLM Swarms (Phases 1 & 2):** Highly realistic panic dynamics and sentiment interpretation, but bounded by GPU memory and compute. On a single RTX 5070 Ti (16 GB VRAM), the hardware ceiling is ~400 concurrent agents per tick even with 1.58-bit ternary models and Radix KV-cache sharing.
* **The AMPS Solution (Phase 3 Distillation):** Use LLM agents to generate high-fidelity behavioral panic traces, then **distill the LLM reasoning into lightweight neural network RL policies via Proximal Policy Optimization (PPO)**.

## Step-by-Step Architecture

<div style="display: flex; flex-direction: column; gap: 1rem; align-items: center; margin: 1.5rem 0; font-family: system-ui, sans-serif; font-size: 0.9rem;">
  
  <!-- Phase 1 & 2 -->
  <div style="border: 2px solid #4a90e2; padding: 1rem; border-radius: 8px; width: 100%; max-width: 500px; text-align: center; background: rgba(74, 144, 226, 0.05);">
    <h3 style="margin-top: 0; color: #4a90e2; font-size: 1rem; margin-bottom: 0.8rem;">Phase 1 & 2: Trace Collection</h3>
    <div style="display: grid; grid-template-columns: 1fr auto 1fr auto 1fr; align-items: center; gap: 0.5rem;">
      <div style="background: rgba(255,255,255,0.1); padding: 0.5rem; border-radius: 4px; border: 1px solid rgba(255,255,255,0.2);">Macro Shocks</div>
      <div style="color: #888;">→</div>
      <div style="background: #e67e22; padding: 0.75rem 0.5rem; border-radius: 4px; color: #fff; font-weight: bold;">400 LLM Agents</div>
      <div style="color: #888;">←</div>
      <div style="background: rgba(255,255,255,0.1); padding: 0.5rem; border-radius: 4px; border: 1px solid rgba(255,255,255,0.2);">LOB Engine</div>
    </div>
    <div style="margin-top: 0.8rem; color: #888;">↓</div>
    <div style="background: #27ae60; padding: 0.5rem 1rem; border-radius: 4px; display: inline-block; color: white; margin-top: 0.2rem; font-weight: bold;">Decision Traces (LanceDB / Zarr)</div>
  </div>

  <div style="font-size: 1.5rem; color: #666; line-height: 0.5;">↓</div>

  <!-- Phase 3 -->
  <div style="border: 2px solid #9b59b6; padding: 1rem; border-radius: 8px; width: 100%; max-width: 500px; text-align: center; background: rgba(155, 89, 182, 0.05);">
    <h3 style="margin-top: 0; color: #9b59b6; font-size: 1rem; margin-bottom: 0.8rem;">Phase 3: RL Distillation (PPO)</h3>
    <div style="display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; gap: 0.5rem;">
      <div style="background: rgba(255,255,255,0.1); padding: 0.5rem; border-radius: 4px; border: 1px solid rgba(255,255,255,0.2);">Gymnasium<br><span style="font-size: 0.8em; color: #bbb;">State <b>S_t</b></span></div>
      <div style="color: #888;">↔</div>
      <div style="background: #e74c3c; padding: 0.75rem 0.5rem; border-radius: 4px; color: #fff; font-weight: bold;">PPO Policy<br><span style="font-size: 0.8em; font-weight: normal;">Action <b>a_t</b></span></div>
    </div>
    <div style="margin-top: 0.8rem; background: #c0392b; padding: 0.5rem; border-radius: 4px; color: white;">Divergence Loss (Targeting LLM Traces)</div>
  </div>

  <div style="font-size: 1.5rem; color: #666; line-height: 0.5;">↓</div>

  <!-- Deployment -->
  <div style="border: 2px solid #2ecc71; padding: 1rem; border-radius: 8px; width: 100%; max-width: 500px; text-align: center; background: rgba(46, 204, 113, 0.05);">
    <h3 style="margin-top: 0; color: #2ecc71; font-size: 1rem; margin-bottom: 0.8rem;">Production Scaling</h3>
    <div style="display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; gap: 0.5rem;">
      <div style="background: #16a085; padding: 0.5rem; border-radius: 4px; color: #fff; font-weight: bold;">1,000,000 Agents</div>
      <div style="font-size: 0.8rem; font-style: italic; color: #888;">Microsecond<br>Inference</div>
      <div style="background: rgba(255,255,255,0.1); padding: 0.5rem; border-radius: 4px; border: 1px solid rgba(255,255,255,0.2);">Numba LOB</div>
    </div>
  </div>
</div>

The distillation pipeline executes through the following phases:

### 1. Trace Generation (LLMs as the "Reward Signal")

The 400 generative LLM agents trade through market shock scenarios generated by the Macro-Orchestrator against algorithmic Inventory-Aware Market Makers. Instead of crafting a synthetic reward function, the simulation records each agent's exact decision traces, order book states, and trading actions to persistent storage (LanceDB / Zarr). These traces become the **ground-truth behavioral target** for the RL agents.

### 2. Environment & Fixed-Size State Vector Formulation

The simulation matching engine is formatted as an **OpenAI Gym / Gymnasium** environment. At tick $t$, the state observed by an agent is represented as a fixed-size vector:

$$
S_t = [\mathbf{s}_{\text{LOB}},\, \mathbf{e}_{\text{news}},\, \mathbf{e}_{\text{persona}}]
$$

Where:

* $\mathbf{s}_{\text{LOB}}$: Numerical Limit Order Book metrics (best bid, best ask, mid-price, order book depth, bid-ask spread, order flow imbalance).
* $\mathbf{e}_{\text{news}}$: A dense semantic embedding of the current macroeconomic shock/news headline, computed once per tick on CPU using `FastEmbed`.
* $\mathbf{e}_{\text{persona}}$: A static persona embedding representing the agent profile (e.g., retail panic trader, institutional hedger).
    * **Critical Invariant:** Without $\mathbf{e}_{\text{persona}}$, a single global neural network would regress to the population mean, destroying the behavioral diversity and panic cascades that the simulation was created to capture.

### 3. PPO Policy Training & Loss Formulation

* **Model Architecture:** Lightweight feed-forward Actor-Critic neural networks initialized using frameworks such as Stable-Baselines3 or Ray RLlib.
* **Algorithm:** Proximal Policy Optimization (PPO) with clipped surrogate objective.
* **Reward / Loss Design:** The reward function directly penalizes deviations between the RL agent's chosen action $a_t$ and the historical decision $a_{\text{LLM}, t}$ recorded by the corresponding LLM agent under identical market conditions:

$$
R_t = -\mathcal{D}(a_t, a_{\text{LLM}, t}) - \lambda \cdot \text{KL}(\pi_\theta(\cdot \mid S_t) \parallel \pi_{\text{LLM}}(\cdot \mid S_t))
$$

Over thousands of episodes, the PPO policy internalizes the nuanced, irrational panic behaviors without needing to evaluate the underlying LLM.

### 4. Policy Evaluation & Parity Verification

The distilled policy is evaluated using the project evaluation pipeline to verify behavioral parity:

* **Herding Index ($H_t$):** Measures whether the collective actions of distilled agents exhibit the same cluster-selling and liquidity-drain spikes as the LLM cohort.
* **Price Impact & Flash-Crash Dynamics:** Asserts that the distilled swarm triggers equivalent liquidity black holes against the market makers.

### 5. Decommissioning LLMs & Cloud-Scale Execution

Once policy convergence is verified, the resource-heavy 70B/27B models and `llama-server` are completely removed from the execution loop. The distilled PPO actor networks run vectorized batch forward-passes on CPU/GPU in microseconds. The Python `uvloop` layer can then be replaced with Numba-JIT parallel array dispatch or compiled routines, bypassing Python GIL bottlenecks to clear orders for up to 1,000,000 agents per tick.

## Risk Management & Graceful Degradation

Because RL reward shaping can be prone to non-convergence, Phase 3 (Distillation) is structured as a stretch goal. If PPO distillation fails to converge within the project timeframe, the system gracefully degrades to deliver the fully functional Phase 2 heterogeneous LLM architecture.
