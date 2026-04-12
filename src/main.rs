use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::{self, Read};
use std::process;
use xxhash_rust::xxh32::xxh32;

#[derive(Parser)]
#[command(author, version, about = "LLM compact hashmap line editor")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Read file to hashlined JSON array
    Read { file: String },
    /// Apply edits from JSON array on stdin
    Apply { file: String },
}

#[derive(Serialize)]
struct LineOutput {
    l: usize,
    h: String,
    c: String,
}

#[derive(Deserialize, Debug)]
#[serde(tag = "op")]
enum Edit {
    #[serde(rename = "r")] Replace { l: usize, h: String, c: String },
    #[serde(rename = "rm")] ReplaceMulti { s: usize, e: usize, h: Vec<String>, c: Vec<String> },
    #[serde(rename = "i")] Insert { l: usize, h: String, c: Vec<String> },
    #[serde(rename = "d")] Delete { s: usize, e: usize, h: Vec<String> },
}

impl Edit {
    fn start_line(&self) -> usize {
        match self {
            Edit::Replace { l, .. } => *l,
            Edit::ReplaceMulti { s, .. } => *s,
            Edit::Insert { l, .. } => *l,
            Edit::Delete { s, .. } => *s,
        }
    }
}

fn compute_hash(line: &str) -> String {
    let trimmed = line.trim();
    let h = if trimmed.is_empty() { 0 } else { xxh32(trimmed.as_bytes(), 0) % 256 };
    format!("{:02x}", h)
}

fn error_exit(msg: &str) -> ! {
    eprintln!("{}", serde_json::json!({ "error": msg }));
    process::exit(1);
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Read { file } => {
            let content = match fs::read_to_string(&file) { Ok(c) => c, Err(e) => error_exit(&format!("Failed to read {}: {}", file, e)) };
            let mut out = Vec::new();
            for (i, line) in content.lines().enumerate() {
                out.push(LineOutput { l: i + 1, h: compute_hash(line), c: line.to_string() });
            }
            println!("{}", serde_json::to_string(&out).unwrap());
        }
        Commands::Apply { file } => {
            let mut input = String::new();
            io::stdin().read_to_string(&mut input).unwrap_or_else(|_| error_exit("Failed to read stdin"));
            let mut edits: Vec<Edit> = serde_json::from_str(&input).unwrap_or_else(|e| error_exit(&format!("Invalid JSON payload: {}", e)));
            edits.sort_by(|a, b| b.start_line().cmp(&a.start_line()));
            let content = match fs::read_to_string(&file) { Ok(c) => c, Err(e) => error_exit(&format!("Failed to read {}: {}", file, e)) };
            let has_trailing_newline = content.ends_with('\n');
            let mut lines: Vec<String> = content.split('\n').map(|s| s.to_string()).collect();
            if has_trailing_newline && !lines.is_empty() { lines.pop(); }
            
            for edit in edits {
                match edit {
                    Edit::Replace { l, h, c } => {
                        let idx = l - 1;
                        if idx >= lines.len() { error_exit(&format!("Line {} out of bounds", l)); }
                        if compute_hash(&lines[idx]) != h { error_exit(&format!("Hash mismatch at line {}", l)); }
                        lines[idx] = c;
                    }
                    Edit::ReplaceMulti { s, e, h, c } => {
                        let start_idx = s - 1; let end_idx = e - 1;
                        if end_idx >= lines.len() { error_exit(&format!("Line {} out of bounds", e)); }
                        if h.len() != (e - s + 1) { error_exit("Hash array length must match line range"); }
                        for (i, hash) in h.iter().enumerate() {
                            if compute_hash(&lines[start_idx + i]) != *hash { error_exit(&format!("Hash mismatch at line {}", s + i)); }
                        }
                        lines.splice(start_idx..=end_idx, c);
                    }
                    Edit::Insert { l, h, c } => {
                        if l == 0 {
                            if h != "00" { error_exit("BOF insert expected hash 00"); }
                            for (i, new_line) in c.into_iter().enumerate() { lines.insert(i, new_line); }
                        } else {
                            let idx = l - 1;
                            if idx >= lines.len() { error_exit(&format!("Line {} out of bounds", l)); }
                            if compute_hash(&lines[idx]) != h { error_exit(&format!("Hash mismatch at line {}", l)); }
                            for (i, new_line) in c.into_iter().enumerate() { lines.insert(idx + 1 + i, new_line); }
                        }
                    }
                    Edit::Delete { s, e, h } => {
                        let start_idx = s - 1; let end_idx = e - 1;
                        if end_idx >= lines.len() { error_exit(&format!("Line {} out of bounds", e)); }
                        if h.len() != (e - s + 1) { error_exit("Hash array length must match line range"); }
                        for (i, hash) in h.iter().enumerate() {
                            if compute_hash(&lines[start_idx + i]) != *hash { error_exit(&format!("Hash mismatch at line {}", s + i)); }
                        }
                        lines.drain(start_idx..=end_idx);
                    }
                }
            }
            let mut output = lines.join("\n");
            if has_trailing_newline { output.push('\n'); }
            if let Err(e) = fs::write(&file, output) { error_exit(&format!("Failed to write to file: {}", e)); }
            println!("{}", serde_json::json!({"status": "success"}));
        }
    }
}
