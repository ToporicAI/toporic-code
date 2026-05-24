# Toporic

An AI agent harness for your terminal — built for coding, research, and automation.

> **This repository is the official distribution point for pre-built Toporic binaries.**
> Source code is not published here.

---

## Installation

### macOS & Linux

```sh
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/toporic-code/main/install.sh | sh
```

To install a specific version:

```sh
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/toporic-code/main/install.sh | sh -s -- --version 1.2.3
```

To install to a custom directory:

```sh
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/toporic-code/main/install.sh | sh -s -- --install-dir /usr/local/bin
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/YOUR_ORG/toporic-code/main/install.ps1 | iex
```

To install a specific version:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/YOUR_ORG/toporic-code/main/install.ps1))) -Version 1.2.3
```

### Manual download

Download the binary for your platform from the [Releases](../../releases) page and place it in a directory on your `PATH`.

| Platform | File |
|---|---|
| macOS Intel | `toporic-vX.Y.Z-x86_64-apple-darwin.tar.gz` |
| macOS Apple Silicon | `toporic-vX.Y.Z-aarch64-apple-darwin.tar.gz` |
| Linux x86_64 | `toporic-vX.Y.Z-x86_64-unknown-linux-gnu.tar.gz` |
| Linux arm64 | `toporic-vX.Y.Z-aarch64-unknown-linux-gnu.tar.gz` |
| Windows x86_64 | `toporic-vX.Y.Z-x86_64-pc-windows-msvc.zip` |

Each release also includes a `sha256sums.txt` for verification.

---

## Quick start

```sh
# Set your API key (Anthropic by default)
toporic set-key --provider anthropic --key sk-ant-...

# Start the TUI
toporic

# Coding mode (default) — full FS + shell tools
toporic --mode coding

# Research mode — web tools, no FS writes
toporic --mode research

# Plan mode — read-only, generates a task breakdown
toporic plan "Refactor the auth module to use JWTs"
```

---

## Supported providers

| Provider | Env var |
|---|---|
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| DeepSeek | `DEEPSEEK_API_KEY` |
| OpenRouter | `OPENROUTER_API_KEY` |
| Groq | `GROQ_API_KEY` |
| Mistral | `MISTRAL_API_KEY` |
| Perplexity | `PERPLEXITY_API_KEY` |
| Together | `TOGETHER_API_KEY` |
| Fireworks | `FIREWORKS_API_KEY` |
| Cerebras | `CEREBRAS_API_KEY` |
| MiniMax | `MINIMAX_API_KEY` |
| Kimi | `KIMI_API_KEY` |
| Qwen | `QWEN_API_KEY` |
| Ollama | _(local, no key needed)_ |

---

## Updating

The binary checks for updates automatically on each run. To update manually, re-run the install script — it will replace the existing binary in place.

---

## Uninstall

**macOS / Linux:**

```sh
rm "$(which toporic)"
```

**Windows:**

```powershell
Remove-Item "$env:LOCALAPPDATA\toporic\bin\toporic.exe"
```

---

## License

Toporic is proprietary software. All rights reserved.
