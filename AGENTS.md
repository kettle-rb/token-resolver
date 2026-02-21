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

## Key Design Decisions

1. **Grammar never fails** — Any input is valid. Unrecognized content becomes text nodes.
2. **Single-pass resolution** — Replacement values are NOT re-scanned for tokens.
3. **Config is frozen and hashable** — Grammar classes are cached per config.
4. **Fast-path** — If input doesn't contain the `pre` delimiter, no parslet invocation.

## Running Tests

```bash
bundle exec rspec
```

## Critical AI Agent Terminal Limitations

**IMPORTANT**: AI agents (Copilot, etc.) almost never can see terminal output from `run_in_terminal`.

**Workarounds:**
1. **ALWAYS redirect output to a file** in the project's local `tmp/` directory, then read it back:
   ```bash
   bundle exec rspec 2>&1 > tmp/rspec-output.txt
   ```
   Then use `read_file` tool on `tmp/rspec-output.txt`.

2. **NEVER chain `cd` with other commands via `&&`** — `direnv` won't initialize until after
   all commands finish. Run `cd` alone first, then run subsequent commands separately.

3. **NEVER use `head`, `tail`, or any output truncation** with test commands.

4. **Use internal tools** (`grep_search`, `read_file`, `list_dir`) instead of terminal for
   information gathering whenever possible.

## API Conventions

- All constructors accept `**options` for forward compatibility where appropriate
- `Token::Resolver.parse(input, config:)` → `Document`
- `Token::Resolver.resolve(input, replacements, config:, on_missing:)` → `String`
