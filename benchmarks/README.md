# LLM Hash Edit Benchmarks

This directory contains scripts to test and benchmark the performance and reliability of `llm-hash-edit-cli`.

## 1. Hyperfine Performance Benchmark

Measures the raw execution speed (latency) of the Rust CLI vs a comparable native script in Bun (simulating an MCP server execution).

```bash
chmod +x hyperfine_bench.sh
./hyperfine_bench.sh
```
This generates a 20,000 line synthetic file and runs `hyperfine` to compare reading and applying times.

## 2. LLM Agent Hit Rate A/B Test

Tests how reliably an LLM agent (Gemini, Claude Code, Codex) can perform edits with and without `llm-hash-edit-cli`.

**Prerequisites:**
You need a directory containing test cases (e.g., `dataset/test_1`). Each test case must be a valid Rust project (or another language you are testing) containing a `prompt.txt` that describes the bug to fix, and a test suite that fails initially but will pass if the LLM makes the right edit.

**Running the Control Group (Native Editing Tools):**
```bash
chmod +x hit_rate_bench.sh
./hit_rate_bench.sh --agent "gemini --yolo" --dataset ./dataset
```

**Running the Experimental Group (With Hashline Skill):**
Make sure the `llm-hash-edit` skill is loaded in your environment, then run:
```bash
./hit_rate_bench.sh --agent "gemini --yolo" --dataset ./dataset --use-skill
```

Compare the hit rate (%) between the two runs to measure the reduction in hallucinated or malformed edits!
