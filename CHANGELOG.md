# Changelog

All notable changes to Toporic are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

---

## [0.1.0] - 2026-05-24

### Added

- Initial release of Toporic — AI agent harness for the terminal
- ReAct loop with PLAN / AUTO / BUILD modes
- 14 LLM providers: Anthropic, OpenAI, DeepSeek, OpenRouter, Groq, Mistral, Perplexity, Together, Fireworks, Cerebras, MiniMax, Kimi, Qwen, Ollama
- Full Ratatui TUI with amber, purple, and green themes
- Coding mode: FS tools, shell tools, tree-sitter AST search, LSP integration
- Research mode: web search and fetch tools
- RAG context (repo map by default, full semantic RAG opt-in)
- MCP (Model Context Protocol) server support via `rmcp`
- Skill system for project-local agent instructions
- Session persistence (SQLite) with resume support
- `toporic plan` subcommand for non-interactive goal decomposition
- `toporic serve` HTTP/SSE API mode
- Binary update check against `version.json`

[Unreleased]: https://github.com/ToporicAI/toporic-code/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ToporicAI/toporic-code/releases/tag/v0.1.0
