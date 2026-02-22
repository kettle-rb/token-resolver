# Token-Resolver Benchmark Results

⚠️ **IMPORTANT**: This is NOT an apples-to-apples performance comparison.

These three approaches solve different problems with different levels of functionality.
The performance differences reflect this - token-resolver does more work than the alternatives.

## What This Benchmark Measures

This benchmark compares three approaches to token/template replacement:

1. **token-resolver**:
   - Full PEG parsing of input string
   - Token validation (format, segment count)
   - Returns parsed document with nodes for introspection
   - Configurable token structure
   - Error handling for missing tokens

2. **String#gsub**:
   - Simple regex pattern matching
   - Fixed token format
   - No parsing or validation
   - No introspection capabilities

3. **Kernel#sprintf**:
   - Positional format string substitution
   - Pre-determined template structure
   - No runtime token discovery
   - Not suitable for variable/unknown tokens

## Methodology

Each scenario runs for 5 seconds with 2 seconds warmup using `benchmark-ips`.

**Why the large performance difference?**

Token-resolver is significantly slower because it:
- Parses the entire input string using a PEG parser (Parslet gem)
- Builds an AST of Text and Token nodes
- Validates token structure against configuration
- Allocates more objects than simple regex substitution

In contrast, `String#gsub` just does a simple regex replacement with minimal allocations.

## Test Environment

- **Ruby Version**: 4.0.1
- **Platform**: x86_64-linux
- **Ruby Description**: ruby 4.0.1 (2026-01-13 revision e04267a14b) +PRISM [x86_64-linux]
- **Date**: 2026-02-22 04:17:45 MST

## Results

### 1. Simple Replacement (2 tokens)

**Description**: Basic token replacement in a short string

**Input Size**: 41 bytes | **Token Count**: 2

| Approach | Iterations/Second | Time per Iteration |
|----------|-------------------|-------------------|
| Kernel#sprintf | 991.8k ±1.6% | 1.01µs |
| String#gsub | 163.5k ±1.7% | 6.12µs |
| token-resolver | 523.7 ±2.9% | 1909.53µs |

**Comparison**: `String#gsub` is **312x slower** than `token-resolver`.
**Comparison**: `Kernel#sprintf` is **1894x slower** than `token-resolver`.

### 2. Moderate Complexity (7 tokens)

**Description**: Multiple tokens with repeated keys

**Input Size**: 123 bytes | **Token Count**: 7

| Approach | Iterations/Second | Time per Iteration |
|----------|-------------------|-------------------|
| Kernel#sprintf | 521.8k ±0.6% | 1.92µs |
| String#gsub | 62.4k ±1.2% | 16.03µs |
| token-resolver | 193.2 ±1.6% | 5176.46µs |

**Comparison**: `String#gsub` is **323x slower** than `token-resolver`.
**Comparison**: `Kernel#sprintf` is **2701x slower** than `token-resolver`.

### 3. High Complexity (20 tokens)

**Description**: Large template with many tokens

**Input Size**: 278 bytes | **Token Count**: 22

| Approach | Iterations/Second | Time per Iteration |
|----------|-------------------|-------------------|
| Kernel#sprintf | 197.3k ±2.7% | 5.07µs |
| String#gsub | 18.4k ±1.2% | 54.44µs |
| token-resolver | 85.8 ±1.2% | 11658.8µs |

**Comparison**: `String#gsub` is **214x slower** than `token-resolver`.
**Comparison**: `Kernel#sprintf` is **2301x slower** than `token-resolver`.

### 4. Large Document with Sparse Tokens (5 tokens in 1KB text)

**Description**: Realistic document with occasional token replacement

**Input Size**: 1479 bytes | **Token Count**: 5

| Approach | Iterations/Second | Time per Iteration |
|----------|-------------------|-------------------|
| String#gsub | 67.7k ±2.0% | 14.78µs |
| token-resolver | 20.8 ±0.0% | 48080.19µs |

**Comparison**: `String#gsub` is **3254x slower** than `token-resolver`.

## Analysis & Recommendations

### Understanding the Performance Gap

The 100-3000x performance difference is **not a problem** - it reflects that these
are fundamentally different approaches solving different problems:

**token-resolver is designed for:**
- Applications where token structure may vary
- Scenarios requiring token validation and introspection
- Cases where you need to know which tokens were found before resolving
- Systems with configurable token delimiters/separators
- When you need proper error handling for invalid/missing tokens

**Simple approaches are designed for:**
- Fixed, pre-determined token/template formats
- Raw performance where overhead matters
- Simple, one-shot replacements
- Cases where template format is hardcoded

### When to Use Each Approach

#### Use `token-resolver` when:

- ✅ Token structure is **configurable** (custom delimiters, separators)
- ✅ You need **validation** of token format (min/max segments)
- ✅ You need to **parse and inspect** tokens before resolution
- ✅ You want **flexible error handling** for missing tokens (raise/keep/remove)
- ✅ Token structure may **change across contexts**
- ✅ You value **maintainability** and **clarity** over absolute speed
- ✅ You need **single-pass resolution** (replacement values not re-scanned)

**Example use cases:**
- Template processing pipelines with user-configurable tokens
- ETL systems where token format varies by data source
- Configuration file processing with validation
- Document generation where tokens must be identified and reported

#### Use `String#gsub` when:

- ✅ Token format is **fixed and simple**
- ✅ You don't need **token validation** or introspection
- ✅ You need **maximum performance** for fixed patterns
- ✅ The token pattern **won't change**
- ✅ You're doing **simple, one-shot replacements**

**Example use cases:**
- Simple string templating with fixed patterns
- Log message formatting
- Quick text substitutions

#### Use `Kernel#sprintf` when:

- ✅ Tokens are **positional** rather than named
- ✅ Template structure is **completely fixed**
- ✅ You need **formatting options** (padding, precision, etc.)
- ✅ You want the **fastest possible string formatting**

**Example use cases:**
- printf-style formatting
- Fixed output formatting
- Performance-critical string building

## Conclusion

Token-resolver is **significantly slower** than simple alternatives because it does
significantly more work: parsing, validation, introspection, and flexible error handling.

This is a **feature, not a bug**. The performance cost is worth paying when you need
the flexibility and robustness that token-resolver provides.

Choose based on your actual requirements:
- Need flexibility and validation? → **token-resolver** ✅
- Need speed and have fixed patterns? → **String#gsub** ✅
- Need positional formatting? → **Kernel#sprintf** ✅

---

*Benchmark generated on 2026-02-22 04:17:45 MST*

To regenerate this benchmark:

```bash
bundle exec rake bench:comparison
# or
bundle exec ruby benchmarks/comparison.rb
```
