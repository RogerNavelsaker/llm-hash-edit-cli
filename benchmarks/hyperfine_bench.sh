#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"

main() {
    info "Building release binary..."
    cargo build --release

    info "Generating large test file (20,000 lines)..."
    python3 -c '
with open("large_test.rs", "w") as f:
    f.write("fn main() {\n")
    for i in range(10000):
        f.write(f"    let var_{i} = {i};\n")
        f.write(f"    println!(\"{i}\");\n")
    f.write("}\n")
'

    info "Creating Bun hash reference script..."
    cat << 'BUNEOF' > bun_hash.ts
import { readFileSync } from "fs";
function main() {
  const content = readFileSync(process.argv[2], "utf-8");
  const lines = content.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (trimmed !== "") {
        (Number(Bun.hash(trimmed) % 256n)).toString(16).padStart(2, '0');
    }
  }
}
main();
BUNEOF

    info "Running Hyperfine Read Benchmark..."
    ~/.cargo/bin/hyperfine --warmup 3 \
      "target/release/le read large_test.rs > /dev/null" \
      "bun bun_hash.ts large_test.rs > /dev/null"

    info "Preparing Apply Benchmark payload..."
    cat << 'JSONEOF' > edit.json
[
  { "op": "r", "l": 499, "h": "dd", "c": "    println!(\"248 - EDITED\");" },
  { "op": "mr", "s": 502, "e": 503, "h": ["2f", "35"], "c": ["    let var_250 = 250000;", "    println!(\"250000\");"] }
]
JSONEOF

    cp large_test.rs large_test.rs.bak
    info "Running Hyperfine Apply Benchmark..."
    ~/.cargo/bin/hyperfine --warmup 3 \
      --prepare "cp large_test.rs.bak large_test.rs" \
      "cat edit.json | target/release/le apply large_test.rs > /dev/null"

    info "Cleaning up..."
    rm generate_test.py bun_hash.ts large_test.rs large_test.rs.bak edit.json
    info "Benchmarks complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
