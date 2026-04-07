# Changelog

[![SemVer 2.0.0][📌semver-img]][📌semver] [![Keep-A-Changelog 1.0.0][📗keep-changelog-img]][📗keep-changelog]

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][📗keep-changelog],
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
and [yes][📌major-versions-not-sacred], platform and engine support are part of the [public API][📌semver-breaking].
Please file a bug if you notice a violation of semantic versioning.

[📌semver]: https://semver.org/spec/v2.0.0.html
[📌semver-img]: https://img.shields.io/badge/semver-2.0.0-FFDD67.svg?style=flat
[📌semver-breaking]: https://github.com/semver/semver/issues/716#issuecomment-869336139
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat

## [Unreleased]

### Added

- **New CI workflows** — Expanded Ruby/engine matrix coverage:
  - `jruby.yml` — JRuby CI workflow
  - `ruby-3.4.yml` — Ruby 3.4 CI workflow
  - `templating.yml` — Templating CI workflow
  - `truffleruby-23.1.yml`, `truffleruby-23.2.yml`, `truffleruby-24.2.yml`, `truffleruby-25.0.yml` — TruffleRuby version-pinned CI workflows
  - Renamed `legacy.yml` → `ruby-3.2.yml` and `supported.yml` → `ruby-3.3.yml` for consistency
- **Dev binaries** — New developer/tooling scripts in `bin/`: `ast-merge-recipe`, `kettle-gh-release`, `kettle-jem`, `print_matches`, `rbts`, `unparser`
- **Modular gemfiles** — Added `coverage_local.gemfile`, `style_local.gemfile`, `templating.gemfile`, `templating_local.gemfile`, and recording gemfiles for local-path sibling gem development
- **Dev container setup** — Added `devcontainer/scripts/setup-tree-sitter.sh` for Tree-sitter native library installation
- **mise environment management** — Added `mise.toml` for ENV-driven local development configuration; migrated from `.envrc`-only approach to mise + dotenvy
- **Template freeze markers** — Added `kettle-jem:freeze` / `kettle-jem:unfreeze` markers in `token-resolver.gemspec` to preserve custom sections across template runs
- **`.gemrc`** — Added project-level gem configuration file
- **`.rubocop_rspec.yml`** — Added RSpec-specific RuboCop configuration
- **GitHub Copilot instructions** — Added `.github/COPILOT_INSTRUCTIONS.md`
- **AGPL-3.0-only license text** — Added `AGPL-3.0-only.md`

### Changed

- **BREAKING: License changed from MIT to AGPL-3.0-only** — `spec.licenses` updated in gemspec; license file updated accordingly
- **`kettle-dev`** development dependency bumped from `~> 1.2` to `~> 2.0`
- **`bundler-audit`** development dependency bumped from `~> 0.9.2` to `~> 0.9.3`
- **`appraisal2`** version constraint loosened from `~> 3.0, ~> 3.0.6` to `~> 3.0, >= 3.0.6`
- **Local dev wiring** — Switched from ad hoc monorepo paths to `nomono` Gemfile macros for sibling gem resolution in `style.gemfile` and related local gemfiles
- **Template dependency** — Updated from `jsonc-merge` to `json-merge` in `templating_local.gemfile`
- **Gemspec `homepage_uri`** — Hardcoded to `https://token-resolver.galtzo.com/` (was dynamically constructed with `tr`)
- **Skip unresolved-token scan for gemspec** — Added `.kettle-jem.yml` config to exclude `token-resolver.gemspec` from the token scan
- **CI: `codecov/codecov-action`** bumped from v5 to v6
- **CI: `marocchino/sticky-pull-request-comment`** bumped from v2 to v3
- **CI: `addressable`** (transitive dependency) bumped from 2.8.8 to 2.8.9
- **CI: `json`** (bundler group) bumped from 2.18.1 to 2.19.2
- **Dev container** — Updated `devcontainer.json` and `apt-install` scripts with improved tooling setup

### Deprecated

### Removed

- **`LICENSE.txt`** — Replaced by `LICENSE.md` (reformatted) and `AGPL-3.0-only.md`
- **Previous non-AGPL license files** — `Big-Time-Public-License.md` and `PolyForm-Small-Business-1.0.0.md` removed (then re-added by subsequent template pass; see Added)

### Fixed

- **Typos** — Minor documentation/comment typo corrections in `BENCHMARK.md` and IDE configuration

### Security

- **`bundler-audit` ~> 0.9.3`** — Picked up latest security-advisory database and patch-level fixes

## [1.0.2] - 2026-02-22

- TAG: [v1.0.2][1.0.2t]
- COVERAGE: 98.13% -- 263/268 lines in 10 files
- BRANCH COVERAGE: 91.18% -- 62/68 branches in 10 files
- 96.77% documented

### Added

- **Benchmarking tools** — Performance comparison suite comparing `token-resolver` against simpler
  alternatives (`String#gsub` and `Kernel#sprintf`):
  - `benchmarks/comparison.rb` — Comprehensive benchmark script measuring iterations per second
    across four realistic scenarios (simple replacement, moderate complexity, high complexity,
    and large documents with sparse tokens)
  - `gemfiles/modular/benchmark/ips.gemfile` — Development dependency for `benchmark-ips` gem
  - Rake tasks: `rake bench:comparison` (run comparison), `rake bench:list` (list benchmarks),
    `rake bench:run` (run all benchmarks), `rake bench` (alias)
  - `BENCHMARK.md` — Results and analysis showing token-resolver is 100-3000x slower due to
    PEG parsing, validation, and AST building; includes guidance on when to use each approach
    and real-world performance context

## [1.0.1] - 2026-02-22

- TAG: [v1.0.1][1.0.1t]
- COVERAGE: 98.13% -- 263/268 lines in 10 files
- BRANCH COVERAGE: 91.18% -- 62/68 branches in 10 files
- 96.77% documented

### Added

- `Config#segment_pattern` option — a parslet character class constraining which characters
  are valid inside token segments (default: `"[A-Za-z0-9_]"`). This prevents false positive
  token matches against Ruby block parameters (`{ |x| expr }`), shell variable expansion
  (`${VAR:+val}`), and other syntax that structurally resembles tokens but contains spaces
  or punctuation in the "segments".
- `Resolve#resolve` now validates replacement keys against the config's `segment_pattern` and
  raises `ArgumentError` if a key contains characters that the grammar would never parse.

### Fixed

- **False positive token matches** — the grammar previously used `any` (match any character)
  for segment content, which allowed spaces, operators, and punctuation inside token segments.
  This caused Ruby block syntax like `{ |fp| File.exist?(fp) }` and shell expansion like
  `${CLASSPATH:+:$CLASSPATH}` to be incorrectly parsed as tokens. With multi-separator configs
  (`["|", ":"]`), the second `|` was reconstructed as `:` during `on_missing: :keep`
  roundtripping, silently corrupting source files. The grammar now uses
  `match(segment_pattern)` instead of `any`, limiting segments to word characters by default.

## [1.0.0] - 2026-02-21

- TAG: [v1.0.0][1.0.0t]
- COVERAGE: 97.67% -- 252/258 lines in 10 files
- BRANCH COVERAGE: 89.39% -- 59/66 branches in 10 files
- 96.72% documented

### Added

- Initial release

### Security

[Unreleased]: https://github.com/kettle-rb/token-resolver/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/kettle-rb/token-resolver/compare/v1.0.1...v1.0.2
[1.0.2t]: https://github.com/kettle-rb/token-resolver/releases/tag/v1.0.2
[1.0.1]: https://github.com/kettle-rb/token-resolver/compare/v1.0.0...v1.0.1
[1.0.1t]: https://github.com/kettle-rb/token-resolver/releases/tag/v1.0.1
[1.0.0]: https://github.com/kettle-rb/ast-merge/compare/e0e299cad6e6914d512845c71df6b7ac8009e5ac...v1.0.0
[1.0.0t]: https://github.com/kettle-rb/ast-merge/tags/v1.0.0
