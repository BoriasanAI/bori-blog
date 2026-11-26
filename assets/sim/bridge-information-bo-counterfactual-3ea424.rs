//! Zero-dependency Stormer-Verlet + Turing dispersion solver for bridge (4, 11).
//! Compile & run: `rustc -O <file>.rs -o symp_sim && ./symp_sim`

#[inline]
fn pcg32_unit(state: &mut u64, inc: u64) -> f64 {
    let old = *state;
    *state = old.wrapping_mul(6_364_136_223_846_793_005_u64).wrapping_add(inc | 1);
    let xorshifted = (((old >> 18) ^ old) >> 27) as u32;
    let rot = (old >> 59) as u32;
    let out = xorshifted.rotate_right(rot);
    (f64::from(out) / f64::from(u32::MAX)) * 2.0 - 1.0
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
    let mut coh = [0.0_f64; 160];
    let mut dh_arr = [0.0_f64; 160];
    let mut lam_arr = [0.0_f64; 160];
    let scale_b = eta.exp();
    let pair_tag = ((ia as u64) << 8) ^ (ib as u64) ^ 0x517c_c1b7_2722_0a95;
    let diff_ratio = 6.0 + 1.2 * ((ia + ib) % 7) as f64;
    let noise_amp = 0.048 + 0.004 * (ia as f64) + 0.002 * (ib as f64);
    let lag_coeff = 0.032 + 0.005 * (ib as f64);
    let dt = 0.025_f64;
    for s in 0..160_usize {
        let mut st = (base_seed ^ pair_tag).wrapping_add((s as u64).wrapping_mul(7_907));
        let inc = ((s as u64) << 1) | 1;
        let mut q = 1.05 + 0.25 * pcg32_unit(&mut st, inc);
        let mut p = 0.35 * pcg32_unit(&mut st, inc);
        let h0 = 0.5 * p * p + 0.5 * q * q + 0.25 * q.powi(4);
        let mut max_dh = 0.0_f64;
        for _ in 0..240 {
            let eps_damp = (noise_amp / scale_b.powf(0.95)) * pcg32_unit(&mut st, inc);
            let coarse_bias = lag_coeff * (scale_b - 1.0).max(0.0).powi(2);
            let p_half = p - 0.5 * dt * (q + q.powi(3) + coarse_bias * q);
            q += dt * p_half;
            p = p_half - 0.5 * dt * (q + q.powi(3)) + dt * eps_damp;
            let dh = (0.5 * p * p + 0.5 * q * q + 0.25 * q.powi(4) - h0).abs();
            if dh > max_dh { max_dh = dh; }
        }
        let k2 = (0.42 + 0.08 * ((ia % 5) as f64)) / scale_b.powf(0.45);
        let disp_margin = (0.38 - (1.0 / diff_ratio) * k2 - 0.16 * (scale_b - 1.0).max(0.0).powi(2)
            + 0.015 * pcg32_unit(&mut st, inc)).max(0.0);
        coh[s] = (0.68 * (-max_dh / 0.18).exp() + 0.32 * (disp_margin / 0.38).clamp(0.0, 1.0)).clamp(0.0, 1.0);
        dh_arr[s] = max_dh;
        lam_arr[s] = disp_margin;
    }
    (mean_ci95(&coh), mean_ci95(&dh_arr), mean_ci95(&lam_arr))
}

fn main() {
    let (ia, ib, base_seed) = (4_usize, 11_usize, 15645_u64);
    let (mut best_eta, mut best_m) = (0.05_f64, -1.0_f64);
    for step in 1..=27_usize {
        let eta = (step as f64) * 0.05;
        let ((m, _), _, _) = simulate(ia, ib, base_seed, eta);
        if m > best_m { best_m = m; best_eta = eta; }
    }
    let (s0, _, _) = simulate(ia, ib, base_seed, 0.00);
    let (sw, _, _) = simulate(ia, ib, base_seed, 0.15);
    let (so, dh, lam) = simulate(ia, ib, base_seed, best_eta);
    let (sv, _, _) = simulate(ia, ib, base_seed, 1.35);
    let digest = fnv_digest(ia * 16 + ib, &[best_eta, s0.0, sw.0, so.0, sv.0]);
    println!("eta_star={best_eta:.2} (expected 0.20)");
    println!("coherence={:.3} +- {:.3} |dH|={:.3} +- {:.3} Re(lam)={:.3} +- {:.3}", so.0, so.1, dh.0, dh.1, lam.0, lam.1);
    println!("FNV1a-64=0x{digest}");
}
