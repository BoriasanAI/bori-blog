//! Standalone zero-dependency numerical verification script for coupled operator bridge (9, 14).
//! Compile & run: `rustc -O <file>.rs -o bridge_sim && ./bridge_sim`

#[inline]
fn splitmix64(state: &mut u64) -> f64 {
    *state = state.wrapping_add(0x9e37_79b9_7f4a_7c15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xbf58_476d_1ce4_e5b9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94d0_49bb_1331_11eb);
    z ^= z >> 31;
    ((z >> 11) as f64) * (1.0 / ((1_u64 << 53) as f64)) * 2.0 - 1.0
}

fn mean_ci95_200(samples: &[f64]) -> (f64, f64) {
    let n = samples.len() as f64;
    let mean = samples.iter().sum::<f64>() / n;
    let var = samples.iter().map(|&x| (x - mean) * (x - mean)).sum::<f64>() / (samples.len() - 1) as f64;
    (mean, 1.96 * (var / n).sqrt())
}

fn fnv_digest_f64s(topic_idx: usize, vals: &[f64]) -> String {
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

fn simulate_coupled_regime_200(ia: usize, ib: usize, base_seed: u64, eta: f64) -> ((f64, f64), (f64, f64), (f64, f64)) {
    let mut stab = [0.0_f64; 200];
    let mut v_end = [0.0_f64; 200];
    let mut a_pk = [0.0_f64; 200];
    let is_optical_rg = (ia == 14 && ib == 15) || (ia == 15 && ib == 14);
    let block_b = eta.exp();
    let pair_tag = ((ia as u64) << 8) ^ (ib as u64) ^ 0x6a09_e667_f3bc_c908;
    let alpha_noise = 0.085 + 0.011 * (ia as f64) + 0.004 * (ib as f64);
    let beta_lag = 0.038 + 0.007 * (ib as f64) + 0.003 * (ia as f64);
    let stiff_gain = 0.65 + 0.025 * (((ia * 3 + ib) % 7) as f64);
    let z0_nom = if is_optical_rg { 20.0 } else { 16.5 + 0.45 * (ia as f64) + 0.20 * (ib as f64) };
    let v0_nom = if is_optical_rg { 10.0 } else { 8.4 + 0.22 * (ib as f64) };
    let a_nom = 0.50 * v0_nom * v0_nom / z0_nom;

    for s in 0..200_usize {
        let mut rng = (base_seed ^ pair_tag).wrapping_add((s as u64).wrapping_mul(7919));
        let mut z = z0_nom + 1.0 * splitmix64(&mut rng);
        let mut v = v0_nom + 0.5 * splitmix64(&mut rng);
        let radius = 0.90 + 0.60 * splitmix64(&mut rng);
        let dt = 0.002_f64;
        let d_vartheta = 0.018_f64;
        let mut peak_a = 0.0_f64;

        if is_optical_rg {
            for _ in 0..12_500 {
                if z <= 0.015 || v <= 0.008 { break; }
                let theta = 2.0 * (radius / z).atan();
                let theta_dot_true = 2.0 * radius * v / (z * z + radius * radius);
                let tex_sigma = alpha_noise / block_b.powf(0.85);
                let ap_ratio = (block_b * d_vartheta) / theta.max(0.035);
                let ap_bias = 1.0 / (1.0 + 0.14 * ap_ratio * ap_ratio);
                let xi = splitmix64(&mut rng);
                let theta_dot_obs = (theta_dot_true * ap_bias * (1.0 + tex_sigma * xi)).max(1e-6);
                let tau_hat = (theta.sin() / theta_dot_obs).max(1e-4);
                let decel = (0.50 * v / tau_hat).clamp(0.0, 9.0);
                if decel > peak_a { peak_a = decel; }
                z = (z - v * dt - 0.5 * decel * dt * dt).max(0.0);
                v = (v - decel * dt).max(0.0);
            }
        } else {
            for _ in 0..12_500 {
                if z <= 0.015 || v <= 0.008 { break; }
                let irr_noise = (alpha_noise / block_b.powf(stiff_gain)) * splitmix64(&mut rng);
                let cross_lag = beta_lag * (block_b - 1.0).max(0.0).powi(2);
                let eff_gain = (1.0 / (1.0 + cross_lag)) * (1.0 + irr_noise);
                let tau_eff = (z / (v * eff_gain.max(0.15))).max(1e-4);
                let decel = (0.50 * v / tau_eff).clamp(0.0, 9.0);
                if decel > peak_a { peak_a = decel; }
                z = (z - v * dt - 0.5 * decel * dt * dt).max(0.0);
                v = (v - decel * dt).max(0.0);
            }
        }
        let arrest_term = (-v / 0.35).exp();
        let margin_pen = 0.28 * ((peak_a - a_nom).max(0.0) / (9.0 - a_nom).max(1.0));
        let under_pen = if z > 0.25 { 0.35 * (z / z0_nom).min(1.0) } else { 0.0 };
        stab[s] = (arrest_term * (1.0 - margin_pen) - under_pen).clamp(0.0, 1.0);
        v_end[s] = v;
        a_pk[s] = peak_a;
    }
    (mean_ci95_200(&stab), mean_ci95_200(&v_end), mean_ci95_200(&a_pk))
}

fn main() {
    let (ia, ib, base_seed) = (9_usize, 14_usize, 26172_u64);
    let mut best_eta = 0.05_f64;
    let mut best_mean = -1.0_f64;
    for step in 1..=27_usize {
        let eta = (step as f64) * 0.05;
        let ((m, _), _, _) = simulate_coupled_regime_200(ia, ib, base_seed, eta);
        if m > best_mean {
            best_mean = m;
            best_eta = eta;
        }
    }
    let (s0, _, _) = simulate_coupled_regime_200(ia, ib, base_seed, 0.00);
    let (sw, _, _) = simulate_coupled_regime_200(ia, ib, base_seed, 0.15);
    let (so, vo, ao) = simulate_coupled_regime_200(ia, ib, base_seed, best_eta);
    let (sv, _, _) = simulate_coupled_regime_200(ia, ib, base_seed, 1.35);
    let digest = fnv_digest_f64s(ia * 16 + ib, &[best_eta, s0.0, sw.0, so.0, sv.0]);
    println!("eta_star={best_eta:.2} (expected 0.05)");
    println!("eta=0.00      stability={:.3} +- {:.3}", s0.0, s0.1);
    println!("eta=0.15      stability={:.3} +- {:.3}", sw.0, sw.1);
    println!("eta={best_eta:.2}*     stability={:.3} +- {:.3} (v_end={:.2} +- {:.2}, a_peak={:.2} +- {:.2})", so.0, so.1, vo.0, vo.1, ao.0, ao.1);
    println!("eta=1.35      stability={:.3} +- {:.3}", sv.0, sv.1);
    println!("FNV1a-64=0x{digest}");
}
