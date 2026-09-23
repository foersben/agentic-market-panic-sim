# List all available recipes in the Justfile (Default task)
default:
	@just --list

# Bootstrap the environment (install Pixi dependencies, pre-commit hooks, and VS Code extensions)
setup:
	pixi install -e dev
	pixi run --frozen -e dev pre-commit install
	@just install-extensions

# Alias target to run bootstrap setup
install:
	@just setup

init:
	pixi shell --manifest-path ./pyproject.toml -e dev

# Run the pytest test suite in the dev environment
test:
	pixi run --frozen -e dev pytest

# Run linting checks (Ruff, Mypy) and auto-fix simple styling discrepancies
lint:
	pixi run --frozen -e dev ruff check --fix .
	pixi run --frozen -e dev ruff format .
	pixi run --frozen -e dev mypy app/

# Run all pre-commit hooks manually against all files in the repository
check:
	pixi run --frozen -e dev pre-commit run --all-files

# Format all code blocks inside the workspace using Ruff formatter
format:
	pixi run --frozen -e dev ruff format .

# Start Streamlit frontend
run:
	pixi run --frozen -e dev ui


# Clean all temporary files, cache folders, compilation files, and local environments
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf .cache site build dist .pytest_cache .mypy_cache .ruff_cache .hypothesis .coverage htmlcov .pixi
	@just clean-notebooks

# Build the documentation site statically using Zensical
docs:
	pixi run --frozen -e dev zensical build

# Build and serve the Zensical documentation website locally on http://localhost:9000
serve:
	pixi run --frozen -e dev zensical build
	pixi run --frozen -e dev zensical serve -a localhost:9000

# Start a local JupyterLab server inside the dev environment
lab:
	pixi run --frozen -e dev jupyter lab --ip=127.0.0.1 --port=8888
# Start the background Redis coordination server via Docker
start-redis:
	docker run -d --name macro-redis -p 6379:6379 redis:7-alpine

# Run the macro simulation environment
# Example: just run-simulation ticks=500
run-simulation *args:
	pixi run --frozen -e dev python -m app.main simulate {{args}}

# Evaluate the final simulation PPO policies against the LLM traces
evaluate-policy:
	pixi run --frozen -e dev python scripts/evaluate.py --policy ppo

# Log in to Hugging Face Hub (queries KeePassXC Secret Service via D-Bus, falls back to interactive prompt)
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


# Clean Jupyter notebook checkpoint caches under the notebooks directory
clean-notebooks:
	find notebooks/ -type d -name ".ipynb_checkpoints" -exec rm -rf {} +

# Run cognitive complexity analysis with Complexipy across the repository
complexity:
	uvx complexipy . --failed

# Run local cognitive complexity analysis with Complexipy
complexity-local:
	uvx complexipy . --failed

# Run CI cognitive complexity analysis with Complexipy
complexity-ci:
	uvx complexipy . --failed

# Run the CI pipeline locally using GitHub 'act' tool
act-ci:
	act -W .github/workflows/ci.yml

# Run cognitive complexity GitHub Actions workflow locally via act
act-complexity:
	act -j cognitive-complexity

# Install the recommended VS Code extensions list
install-extensions:
	@jq -r '.recommendations[]' .vscode/extensions.json | while read -r ext; do \
		code --install-extension "$ext"; \
	done
