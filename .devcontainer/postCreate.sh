#!/usr/bin/env bash
set -euo pipefail

npm config set prefix "$HOME/.npm-global"
npm install -g eslint prettier @openai/codex @anthropic-ai/claude-code
pip install --user ruff black

mkdir -p "$HOME/bin"


echo 'export PATH="$PATH:$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.dotnet/tools:$HOME/bin"' >>"$HOME/.bashrc"

# Pre-cache drawio-mcp for faster first use
npx -y drawio-mcp --help 2>/dev/null || true

# Pre-cache Playwright MCP for faster first use
npx -y @playwright/mcp@latest --help 2>/dev/null || true
