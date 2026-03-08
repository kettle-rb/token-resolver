# AI Agent Instructions for token-resolver

## Project Overview

token-resolver is a standalone Ruby gem that provides configurable PEG-based (parslet) token
parsing and resolution. It detects structured tokens like `{KJ|GEM_NAME}` in arbitrary text
and resolves them against a replacement map.

**This is NOT a `*-merge` family gem.** It depends only on `parslet` and `version_gem`.
It has no dependency on `ast-merge`, `tree_haver`, or any merge infrastructure.

## Directory Structure

```
lib/token/resolver/
├── config.rb       — Config value object (token structure definition)
├── document.rb     — Public API: parses input, exposes nodes
├── grammar.rb      — Dynamically builds Parslet::Parser from Config
├── node.rb         — Autoloads for Node namespace
├── node/
│   ├── text.rb     — Plain text node
│   └── token.rb    — Token node with segments
├── resolve.rb      — Replaces tokens with values from a map
├── transform.rb    — Converts parslet output to node objects
└── version.rb      — Version information
```

## Running Tests

```bash
mise exec -C /home/pboling/src/kettle-rb/ast-merge/vendor/token-resolver -- bundle exec rspec
```

## Critical AI Agent Terminal Guidance

### Terminal Output Is Available, but Each Command Is Isolated

**IMPORTANT**: AI agents can reliably read terminal output when commands run in the background and the output is polled afterward. However, every terminal command should be treated as a fresh shell with no shared state.

### Use `mise` for Project Environment

**IMPORTANT**: The canonical project environment now lives in `mise.toml`, with local overrides in `.env.local` loaded via `dotenvy`.

✅ **CORRECT**:
```bash
mise exec -C /home/pboling/src/kettle-rb/ast-merge/vendor/token-resolver -- bundle exec rspec
```

✅ **CORRECT**:
```bash
eval "$(mise env -C /home/pboling/src/kettle-rb/ast-merge/vendor/token-resolver -s bash)" && bundle exec rspec
```

❌ **WRONG**:
```bash
cd /home/pboling/src/kettle-rb/ast-merge/vendor/token-resolver
bundle exec rspec
```

❌ **WRONG**:
```bash
cd /home/pboling/src/kettle-rb/ast-merge/vendor/token-resolver && bundle exec rspec
```

### Additional Rules

1. **NEVER use `head`, `tail`, or any output truncation** with test commands.
2. **Use internal tools** (`grep_search`, `read_file`, `list_dir`) instead of terminal for
   information gathering whenever possible.
3. **Do NOT rely on prior shell state** — Previous `cd`, `export`, aliases, and functions are not available to the next command.

## API Conventions

- All constructors accept `**options` for forward compatibility where appropriate
- `Token::Resolver.parse(input, config:)` → `Document`
- `Token::Resolver.resolve(input, replacements, config:, on_missing:)` → `String`
