//! Public-content boundary. Keep the standalone deployment copy byte-identical.

use std::io::{self, Read};
use std::process::ExitCode;

#[inline]
fn fnv1a_token_u64(bytes: &[u8]) -> u64 {
    let mut h = 0xcbf2_9ce4_8422_2325_u64;
    for &b in bytes {
        h ^= u64::from(b);
        h = h.wrapping_mul(0x0100_0000_01b3);
    }
    h
}

#[inline]
fn has_blocked_owner_token(normalized: &str) -> bool {
    const BLOCKED_HASHES: [u64; 5] = [
        0x2253_d0eb_a99e_fabc_u64,
        0x4ade_2688_91d5_9a17_u64,
        0xea3d_87b1_f87c_687b_u64,
        0x4b87_44c1_f2b6_387c_u64,
        0xd45f_61b7_9a7f_c348_u64,
    ];
    let mut prev2 = "";
    let mut prev1 = "";
    for tok in normalized.split(|c: char| !c.is_ascii_alphanumeric()) {
        if tok.is_empty() {
            continue;
        }
        if BLOCKED_HASHES.contains(&fnv1a_token_u64(tok.as_bytes())) {
            return true;
        }
        if !prev1.is_empty() {
            let joined2 = format!("{prev1}{tok}");
            if BLOCKED_HASHES.contains(&fnv1a_token_u64(joined2.as_bytes())) {
                return true;
            }
            if !prev2.is_empty() {
                let joined3 = format!("{prev2}{prev1}{tok}");
                if BLOCKED_HASHES.contains(&fnv1a_token_u64(joined3.as_bytes())) {
                    return true;
                }
            }
        }
        prev2 = prev1;
        prev1 = tok;
    }
    false
}

#[inline]
pub fn disclosure_reason(text: &str) -> Option<&'static str> {
    let normalized = text
        .to_lowercase()
        .replace(['\\', '\u{ff0f}'], "/")
        .replace(['\u{200b}', '\u{200c}', '\u{200d}', '\u{feff}'], "")
        .replace("&#47;", "/")
        .replace("&#x2f;", "/")
        .replace("%2f", "/");
    let normalized = normalized.split_whitespace().collect::<Vec<_>>().join(" ");
    if has_blocked_owner_token(&normalized) {
        return Some("owner-identity-isolation");
    }
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
