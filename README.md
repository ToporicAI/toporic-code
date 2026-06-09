# Toporic

A terminal-native AI agent harness for software engineering. Toporic works with your
filesystem, shell, and the web — backed by 14+ LLM providers. It runs entirely in your
terminal with a full TUI (text user interface).


---

## Installation

### macOS & Linux

```bash
curl -fsSL https://toporic.com/code/tui/install.sh | sh
```

Or from GitHub directly:

```bash
curl -fsSL https://raw.githubusercontent.com/ToporicAI/toporic-code/main/install.sh | sh
```

### Windows

```powershell
irm https://raw.githubusercontent.com/ToporicAI/toporic-code/main/install.ps1 | iex
```

> **Prerequisites:** The coding mode's `search_files` tool uses [ripgrep](https://github.com/BurntSushi/ripgrep).
> Install it via your package manager: `brew install ripgrep`, `apt install ripgrep`, etc.

### Manual download

Download the binary for your platform from the [latest release](https://github.com/ToporicAI/toporic-code/releases/latest),
extract it, and place it in your `PATH`.

### Supported platforms

| OS      | Architecture    |
|---------|----------------|
| macOS   | Intel (x86_64), Apple Silicon (aarch64) |
| Linux   | x86_64, aarch64 |
| Windows | x86_64          |

---

## Quick Start

```bash
# 1. Save your API key (DeepSeek, Anthropic, OpenAI, etc.)
toporic set-key --provider deepseek --key sk-...

# 2. Start coding — Toporic detects your workspace automatically
toporic --mode coding
```

On first run, the TUI opens in your current directory. The agent sees your files,
git state, and project structure. Type a prompt and press Enter.

Need help? Press `?` anytime for keybindings, or type `/help` in the input box.

---

## What Can Toporic Do?

- **Read, write, and edit files** — full filesystem access sandboxed to your workspace
- **Run shell commands** — with safe execution (allowlisting, sandboxing, timeouts)
- **Search your codebase** — ripgrep-powered search with pattern matching
- **Browse the web** — fetch URLs, search the web, call REST APIs
- **Git awareness** — sees current diff, staged changes, and branch state
- **Multi-agent orchestration** — complex tasks (refactors, migrations) are automatically
  decomposed and executed by up to 8 parallel specialized workers
- **Session persistence** — every conversation is saved; resume any session anytime
- **Automatic strategy selection** — Toporic picks the optimal execution mode
  (single agent, sequential DAG, or parallel workers) based on task complexity

---

## Modes

| Mode                 | Description |
|----------------------|-------------|
| `--mode coding`      | Full workspace context — filesystem, shell, web, git, 20+ tools. Code-aware with repo maps and RAG context. |
| `--mode assistant`   | Pure conversation. No tools or filesystem access. Ideal for Q&A, brainstorming, and writing help. |
| `--mode research`    | Web research agent. Search, fetch pages, call APIs. No filesystem access. |

---

## The TUI

Toporic's terminal interface is built with Ratatui. Key concepts:

```
┌─ toporic ──── ⣾ Thinking… ─────────────────── [END] ─┐
│ ┌ Sidebar ────┐ ┌ Chat ──────────────────────────── │
│ │ project:main │ │ You: Write a function that sums…  │
│ │              │ │                                   │
│ │ Messages     │ │ ▸ write_file(src/sum.rs)    ✓     │
│ │ Files        │ │                                   │
│ │   src/       │ │ Assistant: Here's the function…   │
├─┴──────────────┴─┴──────────────────────────────────┤
│ > Write a Rust function that reads a CSV…            │
├─ 3 msgs ─────── ?help │ Ctrl+B sidebar │ /quit ──────┤
└──────────────────────────────────────────────────────┘
```

### Keybindings

| Key          | Action                         |
|-------------|--------------------------------|
| `Enter`      | Submit message                 |
| `Shift+Enter`| Insert newline (multiline)     |
| `Ctrl+B`     | Toggle sidebar                 |
| `Ctrl+P`     | Open command palette           |
| `?`          | Open help overlay              |
| `Tab`        | Cycle focus (input / messages) |
| `PageUp/Down`| Scroll chat history            |
| `/quit`      | Exit Toporic                   |

### Special commands (type in the input box)

| Command        | Description |
|---------------|-------------|
| `/init`        | Initialize workspace (creates `.toporic/` and `AGENTS.md`) |
| `/resume`      | Resume interrupted multi-worker execution from checkpoint |
| `/skill <name>`| Load a skill for the current turn |
| `/session new` | Start a new session |
| `/help`        | Show keybinding reference |
| `/diag`        | Show diagnostic logs |

### Confirmation

Before executing mutating operations (write, edit, delete, run commands), Toporic
shows a confirmation popup. Press `Y` to allow, `N` or `Enter` to reject.

Skip prompts with `--auto-approve`:

```bash
toporic --mode coding --auto-approve
```

---

## Provider Support

14+ built-in providers. Keys are stored in `~/.toporic/config.json` with permissions `600`.

| Provider     | Set up                                           |
|-------------|--------------------------------------------------|
| Anthropic    | `toporic set-key --provider anthropic --key sk-ant-...` |
| OpenAI       | `toporic set-key --provider openai --key sk-...` |
| DeepSeek     | `toporic set-key --provider deepseek --key sk-...` |
| OpenRouter   | `toporic set-key --provider openrouter --key sk-or-...` |
| Ollama (local)| No key needed — just run `ollama serve`          |
| Groq, Together, Perplexity, Mistral, Cerebras, Fireworks, MiniMax, Kimi, Alibaba | Same pattern with the provider name |

Change provider or model anytime via `Ctrl+P` (command palette), CLI flags, or the config file.

```bash
toporic --provider ollama --model codellama
toporic --provider openai --model gpt-4o-mini
```

For custom OpenAI-compatible endpoints, set `provider_urls` in `~/.toporic/config.json`:

```json
{
  "provider_urls": {
    "deepseek": "http://localhost:7897",
    "openai": "https://gateway.example.com/v1"
  }
}
```

---

## Configuration

Config file lives at `~/.toporic/config.json`. Scaffold a project workspace with:

```bash
toporic init
```

This creates `.toporic/` in your project directory with local configuration, task
tracking, skills, and checkpoints.

### Configuration structure

```json
{
  "defaults": {
    "provider": "anthropic",
    "model": "claude-sonnet-4-20250514"
  },
  "providers": {
    "anthropic": "sk-ant-...",
    "deepseek": "sk-..."
  },
  "permissions": {
    "mode": "prompt"
  },
  "context": {
    "rag_enabled": true,
    "max_repo_map_tokens": 8000
  }
}
```

See the full [User Guide](https://toporic.com) for every config option.

---

## Sessions & Resume

Every interaction is saved to `~/.toporic/sessions/<mode>/<uuid>.jsonl`. You can
resume any session:

```bash
toporic --resume                      # latest session
toporic --resume <session-uuid>       # specific session
```

For complex multi-worker tasks, progress is automatically checkpointed to
`.toporic/checkpoints/current.json`. If interrupted (Ctrl+C, network failure),
resume with `/resume` in the TUI.

---

## Security

- **Sandboxed filesystem** — all paths validated against the workspace root. Symlink escapes
  and `..` traversal are blocked.
- **Shell safety** — commands go through allowlist validation, metacharacter rejection, env
  sanitization, sandbox enforcement, concurrency control, and per-command timeouts.
- **SSRF protection** — URL fetching rejects private, loopback, link-local, and IMDS IPs.
- **No keys in process args** — API keys come from environment variables or config file only.
  No `--api-key` flag.
- **Local key storage** — keys in `~/.toporic/config.json` are stored with file permissions `600`.

---

## Updating

```bash
toporic --version    # Check current version
```

Re-run the install script — it replaces the existing binary in place. Or download
the latest release from the [releases page](https://github.com/ToporicAI/toporic-code/releases).

---

## Documentation

- **[User Guide](https://toporic.com)** — full end-user documentation:
  installation, setup, TUI keybindings, all tools with parameters, session management,
  configuration reference, skills, and troubleshooting
