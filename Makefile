# Sweef Browser Makefile
# Commands for building, testing, and running Sweef Browser

.PHONY: help build test run clean docker docker-build docker-run

# Default target
help:
	@echo "Sweef Browser - Ultra-lightweight browser for AI agents and humans"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  build          - Build the core engine"
	@echo "  test          - Run tests"
	@echo "  run           - Run the browser"
	@echo "  run-headless  - Run in headless mode"
	@echo "  run-gui       - Run with GUI"
	@echo "  run-mcp       - Run MCP server for AI agents"
	@echo "  run-repl      - Run interactive REPL"
	@echo "  clean         - Clean build artifacts"
	@echo "  docker        - Build Docker image"
	@echo "  docker-run    - Run in Docker container"
	@echo ""

# Build the core engine
build:
	cd core && zig build -Doptimize=ReleaseSafe

# Run tests
test:
	cd core && zig build test

# Run the browser
run:
	cd core && zig build run

# Run in headless mode
run-headless:
	cd core && zig build run -- --headless

# Run with GUI
run-gui:
	cd core && zig build run -- --gui

# Run MCP server
run-mcp:
	cd core && zig build run -- --headless --mcp

# Run REPL
run-repl:
	cd core && zig build run -- --repl

# Clean build artifacts
clean:
	cd core && rm -rf zig-out zig-cache
	find . -name "*.o" -delete
	find . -name "sweef" -type f -delete

# Build Docker image
docker:
	docker build -t sweef-browser .

# Run in Docker
docker-run:
	docker run -it --rm sweef-browser

# Install Node.js SDK
install-nodejs:
	cd sdks/nodejs && npm install

# Install Python SDK
install-python:
	cd sdks/python && pip install -e .
