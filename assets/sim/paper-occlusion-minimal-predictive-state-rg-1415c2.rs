//! Standalone zero-dependency verification script for the 5-experiment Visual Occlusion
//! Minimal Predictive State & RG Coarse-Graining study (`base_seed = 0x20261119141500c2`).
//! Compile & run: `rustc -O <file>.rs -o occlusion_sim && ./occlusion_sim`

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

fn sample_noise(rng: &mut u64, b: usize) -> f64 {
    let mut acc = 0.0;
    for _ in 0..b { acc += splitmix64(rng); }
    (acc / (b as f64)) / (b as f64).powf(0.35)
}

fn run_cond(seed: u64, mode: u8, block_b: usize, env: u8, dt_occ: f64) -> ((f64, f64), (f64, f64)) {
    let mut safe = [0.0_f64; 200];
    let mut v_arr = [0.0_f64; 200];
    let dt = 0.002_f64;
    for s in 0..200_usize {
        let mut rng = seed.wrapping_add((s as u64).wrapping_mul(7919));
        let mut z = 32.0 + 2.0 * splitmix64(&mut rng);
        let mut v = 10.5 + 4.5 * splitmix64(&mut rng);
        let r0 = 1.05 + 0.75 * splitmix64(&mut rng);
        let rot_phase = std::f64::consts::PI * splitmix64(&mut rng);
        let a_ext = if env == 1 { 3.50 } else { 0.0 };
        let (mut tau_hat, mut gamma_hat, mut a_ext_hat, mut last_u) = (3.0, 1.0 / 10.5, 0.0, 0.0);
        let mut om_ring = [0.0_f64; 50];
        let mut dv_ring = [0.0_f64; 26];
        let mut dz_ring = [0.0_f64; 26];
        let (mut tau0_bar, mut dv_int, mut dz_int, mut in_blk) = (0.0, 0.0, 0.0, false);
        let (mut s11, mut s12, mut s22, mut sy1, mut sy2) = (0.0, 0.0, 0.0, 0.0, 0.0);
        for step in 0..16_000_usize {
            let t = (step as f64) * dt;
            if z <= 0.02 || v <= 0.01 { break; }
            if !in_blk && dt_occ > 0.0 && step >= 460 && (z / v.max(0.1)) <= dt_occ { in_blk = true; }
            let u_cmd = if !in_blk {
                let r_eff = if env == 2 { r0 * (1.0 + 0.22 * (5.5 * t + rot_phase).sin()) } else { r0 };
                let r_dot = if env == 2 { r0 * 0.22 * 5.5 * (5.5 * t + rot_phase).cos() } else { 0.0 };
                let theta = 2.0 * (r_eff / z).atan();
                let td_g = 2.0 * (r_dot * z + r_eff * v) / (z * z + r_eff * r_eff);
                let ap = ((block_b as f64) * 0.0028) / theta.max(0.025);
                let xi = sample_noise(&mut rng, block_b);
                let td_obs = (td_g / (1.0 + 0.16 * ap * ap) * (1.0 + 0.30 * xi)).max(1e-5);
                let om = td_obs / theta.sin().max(1e-6);
                let tau_obs = (1.0 / om).clamp(0.02, 35.0);
                om_ring[step % 50] = om;
                if step == 49 { tau0_bar = 1.0 / (om_ring.iter().sum::<f64>() / 50.0).max(1e-5); }
                if step >= 25 { dv_ring[step % 26] = dv_int; dz_ring[step % 26] = dz_int; }
                if step >= 100 {
                    let tau_bar = 1.0 / (om_ring.iter().sum::<f64>() / 50.0).max(1e-5);
                    let dt_w = ((step - 50) as f64) * dt;
                    let dvm = dv_ring[(step + 1) % 26];
                    let dzm = dz_ring[(step + 1) % 26];
                    let x1 = tau_bar - tau0_bar + dt_w;
                    let x2 = dt_w * tau_bar + 0.5 * dt_w * dt_w;
                    let yr = dvm * tau_bar + dzm;
                    if mode == 5 {
                        s11 += x1 * x1; s12 += x1 * x2; s22 += x2 * x2; sy1 += x1 * yr; sy2 += x2 * yr;
                        let det = s11 * s22 - s12 * s12;
                        if step >= 420 && det > 1e-6 {
                            let v0_3 = ((sy1 * s22 - s12 * sy2) / det).clamp(1.5, 30.0);
                            a_ext_hat = ((s11 * sy2 - sy1 * s12) / det).clamp(-2.0, 5.5);
                            let vn = (v0_3 - dv_int + a_ext_hat * ((step - 25) as f64 * dt)).clamp(0.35, 30.0);
                            gamma_hat = 1.0 / vn;
                        }
                    } else if step >= 220 {
                        let v0_2 = (yr / x1.max(0.04)).clamp(1.5, 30.0);
                        let vn = (v0_2 - dv_int).clamp(0.35, 30.0);
                        gamma_hat = 1.0 / vn;
                    }
                    let dv_tail = dv_int - dvm;
                    let net_tail = dv_tail - a_ext_hat * 25.0 * dt;
                    tau_hat = (tau_bar - 25.0 * dt + tau_bar * gamma_hat * net_tail).max(0.02);
                } else { tau_hat = tau_obs; }
                if step < 220 { 6.20 } else if step < 440 { 0.10 }
                else if mode == 5 { ((0.50 / (tau_hat * gamma_hat).max(1e-4)) + a_ext_hat.max(0.0)).clamp(0.0, 9.0) }
                else if mode >= 4 { (0.50 / (tau_hat * gamma_hat).max(1e-4)).clamp(0.0, 9.0) }
                else { (0.50 * v / tau_obs).clamp(0.0, 9.0) }
            } else {
                match mode {
                    0 => 0.0,
                    1 => last_u,
                    2 => { tau_hat = (tau_hat - dt).max(0.015); (0.50 * 10.5 / tau_hat).clamp(0.0, 9.0) }
                    3 => { let u = (0.50 * 10.5 / tau_hat.max(0.02)).clamp(0.0, 9.0); tau_hat = (tau_hat - 0.50 * dt).max(0.02); u }
                    4 => {
                        let u = (0.50 / (tau_hat * gamma_hat).max(1e-4)).clamp(0.0, 9.0);
                        tau_hat = (tau_hat + (-1.0 + tau_hat * gamma_hat * u) * dt).max(0.015);
                        gamma_hat = (gamma_hat + gamma_hat * gamma_hat * u * dt).clamp(0.02, 40.0);
                        u
                    }
                    5 => {
                        let u = ((0.50 / (tau_hat * gamma_hat).max(1e-4)) + a_ext_hat.max(0.0)).clamp(0.0, 9.0);
                        let ue = u - a_ext_hat;
                        tau_hat = (tau_hat + (-1.0 + tau_hat * gamma_hat * ue) * dt).max(0.015);
                        gamma_hat = (gamma_hat + gamma_hat * gamma_hat * ue * dt).clamp(0.02, 40.0);
                        u
                    }
                    _ => {
                        let dr = 0.09 * splitmix64(&mut rng);
                        let u = ((0.50 / (tau_hat * gamma_hat).max(1e-4)) * (1.0 + dr)).clamp(0.0, 9.0);
                        tau_hat = (tau_hat + (-1.0 + tau_hat * gamma_hat * u) * dt).max(0.015);
                        gamma_hat = (gamma_hat + gamma_hat * gamma_hat * u * dt).clamp(0.02, 40.0);
                        u
                    }
                }
            };
            if step >= 25 && !in_blk { dz_int += dv_int * dt + 0.5 * u_cmd * dt * dt; dv_int += u_cmd * dt; }
            last_u = u_cmd;
            let net = u_cmd - a_ext;
            z = (z - v * dt - 0.5 * net * dt * dt).max(0.0);
            v = (v - net * dt).max(0.0);
        }
        safe[s] = if v <= 0.55 && z <= 0.75 { 1.0 } else { 0.0 };
        v_arr[s] = v;
    }
    (mean_ci95_200(&safe), mean_ci95_200(&v_arr))
}

fn main() {
    let seed = 2316557857737474242_u64;
    let (s_d0z, _) = run_cond(seed, 0, 1, 0, 1.20);
    let (s_d0h, _) = run_cond(seed, 1, 1, 0, 1.20);
    let (s_d1b, _) = run_cond(seed, 2, 1, 0, 1.20);
    let (s_d1p, _) = run_cond(seed, 3, 1, 0, 1.20);
    let (s_d2, _)  = run_cond(seed, 4, 8, 0, 1.20);
    let (s_d64, _) = run_cond(seed, 6, 1, 0, 1.20);
    let (s_e2_d2, _) = run_cond(seed, 4, 8, 1, 1.20);
    let (s_e2_d3, _) = run_cond(seed, 5, 8, 1, 1.20);
    let dig = fnv_digest_f64s(1415, &[s_d0z.0, s_d0h.0, s_d1b.0, s_d1p.0, s_d2.0, s_d64.0, s_e2_d2.0, s_e2_d3.0]);
    println!("d=0 zero: {:.3} +- {:.3}", s_d0z.0, s_d0z.1);
    println!("d=1 ball: {:.3} +- {:.3} (falsified)", s_d1b.0, s_d1b.1);
    println!("d=2 R_8 : {:.3} +- {:.3} (minimal closure)", s_d2.0, s_d2.1);
    println!("E2 d=2->d=3: {:.3} -> {:.3}", s_e2_d2.0, s_e2_d3.0);
    println!("FNV1a-64=0x{dig} (expected 0x715bfce92debd895)");
}
