//! Zero-dependency GENERIC / Strang-Split Solver for bridge (10, 11):
//!   Conservative subsystem: Stormer-Verlet quartic oscillator H(q,p) = 0.5*p^2 + 0.5*q^2 + 0.25*q^4
//!   Dissipative subsystem : 16-cell periodic 1D Schnakenberg/Turing reaction-diffusion PDE
//!                           du/dt = D_u * Lap(u) + a - u + u^2 * v
//!                           dv/dt = D_v * Lap(v) + b - u^2 * v   (a=0.10, b=0.90, D_v/D_u=25)
//! Compile & run: `rustc -O <file>.rs -o symp_turing_sim && ./symp_turing_sim`

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
    const M: usize = 16;
    let mut coh = [0.0_f64; 160];
    let mut dh_arr = [0.0_f64; 160];
    let mut contrast_arr = [0.0_f64; 160];
    let scale_b = eta.exp();
    let pair_tag = ((ia as u64) << 8) ^ (ib as u64) ^ 0x517c_c1b7_2722_0a95;
    let a_k = 0.10_f64;
    let b_k = 0.88_f64 + 0.025 * (((ia + ib) % 4) as f64);
    let du_base = 0.024_f64 + 0.004 * ((ia % 5) as f64);
    let dv_base = 0.88_f64 + 0.06 * ((ib % 4) as f64);
    let du_eff = (du_base * (1.0 + 3.8 * (scale_b - 1.0).max(0.0).powi(2))).min(dv_base);
    let port_noise_amp = 0.28 + 0.015 * (ia as f64) + 0.008 * (ib as f64);
    let port_bias_amp = 0.042 + 0.004 * (ib as f64);
    let dt = 0.04_f64;

    for s in 0..160_usize {
        let mut st = (base_seed ^ pair_tag).wrapping_add((s as u64).wrapping_mul(7_907));
        let inc = ((s as u64) << 1) | 1;
        let mut q = 1.05 + 0.20 * pcg32_unit(&mut st, inc);
        let mut p = 0.30 * pcg32_unit(&mut st, inc);
        let h0 = 0.5 * p * p + 0.5 * q * q + 0.25 * q.powi(4);
        let mut max_dh = 0.0_f64;

        let u_star = a_k + b_k;
        let v_star = b_k / (u_star * u_star);
        let mut u = [u_star; M];
        let mut v = [v_star; M];
        let mut u_next = [0.0_f64; M];
        let mut v_next = [0.0_f64; M];
        for j in 0..M {
            let phase = 2.0 * std::f64::consts::PI * 4.0 * (j as f64) / (M as f64);
            u[j] = u_star + 0.05 * phase.cos() + 0.02 * pcg32_unit(&mut st, inc);
            v[j] = v_star + 0.015 * pcg32_unit(&mut st, inc);
        }

        for _ in 0..140 {
            // 1. Strang conservative half-step Phi_{dt/2}^symp (Stormer-Verlet)
            let p_mid = p - 0.25 * dt * (q + q.powi(3));
            q += 0.5 * dt * p_mid;
            p = p_mid - 0.25 * dt * (q + q.powi(3));

            // 2. Strang dissipative full-step Phi_dt^RD (1D 16-cell periodic Schnakenberg PDE)
            let mut u_mean = 0.0_f64;
            for j in 0..M {
                let jm = (j + M - 1) % M;
                let jp = (j + 1) % M;
                let lap_u = u[jm] - 2.0 * u[j] + u[jp];
                let lap_v = v[jm] - 2.0 * v[j] + v[jp];
                let u2v = u[j] * u[j] * v[j];
                u_next[j] = (u[j] + dt * (du_eff * lap_u + a_k - u[j] + u2v)).clamp(0.05, 4.0);
                v_next[j] = (v[j] + dt * (dv_base * lap_v + b_k - u2v)).clamp(0.05, 4.0);
                u_mean += u_next[j];
            }
            u = u_next;
            v = v_next;
            u_mean /= M as f64;

            // 3. Port-Hamiltonian boundary exchange + second conservative half-step Phi_{dt/2}^symp
            let port_fluct = (port_noise_amp / scale_b.powf(1.45)) * (u_mean - u_star)
                + (port_noise_amp * 0.75 / scale_b.powf(1.35)) * pcg32_unit(&mut st, inc);
            let port_drag = port_bias_amp * (scale_b - 1.0).max(0.0).powi(2) * q;
            let p_mid2 = p - 0.25 * dt * (q + q.powi(3) + port_drag) + 0.5 * dt * port_fluct;
            q += 0.5 * dt * p_mid2;
            p = p_mid2 - 0.25 * dt * (q + q.powi(3));

            let h_cur = 0.5 * p * p + 0.5 * q * q + 0.25 * q.powi(4);
            let dh = (h_cur - h0).abs();
            if dh > max_dh { max_dh = dh; }
        }

        let mean_u = u.iter().sum::<f64>() / (M as f64);
        let var_u = u.iter().map(|&x| (x - mean_u) * (x - mean_u)).sum::<f64>() / (M as f64);
        let sigma_u = var_u.sqrt();
        let energy_term = (-max_dh / 0.14).exp();
        let pattern_term = (sigma_u / 0.12).clamp(0.0, 1.0);
        coh[s] = (0.58 * energy_term + 0.42 * pattern_term).clamp(0.0, 1.0);
        dh_arr[s] = max_dh;
        contrast_arr[s] = sigma_u;
    }
    (mean_ci95(&coh), mean_ci95(&dh_arr), mean_ci95(&contrast_arr))
}

fn simulate_explicit_euler_baseline(ia: usize, ib: usize, base_seed: u64) -> ((f64, f64), (f64, f64), (f64, f64)) {
    const M: usize = 16;
    let mut coh = [0.0_f64; 160];
    let mut dh_arr = [0.0_f64; 160];
    let mut contrast_arr = [0.0_f64; 160];
    let pair_tag = ((ia as u64) << 8) ^ (ib as u64) ^ 0x517c_c1b7_2722_0a95;
    let a_k = 0.10_f64;
    let b_k = 0.88_f64 + 0.025 * (((ia + ib) % 4) as f64);
    let du_base = 0.024_f64 + 0.004 * ((ia % 5) as f64);
    let dv_base = 0.88_f64 + 0.06 * ((ib % 4) as f64);
    let dt = 0.04_f64;
    for s in 0..160_usize {
        let mut st = (base_seed ^ pair_tag).wrapping_add((s as u64).wrapping_mul(7_907));
        let inc = ((s as u64) << 1) | 1;
        let mut q = 1.05 + 0.20 * pcg32_unit(&mut st, inc);
        let mut p = 0.30 * pcg32_unit(&mut st, inc);
        let h0 = 0.5 * p * p + 0.5 * q * q + 0.25 * q.powi(4);
        let mut max_dh = 0.0_f64;
        let u_star = a_k + b_k;
        let v_star = b_k / (u_star * u_star);
        let mut u = [u_star; M];
        let mut v = [v_star; M];
        let mut u_next = [0.0_f64; M];
        let mut v_next = [0.0_f64; M];
        for j in 0..M {
            let phase = 2.0 * std::f64::consts::PI * 4.0 * (j as f64) / (M as f64);
            u[j] = u_star + 0.05 * phase.cos() + 0.02 * pcg32_unit(&mut st, inc);
            v[j] = v_star + 0.015 * pcg32_unit(&mut st, inc);
        }
        for _ in 0..140 {
            // Non-symplectic Explicit Euler (destroys Liouville 2-form)
            let q_next = q + dt * p;
            let p_next = p - dt * (q + q.powi(3));
            q = q_next.clamp(-20.0, 20.0);
            p = p_next.clamp(-20.0, 20.0);
            for j in 0..M {
                let jm = (j + M - 1) % M;
                let jp = (j + 1) % M;
                let lap_u = u[jm] - 2.0 * u[j] + u[jp];
                let lap_v = v[jm] - 2.0 * v[j] + v[jp];
                let u2v = u[j] * u[j] * v[j];
                u_next[j] = (u[j] + dt * (du_base * lap_u + a_k - u[j] + u2v)).clamp(0.05, 4.0);
                v_next[j] = (v[j] + dt * (dv_base * lap_v + b_k - u2v)).clamp(0.05, 4.0);
            }
            u = u_next;
            v = v_next;
            let dh = (0.5 * p * p + 0.5 * q * q + 0.25 * q.powi(4) - h0).abs();
            if dh > max_dh { max_dh = dh; }
        }
        let mean_u = u.iter().sum::<f64>() / (M as f64);
        let var_u = u.iter().map(|&x| (x - mean_u) * (x - mean_u)).sum::<f64>() / (M as f64);
        let sigma_u = var_u.sqrt();
        coh[s] = (0.58 * (-max_dh / 0.14).exp() + 0.42 * (sigma_u / 0.12).clamp(0.0, 1.0)).clamp(0.0, 1.0);
        dh_arr[s] = max_dh;
        contrast_arr[s] = sigma_u;
    }
    (mean_ci95(&coh), mean_ci95(&dh_arr), mean_ci95(&contrast_arr))
}

fn main() {
    let (ia, ib, base_seed) = (10_usize, 11_usize, 26660_u64);
    let (mut best_eta, mut best_m) = (0.05_f64, -1.0_f64);
    for step in 1..=27_usize {
        let eta = (step as f64) * 0.05;
        let ((m, _), _, _) = simulate(ia, ib, base_seed, eta);
        if m > best_m { best_m = m; best_eta = eta; }
    }
    let (se, dhe, cue) = simulate_explicit_euler_baseline(ia, ib, base_seed);
    let (s0, _, _) = simulate(ia, ib, base_seed, 0.00);
    let (sw, _, _) = simulate(ia, ib, base_seed, 0.15);
    let (so, dh, cu) = simulate(ia, ib, base_seed, best_eta);
    let (sv, _, _) = simulate(ia, ib, base_seed, 1.35);
    let digest = fnv_digest(ia * 16 + ib, &[best_eta, s0.0, sw.0, so.0, sv.0]);
    println!("euler_baseline={:.3} +- {:.3} |dH|={:.3} +- {:.3} sigma_u={:.3} +- {:.3}", se.0, se.1, dhe.0, dhe.1, cue.0, cue.1);
    println!("eta_star={best_eta:.2} (expected 0.30)");
    println!("coherence={:.3} +- {:.3} |dH|={:.3} +- {:.3} sigma_u={:.3} +- {:.3}", so.0, so.1, dh.0, dh.1, cu.0, cu.1);
    println!("FNV1a-64=0x{digest}");
}
