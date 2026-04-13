#!/usr/bin/env bash
set -e

# Change to project root
cd "$(dirname "$0")/.."

echo "Building release binary..."
cargo build --release

echo "Generating large test file (20,000 lines)..."
cat << 'PYEOF' > generate_test.py
with open("large_test.rs", "w") as f:
    f.write("fn main() {\n")
    for i in range(10000):
        f.write(f"    let var_{i} = {i};\n")
        f.write(f"    println!(\"{i}\");\n")
    f.write("}\n")
PYEOF
python3 generate_test.py

echo "Creating Bun hash reference script..."
cat << 'BUNEOF' > bun_hash.ts
import { readFileSync } from "fs";

function main() {
  const content = readFileSync(process.argv[2], "utf-8");
  const lines = content.split("\n");
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    let hash = "00";
    if (trimmed !== "") {
        hash = (Number(Bun.hash(trimmed) % 256n)).toString(16).padStart(2, '0');
    }
    out.push({ l: i + 1, h: hash, c: lines[i] });
  }
}
main();
BUNEOF

echo "Running Hyperfine Read Benchmark..."
~/.cargo/bin/hyperfine --warmup 3 \
  "target/release/llm-hash-edit-cli read large_test.rs > /dev/null" \
  "bun bun_hash.ts large_test.rs > /dev/null"

echo "Preparing Apply Benchmark payload..."
cat << 'JSONEOF' > edit.json
[
  {
    "op": "r",
    "l": 499,
    "h": "dd",
    "c": "    println!(\"248 - EDITED\");"
  },
  {
    "op": "rm",
    "s": 502,
    "e": 503,
    "h": ["2f", "35"],
    "c": ["    let var_250 = 250000;", "    println!(\"250000\");"]
  }
]
JSONEOF

cp large_test.rs large_test.rs.bak

echo "Running Hyperfine Apply Benchmark..."
~/.cargo/bin/hyperfine --warmup 3 \
  --prepare "cp large_test.rs.bak large_test.rs" \
  "cat edit.json | target/release/llm-hash-edit-cli apply large_test.rs > /dev/null"

echo "Cleaning up..."
rm generate_test.py bun_hash.ts large_test.rs large_test.rs.bak edit.json
echo "Benchmarks complete."
