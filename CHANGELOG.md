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

### Changed

### Deprecated

### Removed

### Fixed

### Security

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
