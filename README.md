# Toporic

A universal agent harness for AI-assisted software engineering, running entirely in your terminal.

## Installation

### Official (recommended)

```bash
curl -fsSL https://toporic.com/code/tui/install.sh | sh
```

### GitHub alternative

```bash
curl -fsSL https://raw.githubusercontent.com/ToporicAI/toporic-code/main/install.sh | sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/ToporicAI/toporic-code/main/install.ps1 | iex
```

### Manual

Download the binary for your platform from the [latest release](https://github.com/ToporicAI/toporic-code/releases/latest), extract it, and place it in your `PATH`.

## Quick Start

```bash
# Set your API key (e.g., DeepSeek, Anthropic, OpenAI)
toporic set-key --provider deepseek --key sk-...

# Start coding
toporic --mode coding
```

### Modes

| Mode | Description |
|---|---|
| `--mode coding` | Code with full workspace context (repo map + RAG) |
| `--mode assistant` | General AI assistant |
| `--mode research` | Research mode |

### Provider Support

Anthropic, OpenAI, DeepSeek, OpenRouter, Ollama, Groq, Together, Perplexity, Mistral, Cerebras, Fireworks, MiniMax, Kimi, Qwen, plus custom OpenAI-compatible providers.

## Configuration

Config lives at `~/.toporic/config.json`. Run `toporic init` to scaffold a project workspace.

## Updating

```bash
toporic --version    # Check current version and see update instructions
```

Or re-run the install script — it replaces the existing binary in place.
