# AMPS Test Suite & Verification Architecture

The Agentic Market Panic Simulator (AMPS) testing architecture is engineered around mathematical rigor, financial conservation laws, strict branch coverage, and deterministic execution. Rather than treating tests merely as regression shields, AMPS treats test specifications as executable mathematical proofs of macroeconomic and quantitative invariants.

The testing framework is partitioned into distinct domain-focused packages so that fast unit contracts, scientific invariants, property-based exploration, and latency benchmarks evolve independently without coupling simulation physics to transport or presentation layers.

---

## 1. Test Suite Taxonomy & Directory Catalog

```text
tests/
├── unit/                                  # Isolated component contracts & algorithm helpers
│   ├── analytics/                         # Design Space Exploration & parameter sweeps
│   ├── api/                               # Pydantic schemas, DraftState transitions, presenter logic
│   ├── cli/                               # Command-line interface entrypoints & argument parsers
│   ├── engine/
│   │   ├── core/                          # ECSWorld, GridEnvironment, SpatialHashGrid, placement
│   │   ├── invariants/                    # Double-buffering immutability, JIT parity, coordinate masks
│   │   └── systems/                       # Liquidity cascades, margin calls, contagion networks, interventions
│   ├── io/                                # Scenario JSON validation, draft state serialization
│   ├── shared/                            # Logging, constants, concurrency guards
│   └── telemetry/                         # Per-agent accumulation, Polars metrics, exports
├── integration/                           # Multi-system loop interaction & physical invariants
│   ├── api/                               # FastAPI endpoints, WebSocket streams, batch workers
│   ├── scientific_invariants/             # PDE conservation, thermodynamics, Data-Flow Matrices
│   │   ├── conservation/                  # Capital conservation, debt-to-equity non-negativity
│   │   └── kinetics/                      # Panic response curves, liquidity withdrawal kinetics
│   └── systems/                           # Five-phase loop ordering, batch orchestration
├── e2e/                                   # Full simulation runs & data persistence
│   ├── replay_and_io/                     # Zarr telemetry buffers & bit-exact replay playback
│   └── scenarios/                         # Curated market scenarios (baseline, collapse, intervention)
└── benchmarks/                            # Latency budgets & micro-benchmarks (pytest-benchmark)
```

### Architectural Package Catalog

The sections below detail the responsibilities, test boundaries, and design invariants for each primary test tier:

#### A. Unit Tests (`tests/unit/`)

Isolated component contracts, data structures, and mathematical helper logic that execute without spinning up the full simulation loop:

* **`analytics/`**: Validates the Design Space Exploration (DSE) bounds (capital deficits, asset correlation matrices) prior to expensive simulation runs.
* **`api/`**: Verifies HTTP/WebSocket interface schemas, presenter functions, and state machines:
  * Validates Pydantic schema coercion, economic parameter bounds, and JSON schema compatibility.
  * Asserts atomic draft state transitions (`DraftState` $\to$ `DraftService` $\to$ Live commit).
* **`cli/`**: Asserts CLI entrypoints, command-line arguments, headless execution switches.
* **`engine/core/`**: Tests the core ECS foundation, market layers, and spatial/network indexing:
  * `test_ecs_world.py`: Verifies zero-allocation entity creation, archetypal component registration, single-writer invariants, and garbage collection.
  * Spatial Hash Grid: Validates $O(1)$ spatial cell lookups, wrapping boundary queries, and entity relocation updates for spatial market interactions.
* **`engine/invariants/`**: Low-level computational and hardware invariant verification:
  * `test_read_layer_immutability.py`: Verifies that the `_read` layer of all biotope grids is cryptographically immutable (SHA-256 byte hashing) throughout an entire simulation step.
  * `test_numba_jit_parity.py`: Verifies numerical identity between Numba `@njit` kernels and pure-Python reference implementations.
  * `test_jit_capacity_masking_parity.py`: Asserts branchless float SIMD masking for carrying capacity thresholds.
* **`engine/systems/`**: Micro-contracts for individual simulation systems:
  * Liquidity Cascades: Validates temperature-scaled Softmax probability distribution calculations for depositor flight.
  * Central Bank Interventions: Verifies discount window loans and reserve requirement enforcements.
* **`io/`**: Verifies scenario serialization, JSON schema validation, migration edge cases, and Zarr metadata encoding.
* **`shared/`**: Tests structured logging formats, shared constants, thread-safety primitives, and exception hierarchies.
* **`telemetry/`**: Validates telemetry accumulation, Polars DataFrame conversion, metric decimation, condition alarms, and multi-format exporters.

---

#### B. Integration Tests (`tests/integration/`)

Multi-system loop interactions, boundary crossings, and overarching financial conservation laws:

* **`api/`**: Verifies FastAPI routes, WebSocket telemetry streaming, SSE connection lifecycles, and configuration mutations.
* **`ui/`**: Verifies static content rendering, template integrity, and tiered progressive disclosure workbench components.
* **`systems/`**: Asserts deterministic phase ordering and multi-system economic mechanics:
  1. **Flow Field Phase**: Dynamic gradient derivation, Jacobi relaxation, and sentiment advection.
  2. **Lifecycle Phase**: Agent balance sheet evaluation, margin call propagation.
  3. **Interaction Phase**: Asset fire sales, trading cascades, and cross-asset correlations.
  4. **Signaling Phase**: Panic signal synthesis, volatility indices updates, and systemic risk aggregation.
  5. **Telemetry & Termination Phase**: Replay buffer commits, WebSocket dispatch, and condition threshold evaluation.
* **`scientific_invariants/`**:
  * **`conservation/`**: Financial conservation laws:
    * Mass Conservation of Capital: Ensured zero sum across closed market trades ($\text{rtol} \le 1\times 10^{-5}$).
  * **`test_causal_data_flow_matrices.py`**: Automated Table-to-Trace Parity tests enforcing exact 1:1 correspondence between documented OKF Data-Flow Matrices and runtime simulation traces for Liquidity Cascades, Margin Calls, etc.
  * **`test_double_buffering_isolation.py`**: Enforces strict read/write layer isolation across multi-tick loop transitions.

---

#### C. End-to-End Tests (`tests/e2e/`)

Full-system scenario execution from initial state load to final termination:

* **`scenarios/`**: Executes complete market scenarios across varying temporal horizons (100 to 1,000+ ticks), asserting non-degeneracy, pricing stability, and agent insolvency bounds.
* **`replay_and_io/`**:
  * `test_zarr_replay_bit_exactness.py`: Serializes multi-tick simulation runs into compressed Zarr replay buffers and verifies bit-exact numerical round-trip playback completely bypassing the engine loop.

---

#### D. Performance Benchmarks (`tests/benchmarks/`)

Deterministic latency benchmarks asserted via `pytest-benchmark` against pre-defined performance budgets:

* Contagion network query throughput ($O(1)$ neighbour discovery).
* Sparse vs. dense Gaussian diffusion kernel execution latency for sentiment.
* Zarr chunk write and telemetry export serialization speeds.

---

## 2. Two-Pass Testing Methodology

AMPS employs a two-pass testing strategy to resolve the fundamental conflict between Numba JIT acceleration and Python test coverage instrumentation:

### Pass 1: Logic & Branch Coverage (`NUMBA_DISABLE_JIT=1`)
By launching the test suite with `NUMBA_DISABLE_JIT=1`, Numba decorators execute as standard Python functions, allowing `coverage.py` to trace branches.

### Pass 2: High-Performance Parity & Latency (JIT Enabled)
Tests tagged with `@pytest.mark.jit_parity` and `@pytest.mark.benchmark` run with full Numba JIT compilation active to verify numerical identity and latency.

---

## 3. Data-Flow Matrix Synchronization Protocol (Rule 05)

Every dynamic macroeconomic cascade and temporal state transition in AMPS must adhere to the **Data-Flow Invariant Architecture (Rule 05)**:

1. **Table-to-Trace Parity (Rule 05-A)**:
   Every documented Data-Flow Matrix in `docs/scientific_model/` must have a corresponding Pytest trace test in `test_causal_data_flow_matrices.py`.
2. **Branchless SIMD Mask Mandate (Rule 05-B)**:
   JIT kernels implementing Data-Flow Matrix rules must execute state transfers via scalar/vector float multiplication (`delta * alive_mask`). `if/else` conditionals are strictly prohibited.
3. **Bilateral Resource Mapping (Rule 05-C)**:
   OKF frontmatter `sources:` must explicitly link both the underlying system file and the corresponding trace test file.
4. **Continuous Agentic Synchronization Gate (Rule 05-D)**:
   Automated verification scripts enforce compliance in local development and CI via `audit_matrix_coverage.py` and `verify_matrix_trace_parity.py`.

---

## 4. Property-Based Testing (Hypothesis)

AMPS integrates Hypothesis property-based testing (`@pytest.mark.hypothesis_pilot`) to stress-test mathematical invariants across thousands of pseudo-randomly generated parameter combinations.

## 5. Mutation Testing (`mutmut`)

Mutation testing validates test-suite efficacy by programmatically introducing deliberate faults (mutations) into production code.

## 6. Code Quality & Coverage Governance

### Strict Branch Coverage Floor ($\ge 80.0\%$)
All pull requests and test runs must satisfy two independent coverage gates:
1. **Global Branch Coverage**: $\ge 80.0\%$ across the entire `app/` codebase.
2. **Diff Coverage**: $\ge 80.0\%$ branch coverage on modified lines compared against `origin/main`.

### Cognitive Complexity Budget ($\le 15$)
All test and production functions must respect a cognitive complexity budget $\le 15$ measured via Complexipy.

### Google-Style Documentation Mandate
Every test module, class, and test function must include Google-style docstrings declaring the specific invariant under test, formulas, and arguments.

---

## 7. Common Developer Recipes & Command Reference

| Goal | Command / Recipe | Environment & Flags |
| :--- | :--- | :--- |
| **Run Full Test Suite** | `pixi run test` | Standard pytest with benchmarks enabled |
| **Full Coverage Pass** | `NUMBA_DISABLE_JIT=1 pixi run pytest --cov=app --cov-fail-under=80` | Disables JIT for 100% Python branch tracing |
| **Scientific Invariants** | `pixi run test-scientific` | Runs `-m scientific_invariant` with `--no-cov` |
| **JIT Parity Checks** | `pixi run test-parity` | Runs `-m jit_parity` with compiled Numba kernels |
| **Data-Flow Matrix Audit** | `pixi run audit-matrix` | Verifies OKF coverage across scientific concepts |
| **Table-to-Trace Parity** | `pixi run verify-matrix` | Asserts 1:1 numerical parity against doc tables |
| **Performance Benchmarks** | `pixi run benchmark` | Runs latency micro-benchmarks via pytest-benchmark |
| **Full Pre-Commit Suite** | `pixi run pre-commit run --all-files` | Executes all pre-commit quality gates |
