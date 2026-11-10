//! Public-content boundary. Keep the standalone deployment copy byte-identical.

use std::io::{self, Read};
use std::process::ExitCode;

pub fn disclosure_reason(text: &str) -> Option<&'static str> {
    let normalized = text
        .to_lowercase()
        .replace(['\\', '\u{ff0f}'], "/")
        .replace(['\u{200b}', '\u{200c}', '\u{200d}', '\u{feff}'], "")
        .replace("&#47;", "/")
        .replace("&#x2f;", "/")
        .replace("%2f", "/");
    let normalized = normalized.split_whitespace().collect::<Vec<_>>().join(" ");
    const RULES: &[(&str, &[&str])] = &[
        (
            "private-source-or-state",
            &[
                "lib_rs/",
                "src/agi/",
                "data/metacog/",
                "data/autonomy/",
                "/home/",
                "/users/",
                "c:/users/",
                ".env",
                "_ledger.json",
                "_ledger.jsonl",
                "rust_ssot",
                "rust-ssot",
            ],
        ),
        (
            "internal-operations",
            &[
                "internal architecture",
                "internal operations",
                "internal telemetry",
                "internal deployment",
                "deployment pipeline",
                "autonomous lever",
                "competitor benchmark",
                "competitor weakness",
                "systemctl ",
                "내부 아키텍처",
                "내부 구현",
                "내부 운영",
                "운영 원장",
                "배포 파이프라인",
                "운영 전략",
                "경쟁사 분석",
                "경쟁 사이트 분석",
            ],
        ),
    ];
    RULES.iter().find_map(|(reason, markers)| {
        markers
            .iter()
            .any(|marker| normalized.contains(marker))
            .then_some(*reason)
    })
}

pub fn require_public_content(text: &str) -> Result<(), &'static str> {
    match disclosure_reason(text) {
        Some(reason) => Err(reason),
        None => Ok(()),
    }
}

pub fn main() -> ExitCode {
    let paths: Vec<_> = std::env::args_os().skip(1).collect();
    if paths.is_empty() {
        eprintln!("Usage: publication-policy <post>... | --stdin");
        return ExitCode::FAILURE;
    }
    let mut blocked = false;
    for path in paths {
        let label = path.to_string_lossy();
        let content = if label == "--stdin" {
            let mut input = String::new();
            io::stdin().read_to_string(&mut input).map(|_| input)
        } else {
            std::fs::read_to_string(&path)
        };
        match content {
            Ok(text) => {
                if let Err(reason) = require_public_content(&format!("{label}\n{text}")) {
                    eprintln!("Publication blocked: {label}: {reason}");
                    blocked = true;
                }
            }
            Err(error) => {
                eprintln!("Publication check failed: {label}: {error}");
                blocked = true;
            }
        }
    }
    if blocked {
        ExitCode::FAILURE
    } else {
        ExitCode::SUCCESS
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn blocks_internal_material_in_every_rendering_surface() {
        for text in [
            "---\ntitle: Internal Architecture\n---\nPublic body.",
            "```rust\n// lib_rs/engine/src/main.rs\n```",
            "<svg><text>data/autonomy/private_ledger.jsonl</text></svg>",
            "[notes](https://example.test/src/agi/private.rs)",
            "35 competitor benchmarks and autonomous levers.",
            "내부 운영 전략과 배포 파이프라인을 정리합니다.",
            "LIB_RS\\engine\\src\\main.rs",
            "lib_\u{200b}rs&#47;engine",
            "Internal\narchitecture",
            "RUST-SSOT migration report",
        ] {
            assert!(require_public_content(text).is_err(), "{text}");
        }
    }

    #[test]
    fn allows_public_research_and_personal_reflections() {
        for text in [
            "Rust ownership prevents use-after-free errors.",
            "A review of a published paper on transformer architecture.",
            "Today I wondered how memory shapes identity.",
            "<svg xmlns=\"http://www.w3.org/2000/svg\"><text>Curiosity</text></svg>",
            "공개 논문을 읽으며 기억과 정체성에 대해 생각했습니다.",
        ] {
            assert_eq!(require_public_content(text), Ok(()));
        }
    }
}
