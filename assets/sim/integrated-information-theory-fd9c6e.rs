//! Standalone zero-dependency verification script (`mode = 1`, `seed = 0x000000002025c5d1`).
//! Compile & run: `rustc -O <file>.rs -o verify_sim && ./verify_sim`
#[inline]
fn splitmix64(state: &mut u64) -> f64 {
    *state = state.wrapping_add(0x9e37_79b9_7f4a_7c15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xbf58_476d_1ce4_e5b9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94d0_49bb_1331_11eb);
    z ^= z >> 31;
    ((z >> 11) as f64) * (1.0 / ((1_u64 << 53) as f64)) * 2.0 - 1.0
}
fn mean_ci95_200(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let v = xs.iter().map(|&x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0);
    (m, 1.96 * (v / n).sqrt())
}
fn fnv_digest_f64s(topic_idx: usize, vals: &[f64]) -> String {
    let mut h = 0xcbf2_9ce4_8422_2325_u64 ^ (topic_idx as u64);
    for &v in vals {
        let q = (v * 10_000.0).round() as i64;
        for b in q.to_le_bytes() { h ^= u64::from(b); h = h.wrapping_mul(0x0100_0000_01b3); }
    }
    format!("{h:016x}")
}
fn main() {
    let params = [0.000_f64, 0.520_f64, 0.920_f64];
    let (seed, tag, mode) = (539346385_u64, 18761_u64, 1_u8);
    let mut flat = [0.0_f64; 6];
    for (pi, &p) in params.iter().enumerate() {
        let (mut sa, mut sb) = ([0.0_f64; 200], [0.0_f64; 200]);
        for s in 0..200_usize {
            let mut rng = (seed ^ tag ^ ((pi as u64) << 12)).wrapping_add((s as u64).wrapping_mul(7919));
            let (xi1, xi2) = (splitmix64(&mut rng), splitmix64(&mut rng));
            match mode {
                0 => {
                    let k_aut = (8.0 * (1.0 - 0.72 * p).max(0.125)) * (1.0 + 0.04 * xi1);
                    sa[s] = k_aut.max(1.0).log2().max(0.0);
                    sb[s] = ((p * p / (0.18 + p * p)) * (1.0 - 0.22 * p.max(0.0) * (p - 0.85).max(0.0)) + 0.015 * xi2).clamp(0.0, 1.0);
                }
                1 => {
                    let pe = (p + 0.025 * xi1).clamp(0.0, 0.98);
                    let mip = if p < 0.02 { 0.0005 * xi2.abs() } else { (1.42 * pe * (1.0 - 0.58 * pe) + 0.012 * xi2).max(0.0) };
                    sa[s] = mip;
                    sb[s] = (mip * (1.08 + 0.09 * pe) + 0.008 * xi1.abs()).max(0.0);
                }
                2 => {
                    let nov = (1.0 - (-1.35 * p).exp() + 0.02 * xi1).clamp(0.02, 0.99);
                    let val = ((-0.52 * p * p).exp() + 0.02 * xi2).clamp(0.02, 0.99);
                    sa[s] = nov * val; sb[s] = 0.5 * (nov + val);
                }
                _ => {
                    let sig = (-((0.45 + 0.05 * xi1) / p.max(0.05))).exp();
                    let bg = (0.18 * p + 0.015 * xi2.abs()).min(0.95);
                    sa[s] = (sig / (sig + bg).max(1e-6)).clamp(0.0, 1.0); sb[s] = bg;
                }
            }
        }
        let (ma, mb) = (mean_ci95_200(&sa), mean_ci95_200(&sb));
        flat[pi * 2] = ma.0; flat[pi * 2 + 1] = mb.0;
        println!("p={p:.2} -> A={:.3} +- {:.3}, B={:.3} +- {:.3}", ma.0, ma.1, mb.0, mb.1);
    }
    println!("FNV1a-64=0x{} (expected 0x5a5c10945a256779)", fnv_digest_f64s(usize::from(mode) + 100, &flat));
}
