# List all available recipes categorized by group (Default task)
default:
	@just --list

# Bootstrap the environment (install Pixi dependencies, pre-commit hooks, and VS Code extensions)
[group("setup")]
setup:
	pixi install -e dev
	pixi run --frozen -e dev pre-commit install
	@just install-extensions

# Alias target to run bootstrap setup
[group("setup")]
install:
	@just setup

[group("setup")]
init:
	pixi shell --manifest-path ./pyproject.toml -e dev

# Install the recommended VS Code extensions list
[group("setup")]
install-extensions:
	@jq -r '.recommendations[]' .vscode/extensions.json | while read -r ext; do \
		code --install-extension "$ext"; \
	done

# Run the pytest test suite in the dev environment
[group("testing")]
test:
	pixi run --frozen -e dev pytest

# Run scientific invariant tests (-m scientific_invariant)
[group("testing")]
test-scientific:
	pixi run --frozen -e dev pytest --no-cov -m scientific_invariant

# Run JIT vs pure-Python numerical parity tests (-m jit_parity)
[group("testing")]
test-parity:
	pixi run --frozen -e dev pytest --no-cov -m jit_parity

# Run Zarr replay bit-exactness and deterministic I/O tests
[group("testing")]
test-replay:
	pixi run --frozen -e dev pytest --no-cov tests/e2e/replay_and_io/test_zarr_replay_bit_exactness.py

# Run local CI test orchestration script
[group("testing")]
ci-test:
	./scripts/local_ci.sh tests

# Run mutation testing with Mutmut across core simulation kernels
[group("testing")]
mutate:
	pixi run --frozen -e dev mutmut run

# Run causal Data-Flow Matrix trace tests against markdown doc tables
[group("data-flow-matrix")]
test-matrix:
	pixi run --frozen -e dev pytest --no-cov tests/integration/scientific_invariants/test_causal_data_flow_matrices.py -v

# Audit scientific model docs for Data-Flow Matrix coverage and bilateral links
[group("data-flow-matrix")]
audit-matrix:
	pixi run --frozen -e dev python scripts/audit_matrix_coverage.py

# Verify 1:1 point-by-point numerical parity between doc tables and runtime traces
[group("data-flow-matrix")]
verify-matrix:
	pixi run --frozen -e dev python scripts/verify_matrix_trace_parity.py --all

# Generate interactive OKF knowledge graph visualization (docs/viz.html)
[group("data-flow-matrix")]
visualize-okf:
	pixi run --frozen -e dev python scripts/visualize_okf.py

# Validate Open Knowledge Format (OKF v0.2) frontmatter, paths, and freshness across docs
[group("data-flow-matrix")]
validate-okf:
	pixi run --frozen -e dev python scripts/validate_okf.py

# Run linting checks (Ruff, Mypy) and auto-fix simple styling discrepancies
[group("quality")]
lint:
	pixi run --frozen -e dev ruff check --fix .
	pixi run --frozen -e dev ruff format .
	pixi run --frozen -e dev mypy app/

# Run all pre-commit hooks manually against all files in the repository
[group("quality")]
check:
	pixi run --frozen -e dev pre-commit run --all-files

# Format all code blocks inside the workspace using Ruff formatter
[group("quality")]
format:
	pixi run --frozen -e dev ruff format .

# Run cognitive complexity analysis with Complexipy across the repository
[group("quality")]
complexity:
	pixi run --frozen -e dev complexipy . --failed

# Run local cognitive complexity analysis with Complexipy
[group("quality")]
complexity-local:
	pixi run --frozen -e dev complexipy . --failed

# Run CI cognitive complexity analysis with Complexipy
[group("quality")]
complexity-ci:
	pixi run --frozen -e dev complexipy . --failed

# Start Streamlit frontend
[group("app")]
run:
	pixi run --frozen -e dev ui

# Start the background Redis coordination server via Docker
[group("app")]
start-redis:
	docker run -d --name macro-redis -p 6379:6379 redis:7-alpine

# Run the macro simulation environment
# Example: just run-simulation ticks=500
[group("app")]
run-simulation *args:
	pixi run --frozen -e dev python -m app.main simulate {{args}}

# Evaluate the final simulation PPO policies against the LLM traces
[group("app")]
evaluate-policy:
	pixi run --frozen -e dev python scripts/evaluate.py --policy ppo

# Log in to Hugging Face Hub
[group("app")]
hf-login:
	#!/usr/bin/env bash
	token=$(secret-tool lookup Title "[HuggingFace Access Token] [write] workspace-upload" 2>/dev/null)
	if [ -n "$token" ]; then
		echo "Token successfully retrieved from KeePassXC Secret Service."
		pixi run --frozen -e dev hf auth login --token "$token"
	else
		echo "Could not find token in KeePassXC Secret Service. Falling back to interactive prompt..."
		pixi run --frozen -e dev hf auth login
	fi

# Build the documentation site statically using Zensical
[group("docs")]
docs:
	pixi run --frozen -e dev zensical build

# Build and serve the Zensical documentation website locally on http://localhost:9000
[group("docs")]
serve:
	pixi run --frozen -e dev zensical build
	pixi run --frozen -e dev zensical serve -a localhost:9000

# Start a local JupyterLab server inside the dev environment
[group("utils")]
lab:
	pixi run --frozen -e dev jupyter lab --ip=127.0.0.1 --port=8888

# Clean all temporary files, cache folders, compilation files, and local environments
[group("utils")]
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf .cache site build dist .pytest_cache .mypy_cache .ruff_cache .hypothesis .coverage htmlcov .pixi
	@just clean-notebooks

# Clean Jupyter notebook checkpoint caches under the notebooks directory
[group("utils")]
clean-notebooks:
	find notebooks/ -type d -name ".ipynb_checkpoints" -exec rm -rf {} +

# Run the CI pipeline locally using GitHub 'act' tool
[group("utils")]
act-ci:
	act -W .github/workflows/ci.yml

# Run cognitive complexity GitHub Actions workflow locally via act
[group("utils")]
act-complexity:
	act -j cognitive-complexity
