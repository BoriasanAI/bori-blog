//! Zero-dependency interventional ATE + Brier-KL inference solver for bridge (0, 1).
//! Compile & run: `rustc -O <file>.rs -o infer_sim && ./infer_sim`

#[inline]
fn xorshift64_star_unit(state: &mut u64) -> f64 {
    let mut x = (*state).max(1);
    x ^= x >> 12;
    x ^= x << 25;
    x ^= x >> 27;
    *state = x;
    let out = x.wrapping_mul(0x2545_f491_4f6c_dd1d_u64);
    ((out >> 11) as f64) * (1.0 / ((1_u64 << 53) as f64)) * 2.0 - 1.0
}

fn mean_ci95(samples: &[f64]) -> (f64, f64) {
    let n = samples.len() as f64;
    let mean = samples.iter().sum::<f64>() / n;
    let var = samples.iter().map(|&x| (x - mean) * (x - mean)).sum::<f64>() / (samples.len() - 1) as f64;
    (mean, 1.96 * (var / n).sqrt())
}

fn fnv_digest(topic_idx: usize, vals: &[f64]) -> String {
    let mut h = 0xcbf2_9ce4_8422_2325_u64 ^ (topic_idx as u64);
    for &v in vals {
        let q = (v * 10_000.0).round() as i64;
        for b in q.to_le_bytes() {
            h ^= u64::from(b);
            h = h.wrapping_mul(0x0100_0000_01b3);
        }
    }
    format!("{h:016x}")
}

fn simulate(ia: usize, ib: usize, base_seed: u64, eta: f64) -> ((f64, f64), (f64, f64), (f64, f64)) {
    let mut fid = [0.0_f64; 144];
    let mut bias_arr = [0.0_f64; 144];
    let mut risk_arr = [0.0_f64; 144];
    let comp_b = eta.exp();
    let pair_tag = ((ia as u64) << 8) ^ (ib as u64) ^ 0x9e37_79b9_7f4a_7c15;
    let conf_base = 0.24 + 0.018 * (ia as f64) + 0.008 * (ib as f64);
    let trunc_k = 0.044 + 0.006 * (ib as f64);
    let true_ate = 0.32_f64;
    for s in 0..144_usize {
        let mut st = (base_seed ^ pair_tag).wrapping_add((s as u64).wrapping_mul(7_883) + 17);
        let (mut est_sum, mut brier_sum) = (0.0_f64, 0.0_f64);
        for _ in 0..32_usize {
            let u_noise = (conf_base / comp_b.powf(0.88)) * xorshift64_star_unit(&mut st);
            let info_loss = trunc_k * (comp_b - 1.0).max(0.0).powi(2);
            let est_ate = true_ate + u_noise - info_loss;
            let p_true = (0.5 + 0.5 * true_ate).clamp(0.05, 0.95);
            let p_hat = (0.5 + 0.5 * est_ate).clamp(0.02, 0.98);
            est_sum += (est_ate - true_ate).abs();
            brier_sum += p_true * (1.0 - p_hat).powi(2) + (1.0 - p_true) * p_hat.powi(2);
        }
        let abs_bias = est_sum / 32.0;
        let brier = brier_sum / 32.0;
        let excess_risk = (brier - 0.66 * 0.34).max(0.0);
        fid[s] = ((-abs_bias / 0.16).exp() * (-excess_risk / 0.045).exp()).clamp(0.0, 1.0);
        bias_arr[s] = abs_bias;
        risk_arr[s] = brier;
    }
    (mean_ci95(&fid), mean_ci95(&bias_arr), mean_ci95(&risk_arr))
}

fn main() {
    let (ia, ib, base_seed) = (0_usize, 1_usize, 306_u64);
    let (mut best_eta, mut best_m) = (0.05_f64, -1.0_f64);
    for step in 1..=27_usize {
        let eta = (step as f64) * 0.05;
        let ((m, _), _, _) = simulate(ia, ib, base_seed, eta);
        if m > best_m { best_m = m; best_eta = eta; }
    }
    let (s0, _, _) = simulate(ia, ib, base_seed, 0.00);
    let (sw, _, _) = simulate(ia, ib, base_seed, 0.30);
    let (so, b, r) = simulate(ia, ib, base_seed, best_eta);
    let (sv, _, _) = simulate(ia, ib, base_seed, 1.35);
    let digest = fnv_digest(ia * 16 + ib, &[best_eta, s0.0, sw.0, so.0, sv.0]);
    println!("eta_star={best_eta:.2} (expected 0.65)");
    println!("fidelity={:.3} +- {:.3} ate_bias={:.3} +- {:.3} brier={:.4} +- {:.4}", so.0, so.1, b.0, b.1, r.0, r.1);
    println!("FNV1a-64=0x{digest}");
}
