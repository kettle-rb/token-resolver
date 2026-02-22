# frozen_string_literal: true

# Benchmark token-resolver against simpler Ruby string templating approaches
# Run with: bundle exec ruby benchmarks/comparison.rb

require "bundler/setup"
require "benchmark/ips"
require "token/resolver"
require "stringio"

module Benchmarks
  class Comparison
    attr_reader :results, :scenarios

    def initialize
      @results = []
      @scenarios = build_scenarios
      @machine_info = gather_machine_info
    end

    # Run all benchmarks and return results hash
    def run
      puts "=" * 80
      puts "Token Resolver Benchmark Comparison"
      puts "=" * 80
      puts ""
      puts "Ruby Version: #{RUBY_VERSION}"
      puts "Platform: #{RUBY_PLATFORM}"
      puts "Date: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
      puts ""
      puts "⚠️  IMPORTANT: This benchmark compares different approaches with different"
      puts "    levels of functionality. Token-resolver does more (validation, introspection)"
      puts "    than simple regex/sprintf, so performance differences are expected."
      puts ""

      @scenarios.each do |scenario|
        puts "\n#{"-" * 80}"
        puts "Scenario: #{scenario[:name]}"
        puts "Description: #{scenario[:description]}"
        puts "-" * 80
        puts ""

        result = run_scenario(scenario)
        @results << result
      end

      self
    end

    # Generate BENCHMARK.md file from results
    def generate_markdown(output_path = "BENCHMARK.md")
      content = build_markdown_content
      File.write(output_path, content)
      puts "\n" + "=" * 80
      puts "Benchmark report written to: #{output_path}"
      puts "=" * 80
    end

    private

    def build_scenarios
      [
        {
          name: "Simple Replacement (2 tokens)",
          description: "Basic token replacement in a short string",
          input: "Hello {KJ|NAME}, welcome to {KJ|PROJECT}!",
          tokens: {
            "KJ|NAME" => "World",
            "KJ|PROJECT" => "token-resolver",
          },
          # For sprintf: convert to positional format
          sprintf_format: "Hello %s, welcome to %s!",
          sprintf_args: ["World", "token-resolver"],
          # For gsub: pattern to match tokens
          gsub_pattern: /\{KJ\|(\w+)}/,
        },
        {
          name: "Moderate Complexity (7 tokens)",
          description: "Multiple tokens with repeated keys",
          input: "Deploy {KJ|GEM_NAME} v{KJ|VERSION} to {KJ|REGISTRY} for {KJ|ORG}. " \
            "Contact {KJ|AUTHOR} at {KJ|EMAIL}. License: {KJ|LICENSE}.",
          tokens: {
            "KJ|GEM_NAME" => "token-resolver",
            "KJ|VERSION" => "1.0.0",
            "KJ|REGISTRY" => "rubygems.org",
            "KJ|ORG" => "kettle-rb",
            "KJ|AUTHOR" => "Peter Boling",
            "KJ|EMAIL" => "floss@galtzo.com",
            "KJ|LICENSE" => "MIT",
          },
          sprintf_format: "Deploy %s v%s to %s for %s. Contact %s at %s. License: %s.",
          sprintf_args: [
            "token-resolver",
            "1.0.0",
            "rubygems.org",
            "kettle-rb",
            "Peter Boling",
            "floss@galtzo.com",
            "MIT",
          ],
          gsub_pattern: /\{KJ\|(\w+)}/,
        },
        {
          name: "High Complexity (20 tokens)",
          description: "Large template with many tokens",
          input: build_complex_input,
          tokens: build_complex_tokens,
          sprintf_format: build_complex_sprintf_format,
          sprintf_args: build_complex_sprintf_args,
          gsub_pattern: /\{KJ\|(\w+)}/,
        },
        {
          name: "Large Document with Sparse Tokens (5 tokens in 1KB text)",
          description: "Realistic document with occasional token replacement",
          input: build_large_document,
          tokens: {
            "KJ|TITLE" => "Token Resolution Performance",
            "KJ|AUTHOR" => "Peter Boling",
            "KJ|DATE" => "2026-02-21",
            "KJ|VERSION" => "1.0.0",
            "KJ|STATUS" => "production-ready",
          },
          sprintf_format: nil, # sprintf not practical for sparse tokens
          sprintf_args: nil,
          gsub_pattern: /\{KJ\|(\w+)}/,
        },
      ]
    end

    def build_complex_input
      tokens_list = %w[
        GEM_NAME
        VERSION
        AUTHOR
        EMAIL
        LICENSE
        ORG
        REPO
        REGISTRY
        LANG
        FRAMEWORK
        DB
        SERVER
        OS
        ARCH
        CPU
        RAM
        DISK
        NET
        ENV
        REGION
        ZONE
        CLUSTER
      ]
      "Project Details: " + tokens_list.map { |t| "{KJ|#{t}}" }.join(", ") + "."
    end

    def build_complex_tokens
      {
        "KJ|GEM_NAME" => "token-resolver",
        "KJ|VERSION" => "1.0.0",
        "KJ|AUTHOR" => "Peter Boling",
        "KJ|EMAIL" => "floss@galtzo.com",
        "KJ|LICENSE" => "MIT",
        "KJ|ORG" => "kettle-rb",
        "KJ|REPO" => "token-resolver",
        "KJ|REGISTRY" => "rubygems.org",
        "KJ|LANG" => "Ruby",
        "KJ|FRAMEWORK" => "Rails",
        "KJ|DB" => "PostgreSQL",
        "KJ|SERVER" => "Puma",
        "KJ|OS" => "Linux",
        "KJ|ARCH" => "x86_64",
        "KJ|CPU" => "Intel Xeon",
        "KJ|RAM" => "32GB",
        "KJ|DISK" => "1TB SSD",
        "KJ|NET" => "10Gbps",
        "KJ|ENV" => "production",
        "KJ|REGION" => "us-east-1",
        "KJ|ZONE" => "us-east-1a",
        "KJ|CLUSTER" => "prod-cluster-1",
      }
    end

    def build_complex_sprintf_format
      "Project Details: %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s."
    end

    def build_complex_sprintf_args
      [
        "token-resolver",
        "1.0.0",
        "Peter Boling",
        "floss@galtzo.com",
        "MIT",
        "kettle-rb",
        "token-resolver",
        "rubygems.org",
        "Ruby",
        "Rails",
        "PostgreSQL",
        "Puma",
        "Linux",
        "x86_64",
        "Intel Xeon",
        "32GB",
        "1TB SSD",
        "10Gbps",
        "production",
        "us-east-1",
        "us-east-1a",
        "prod-cluster-1",
      ]
    end

    def build_large_document
      # Build ~1KB document with sparse tokens
      paragraphs = [
        "# {KJ|TITLE}\n\nBy {KJ|AUTHOR} - {KJ|DATE}\n\n",
        "This document describes the performance characteristics of version {KJ|VERSION} ",
        "of the token-resolver gem. ",
        "The system is currently {KJ|STATUS} and ready for deployment.\n\n",
        "## Background\n\n",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 5,
        "\n\n## Implementation Details\n\n",
        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. " * 5,
        "\n\n## Performance Considerations\n\n",
        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. " * 5,
        "\n\n## Conclusion\n\n",
        "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum. " * 3,
      ]
      paragraphs.join("")
    end

    def run_scenario(scenario)
      input = scenario[:input]
      tokens = scenario[:tokens]

      result = {
        name: scenario[:name],
        description: scenario[:description],
        input_size: input.bytesize,
        token_count: tokens.size,
        benchmarks: {},
      }

      comparison = Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)

        # Token-Resolver approach
        x.report("token-resolver") do
          Token::Resolver.resolve(input, tokens)
        end

        # String#gsub approach
        x.report("String#gsub") do
          input.gsub(scenario[:gsub_pattern]) do |match|
            key = "KJ|#{Regexp.last_match(1)}"
            tokens[key] || match
          end
        end

        # sprintf approach (only if applicable)
        if scenario[:sprintf_format] && scenario[:sprintf_args]
          x.report("Kernel#sprintf") do
            sprintf(scenario[:sprintf_format], *scenario[:sprintf_args])
          end
        end

        x.compare!
      end

      # Extract results from benchmark
      comparison.entries.each do |entry|
        result[:benchmarks][entry.label] = {
          ips: entry.stats.central_tendency,
          stddev: entry.stats.error_percentage,
          iterations: entry.iterations,
        }
      end

      # Calculate comparison ratios
      if result[:benchmarks]["token-resolver"] && result[:benchmarks]["String#gsub"]
        tr_ips = result[:benchmarks]["token-resolver"][:ips]
        gsub_ips = result[:benchmarks]["String#gsub"][:ips]
        result[:comparison_ratio_gsub] = (gsub_ips / tr_ips).round(2)
      end

      if result[:benchmarks]["token-resolver"] && result[:benchmarks]["Kernel#sprintf"]
        tr_ips = result[:benchmarks]["token-resolver"][:ips]
        sprintf_ips = result[:benchmarks]["Kernel#sprintf"][:ips]
        result[:comparison_ratio_sprintf] = (sprintf_ips / tr_ips).round(2)
      end

      result
    end

    def gather_machine_info
      {
        ruby_version: RUBY_VERSION,
        ruby_platform: RUBY_PLATFORM,
        ruby_description: RUBY_DESCRIPTION,
        date: Time.now.strftime("%Y-%m-%d %H:%M:%S %Z"),
      }
    end

    def build_markdown_content
      md = StringIO.new

      md.puts "# Token-Resolver Benchmark Results"
      md.puts ""
      md.puts "⚠️ **IMPORTANT**: This is NOT an apples-to-apples performance comparison."
      md.puts ""
      md.puts "These three approaches solve different problems with different levels of functionality."
      md.puts "The performance differences reflect this - token-resolver does more work than the alternatives."
      md.puts ""
      md.puts "## What This Benchmark Measures"
      md.puts ""
      md.puts "This benchmark compares three approaches to token/template replacement:"
      md.puts ""
      md.puts "1. **token-resolver**: "
      md.puts "   - Full PEG parsing of input string"
      md.puts "   - Token validation (format, segment count)"
      md.puts "   - Returns parsed document with nodes for introspection"
      md.puts "   - Configurable token structure"
      md.puts "   - Error handling for missing tokens"
      md.puts ""
      md.puts "2. **String#gsub**: "
      md.puts "   - Simple regex pattern matching"
      md.puts "   - Fixed token format"
      md.puts "   - No parsing or validation"
      md.puts "   - No introspection capabilities"
      md.puts ""
      md.puts "3. **Kernel#sprintf**: "
      md.puts "   - Positional format string substitution"
      md.puts "   - Pre-determined template structure"
      md.puts "   - No runtime token discovery"
      md.puts "   - Not suitable for variable/unknown tokens"
      md.puts ""
      md.puts "## Methodology"
      md.puts ""
      md.puts "Each scenario runs for 5 seconds with 2 seconds warmup using `benchmark-ips`."
      md.puts ""
      md.puts "**Why the large performance difference?**"
      md.puts ""
      md.puts "Token-resolver is significantly slower because it:"
      md.puts "- Parses the entire input string using a PEG parser (Parslet gem)"
      md.puts "- Builds an AST of Text and Token nodes"
      md.puts "- Validates token structure against configuration"
      md.puts "- Allocates more objects than simple regex substitution"
      md.puts ""
      md.puts "In contrast, `String#gsub` just does a simple regex replacement with minimal allocations."
      md.puts ""
      md.puts "## Test Environment"
      md.puts ""
      md.puts "- **Ruby Version**: #{@machine_info[:ruby_version]}"
      md.puts "- **Platform**: #{@machine_info[:ruby_platform]}"
      md.puts "- **Ruby Description**: #{@machine_info[:ruby_description]}"
      md.puts "- **Date**: #{@machine_info[:date]}"
      md.puts ""
      md.puts "## Results"
      md.puts ""

      @results.each_with_index do |result, index|
        md.puts "### #{index + 1}. #{result[:name]}"
        md.puts ""
        md.puts "**Description**: #{result[:description]}"
        md.puts ""
        md.puts "**Input Size**: #{result[:input_size]} bytes | **Token Count**: #{result[:token_count]}"
        md.puts ""
        md.puts "| Approach | Iterations/Second | Time per Iteration |"
        md.puts "|----------|-------------------|-------------------|"

        # Sort by IPS descending
        sorted_benchmarks = result[:benchmarks].sort_by { |_, v| -v[:ips] }

        sorted_benchmarks.each do |label, stats|
          ips_formatted = format_number(stats[:ips])
          stddev_formatted = sprintf("±%.1f%%", stats[:stddev])
          time_per_iter_us = (1_000_000 / stats[:ips]).round(2)

          md.puts "| #{label} | #{ips_formatted} #{stddev_formatted} | #{time_per_iter_us}µs |"
        end

        md.puts ""

        # Add comparison summary
        if result[:comparison_ratio_gsub]
          ratio = result[:comparison_ratio_gsub]
          times_slower = (ratio > 1) ? "slower" : "faster"
          md.puts "**Comparison**: `String#gsub` is **#{sprintf("%.0f", ratio)}x #{times_slower}** than `token-resolver`."
        end
        if result[:comparison_ratio_sprintf]
          ratio = result[:comparison_ratio_sprintf]
          times_slower = (ratio > 1) ? "slower" : "faster"
          if ratio > 0
            md.puts "**Comparison**: `Kernel#sprintf` is **#{sprintf("%.0f", ratio)}x #{times_slower}** than `token-resolver`."
          end
        end

        md.puts ""
      end

      md.puts "## Analysis & Recommendations"
      md.puts ""
      md.puts "### Understanding the Performance Gap"
      md.puts ""
      md.puts "The 100-3000x performance difference is **not a problem** - it reflects that these"
      md.puts "are fundamentally different approaches solving different problems:"
      md.puts ""
      md.puts "**token-resolver is designed for:**"
      md.puts "- Applications where token structure may vary"
      md.puts "- Scenarios requiring token validation and introspection"
      md.puts "- Cases where you need to know which tokens were found before resolving"
      md.puts "- Systems with configurable token delimiters/separators"
      md.puts "- When you need proper error handling for invalid/missing tokens"
      md.puts ""
      md.puts "**Simple approaches are designed for:**"
      md.puts "- Fixed, pre-determined token/template formats"
      md.puts "- Raw performance where overhead matters"
      md.puts "- Simple, one-shot replacements"
      md.puts "- Cases where template format is hardcoded"
      md.puts ""
      md.puts "### When to Use Each Approach"
      md.puts ""
      md.puts "#### Use `token-resolver` when:"
      md.puts ""
      md.puts "- ✅ Token structure is **configurable** (custom delimiters, separators)"
      md.puts "- ✅ You need **validation** of token format (min/max segments)"
      md.puts "- ✅ You need to **parse and inspect** tokens before resolution"
      md.puts "- ✅ You want **flexible error handling** for missing tokens (raise/keep/remove)"
      md.puts "- ✅ Token structure may **change across contexts**"
      md.puts "- ✅ You value **maintainability** and **clarity** over absolute speed"
      md.puts "- ✅ You need **single-pass resolution** (replacement values not re-scanned)"
      md.puts ""
      md.puts "**Example use cases:**"
      md.puts "- Template processing pipelines with user-configurable tokens"
      md.puts "- ETL systems where token format varies by data source"
      md.puts "- Configuration file processing with validation"
      md.puts "- Document generation where tokens must be identified and reported"
      md.puts ""
      md.puts "#### Use `String#gsub` when:"
      md.puts ""
      md.puts "- ✅ Token format is **fixed and simple**"
      md.puts "- ✅ You don't need **token validation** or introspection"
      md.puts "- ✅ You need **maximum performance** for fixed patterns"
      md.puts "- ✅ The token pattern **won't change**"
      md.puts "- ✅ You're doing **simple, one-shot replacements**"
      md.puts ""
      md.puts "**Example use cases:**"
      md.puts "- Simple string templating with fixed patterns"
      md.puts "- Log message formatting"
      md.puts "- Quick text substitutions"
      md.puts ""
      md.puts "#### Use `Kernel#sprintf` when:"
      md.puts ""
      md.puts "- ✅ Tokens are **positional** rather than named"
      md.puts "- ✅ Template structure is **completely fixed**"
      md.puts "- ✅ You need **formatting options** (padding, precision, etc.)"
      md.puts "- ✅ You want the **fastest possible string formatting**"
      md.puts ""
      md.puts "**Example use cases:**"
      md.puts "- printf-style formatting"
      md.puts "- Fixed output formatting"
      md.puts "- Performance-critical string building"
      md.puts ""
      md.puts "## Conclusion"
      md.puts ""
      md.puts "Token-resolver is **significantly slower** than simple alternatives because it does"
      md.puts "significantly more work: parsing, validation, introspection, and flexible error handling."
      md.puts ""
      md.puts "This is a **feature, not a bug**. The performance cost is worth paying when you need"
      md.puts "the flexibility and robustness that token-resolver provides."
      md.puts ""
      md.puts "Choose based on your actual requirements:"
      md.puts "- Need flexibility and validation? → **token-resolver** ✅"
      md.puts "- Need speed and have fixed patterns? → **String#gsub** ✅"
      md.puts "- Need positional formatting? → **Kernel#sprintf** ✅"
      md.puts ""
      md.puts "---"
      md.puts ""
      md.puts "*Benchmark generated on #{@machine_info[:date]}*"
      md.puts ""
      md.puts "To regenerate this benchmark:"
      md.puts ""
      md.puts "```bash"
      md.puts "bundle exec rake bench:comparison"
      md.puts "# or"
      md.puts "bundle exec ruby benchmarks/comparison.rb"
      md.puts "```"

      md.string
    end

    def format_number(num)
      if num >= 1_000_000
        sprintf("%.1fM", num / 1_000_000.0)
      elsif num >= 1_000
        sprintf("%.1fk", num / 1_000.0)
      else
        sprintf("%.1f", num)
      end
    end
  end
end

# Run if executed directly
if __FILE__ == $PROGRAM_NAME
  comparison = Benchmarks::Comparison.new
  comparison.run
  comparison.generate_markdown
end
