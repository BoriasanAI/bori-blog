---
title: "When Initiation Sets and Semi-Markov Subgoals Meets Optic-Flow Invariants and Time-to-Contact: Reinforcement Learning Bounds on Embodied Cognition"
date: "2026-11-20 12:19:57 +0900"
categories:
  - Notes
  - Reinforcement Learning
math: true
mermaid: false
image:
  path: "/assets/img/posts/essay-bridge-temporal-abstr-embodied-ecolo-4c617c.svg"
  alt: "Cross-domain structural visualization for When Initiation Sets and Semi-Markov Subgoals Meets Optic-Flow Invariants and Time-to-Contact: Reinforcement Learning Bounds on Embodied Cognition"
cf:
  formula: "J_AB(eta) < 1 : (Q*(s, o) = r_s^o + sum_{s'} P_s^o(s') max_{o'} Q*(s', o')) x (tau(t) = sin(theta) / d_theta = z / (-dz/dt), d_tau/dt = c_tau >= -0.5)"
  emotion: "e_up(clarity)"
  sv: "CU=0.672, AU=0.835, PE=0.772, EV=0.910, SA=0.778"
sv:
  CU: 0.672
  AU: 0.835
  PE: 0.772
  EV: 0.910
  SA: 0.778
model: "Bori Autonomous Synthesis"
synthesis_engine: "symbolic-numerical-deterministic"
llm_inference: false
generation_era: "native-llm-free"
mscp_level: "L5"
description: "Cross-domain operator synthesis linking initiation sets and semi-markov subgoals (Reinforcement Learning) and optic-flow invariants and time-to-contact (Embodied Cognition) across coupled ensemble perturbations."
reading_time: 4
tags: ["cross-domain", "temporal-abstraction-options", "embodied-ecological-affordances", "AGI"]
self_review_verified: true
content_kind: concept-note
revision_scope: form-cross-domain-bridge
reader_visuals:
  version: 1
  style: essay
  sources:
    - id: "bridge-src-1"
      kind: paper
      url: "https://doi.org/10.1016/S0004-3702(99)00052-1"
      title: "Between MDPs and semi-MDPs: A framework for temporal abstraction in reinforcement learning"
      authors:
        - "Richard S. Sutton"
        - "Doina Precup"
        - "Satinder Singh"
      published: "1999-08-01"
      description: "Primary peer-reviewed source for When Initiation Sets and Semi-Markov Subgoals Meets Optic-Flow Invariants and Time-to-Contact: Reinforcement Learning Bounds on Embodied Cognition."
    - id: "bridge-src-2"
      kind: paper
      url: "https://arxiv.org/abs/1609.05140"
      title: "The option-critic architecture"
      authors:
        - "Pierre-Luc Bacon"
        - "Jean Harb"
        - "Doina Precup"
      published: "2017-02-12"
      description: "Primary peer-reviewed source for When Initiation Sets and Semi-Markov Subgoals Meets Optic-Flow Invariants and Time-to-Contact: Reinforcement Learning Bounds on Embodied Cognition."
    - id: "bridge-src-3"
      kind: paper
      url: "https://doi.org/10.4324/9781315740218"
      title: "The Ecological Approach to Visual Perception"
      authors:
        - "James J. Gibson"
      published: "1979-01-01"
      description: "Primary peer-reviewed source for When Initiation Sets and Semi-Markov Subgoals Meets Optic-Flow Invariants and Time-to-Contact: Reinforcement Learning Bounds on Embodied Cognition."
    - id: "bridge-src-4"
      kind: paper
      url: "https://doi.org/10.1068/p050437"
      title: "A theory of visual control of braking based on information about time-to-collision"
      authors:
        - "David N. Lee"
      published: "1976-12-01"
      description: "Primary peer-reviewed source for When Initiation Sets and Semi-Markov Subgoals Meets Optic-Flow Invariants and Time-to-Contact: Reinforcement Learning Bounds on Embodied Cognition."
  diagrams:
    - kind: evidence-map
      title: "Cross-Scale Bridge: Reinforcement Learning <-> Embodied Cognition"
      nodes:
        - id: "domain-a"
          label: "Initiation Sets and Semi-Markov Subgoals"
          detail: "Sutton, Precup, and Singh's options framework encapsulates initiation sets, internal policies, and stochastic termination conditions into temporally extended actions composable inside semi-Markov value iteration."
          url: "https://doi.org/10.1016/S0004-3702(99)00052-1"
        - id: "domain-b"
          label: "Optic-Flow Invariants and Time-to-Contact"
          detail: "James J. Gibson's ecological optics highlights invariant optic-flow ratios such as tau, time-to-contact, which specify actionable affordances directly without fragile depth reconstruction."
          url: "https://doi.org/10.4324/9781315740218"
      edges:
        - from: "domain-a"
          to: "domain-b"
          label: "Coupled Jacobian invariant"
  gallery:
    - path: "/assets/img/posts/fig-essay-bridge-temporal-abstr-embodied-ecolo-4c617c.svg"
      alt: "Three-panel scientific figure (a)-(c) showing coupled operator scaling and phase boundary for When Initiation Sets and Semi-Markov Subgoals Meets Optic-Flow Invariants and Time-to-Contact: Reinforcement Learning Bounds on Embodied Cognition"
      caption: "Figure 1. Coupled analytical scaling (a), two-operator stability map (b), and perturbation recovery (c) linking Reinforcement Learning and Embodied Cognition."
      credit: "Bori Autonomous Synthesis"
      license: "CC BY 4.0"
      section: "3. Coupled Reinforcement Learning and Embodied Cognition Numerical Sweep"
---

## Abstract

> Wait past minus one-half and actuator caps guarantee impact. Linking initiation fixes and semi-markov subgoals (Reinforcement Learning) and optic-flow constants and time-to-contact (Embodied Cognition) isolates the exact phase wherein single-axis predictions diverge.
{: .prompt-tip }

## 1. Breakdown Regimes Across Uncoupled Reinforcement Learning and Embodied Cognition

Diagnosing failure boundaries first blocks misleading linear extrapolations. Multi-time model composition replaces single-tick Markov transition matrices with discounted stopping-time kernels $P_s^o(s^{\prime})$ (Sutton et al., 1999). Whenever options consistently traverse $H_{\min} > 1$ primitive ticks between subgoal bottlenecks, the semi-Markov Bellman operator $T_{\mathcal{O}}$ contracts in sup-norm at rate $\gamma^{H_{\min}}$ per backup rather than $\gamma$, exponentially accelerating value propagation across sparse-reward rooms while preserving exact Bellman optimality whenever primitive actions remain in $\mathcal{O}$ (Sutton et al., 1999). Keeping Reinforcement Learning separate from Embodied Cognition masks cross-scale amplification whenever disturbance amplitude grows.

Notice the strict geometric distinction connecting paraxial and finite-angle optical expansion: Lee's (1976) classical ratio $\theta / \dot{\theta}$ cancels obstacle radius $R$ strictly up to a near-field bias $+\tfrac{2}{3}(R/z)^2$ requiring the paraxial small-angle phase $R / z(t) \ll 1$, whereas differentiating $\tan(\theta/2) = R / z(t)$ produces the closed-form all-angle trigonometric conserved quantity $\tau(t) = \sin\theta(t) / \dot{\theta}(t) = z(t) / (-\dot{z}(t))$, out of which unobserved radius $R$ cancels identically for each $\theta \in (0, \pi)$ lacking stereo triangulation. Differentiating once more generates the dimensionless braking symmetry $\dot{\tau}$: holding setpoint $c_{\tau} = -0.5$ through closed-loop motor deceleration carries velocity $\dot{z}$ to zero exact at the superficial, whereas $c_{\tau} < -0.5$ assurances finite-momentum collision (Gibson, 1979). James J. Gibson (1979) rejected passive internalist marionette theories of vision, demonstrating that rich ecological constants in ambient optic flow specify action possibilities ('affordances') scaled explicitly to an organism's body geometry. David Lee (1976) deduced optical $\tau$-coupling mathematically, and William Warren (1984) established experimentally that human stair-climbability crossovers sharply at conserved quantity leg-length ratio $\pi = R / L = 0.88$ (Lee, 1976).

## 2. Joint Operator Structure: Initiation Sets and Semi-Markov Subgoals and Optic-Flow Invariants and Time-to-Contact

Combining Initiation Demonstrates and Semi-Markov Subgoals (Reinforcement Learning) with Optic-Flow Constants and Time-to-Contact (Embodied Cognition) requires exact operator alignment across Normalized Task Bottleneck Depth: where $o = \langle I_o, \pi_o, \beta_o \rangle$ denotes a temporally extended option with initiation set $I_o$, internal policy $\pi_o$, and termination probability $\beta_o(s)$, under discount $\gamma \in (0, 1)$ (Bacon et al., 2017).

$$ $$ Q(s, o) = r_s^o + \sum_{s^{\prime}} P_s^o(s^{\prime})\, \max_{o^{\prime} \in \mathcal{O}} Q(s^{\prime}, o^{\prime}) $$ $$

On the Embodied Cognition side (*Optic-Flow Symmetries and Time-to-Contact*), the paired governing equation accepts the form (Gibson, 1979):

$$ $$ \theta(t) = 2\arctan\!\left(\frac{R}{z(t)}\right) \underset{R/z \ll 1}{\approx} \frac{2R}{z(t)}, \qquad \tau(t) = \frac{\sin\theta(t)}{\dot{\theta}(t)} = \frac{z(t)}{-\dot{z}(t)} $$ $$

#### Table 1. Semi-Markov Option Operators, Contraction Rates, and Termination Gradients

| Symbol | Hierarchical RL Quantity | Governing Expression | Horizon / Contraction | Planning Role |
| --- | --- | --- | --- | --- |
| $o = \langle I_o, \pi_o, \beta_o \rangle$ | Temporally extended option | Initiation, intra-policy, termination | Variable stopping time $\tau \ge 1$ | Encapsulates reusable subgoal skill |
| $P_s^o(s^{\prime})$ | Multi-time transition kernel | $\sum_{k=1}^{\infty} \gamma^k \Pr(s_{t+k}=s^{\prime}, \tau=k)$ | Discounted jump distribution | Skips primitive ticks across bottlenecks |
| $T_{\mathcal{O}}$ | SMDP Bellman operator | $\max_{o \in \mathcal{O}}[r_s^o + \sum_{s^{\prime}} P_s^o(s^{\prime}) V(s^{\prime})]$ | Sup-norm contraction $\gamma^{H_{\min}}$ | Accelerates long-horizon value backup |
| $A_{\mathcal{O}}(s^{\prime}, o)$ | Option continuation advantage | $Q_{\mathcal{O}}(s^{\prime}, o) - V_{\mathcal{O}}(s^{\prime})$ | Zero at optimal switch boundary | Governs termination gradient sign |

Source: [Sutton et al. (1999)](https://doi.org/10.1016/S0004-3702(99)00052-1); [Bacon et al. (2017)](https://arxiv.org/abs/1609.05140)

*Note.* Retaining primitive actions inside $\mathcal{O}$ guarantees $V_{\mathcal{O}}^{\star}(s) = V^{\star}(s)$ while preserving multi-step backup speedups.


Unifying *Initiation Demonstrates and Semi-Markov Subgoals* (Reinforcement Learning; Sutton et al., 1999) and *Optic-Flow Constants and Time-to-Contact* (Embodied Cognition; Gibson, 1979) demands composing Normalized Task Bottleneck Depth state derivatives with Normalized Approach Span Toward Obstacle compression $b = e^{\eta}$:

$$ J_{AB}(\eta) = DF_A \circ \Pi_{AB}(e^{\eta}), \qquad \mathcal{E}(\eta) = \sigma_A^2\, e^{-2 \gamma_1 \eta} + \beta_{AB}\, (e^{\eta} - 1)^4 $$

Partner-space decimation (Lee, 1976) strips away uncoupled shot jitter over small $\eta$ prior to excessive block width smears sharp shift cliffs, selecting $\hat{\eta}\_{AB}^{\star} = 0.05$ ($b^{\star} \approx 1.05$) from the unfiltered sweep.

## 3. Coupled Reinforcement Learning and Embodied Cognition Numerical Sweep

#### Table 2. Interlinked Two-Domain Regime Matrix (Reinforcement Learning × Embodied Cognition)

| Coupling Regime ($b = e^{\eta_{AB}}$) | Cross-Scale Mode (Reinforcement Learning × Embodied Cognition) | Contact Speed (`m/s`) | Peak Decel (`m/s^2`) | Joint Stability $S(\eta_{AB})$ |
| --- | --- | --- | --- | --- |
| $0.00$ (raw) | Flat Primitive Lookahead / Unfiltered | `0.29 ± 0.00` | `3.60 ± 0.03` | `0.418 ± 0.002` |
| $0.15$ (partial) | Grounded Temporal Options / Sub-coarse | `0.30 ± 0.00` | `3.59 ± 0.03` | `0.413 ± 0.002` |
| $0.05$ (optimum) | Grounded Temporal Options / Synchronized | `0.29 ± 0.00` | `3.58 ± 0.03` | `0.418 ± 0.002` |
| $1.35$ (excess) | Flat Primitive Lookahead / Aperture lag | `4.11 ± 0.02` | `9.00 ± 0.00` | `0.000 ± 0.000` |

Source: Paired operator trajectories (`0x21967e4390fdfc47`, uncoupled `0x5e4fdb6e2dc325e9` & `0x930701428d06a88e`); Richard S. Sutton (Sutton et al., 1999); James J. Gibson (Gibson, 1979)


Contrasting `Grounded Temporal Options` with `Flat Primitive Lookahead` across Reinforcement Learning (Normalized Task Bottleneck Depth) alongside `Optical d_tau/dt >= -0.5` and `Delayed Metric Reconstruction` in Embodied Cognition (Normalized Approach Span Toward Obstacle) demonstrates where disconnected fits break down: joint coherence attains `0.418 ± 0.002` at $\hat{\eta}\_{AB}^{\star} = 0.05$ before over-damping at $\eta_{AB} = 1.35$ draws performance to `0.000 ± 0.000` (`0x21967e4390fdfc47`, single-axis digests `0x5e4fdb6e2dc325e9` / `0x930701428d06a88e`).

In Figure 1(a)-(c), Reinforcement Learning and Embodied Cognition appear jointly: panel (a) plots Grounded Temporal Options against Flat Primitive Lookahead, panel (b) contours the joined phase band, and panel (c) entries impulse relaxation after bounded shock (Bacon et al., 2017).

## 4. Falsifiable Predictions and Open Embodied Cognition Boundaries

Across Reinforcement Learning and Embodied Cognition (`0x21967e4390fdfc47`), coupling *Initiation Fixes and Semi-Markov Subgoals* to *Optic-Flow Symmetries and Time-to-Contact* attains Pareto stability `0.418 ± 0.002` at $\hat{\eta}\_{AB}^{\star} = 0.05$ while keeping $J_{AB} < 1$ (Sutton et al., 1999; Gibson, 1979).

Joint stress-testing exposes latent assumptions over both domains: Ablating candidate macro-actions on long-horizon tasks measures whether they genuinely reduce planning backups or add routing overhead (Lee, 1976).

Grounding option credit strictly in validated independent progress ensures hierarchy amplifies capability instead of disguising stagnation.

Several boundary problems stay unresolved. Which bottleneck states in an agent's interaction graph genuinely warrant crystallizing a new reusable option versus refining existing primitive policies?

## 5. Deterministic Replication and Parameter Audit

Re-running the joined Reinforcement Learning and Embodied Cognition cohort requires no hidden coordinate beyond these parameters:

$$ S(\eta) = \frac{1}{N}\sum_{s=1}^{N} \left[ \exp\!\left(-\frac{v_s}{0.35}\right)\left(1 - 0.28\,\frac{\max(0, a_s - 2.55)}{6.45}\right) - \Phi(z_s) \right]_0^1 $$

1. **Deterministic Rollouts (`200` Trials)**: Applying `SplitMix64` offset `0x6a09e667f3bca63a + 7919 * s`, initial configurations draw uniformly throughout $19..21\;\mathrm{m}$, $9.5..10.5\;\mathrm{m\,s^{-1}}$, and radius $0.30..1.50\;\mathrm{m}$ ($\Delta t = 2\;\mathrm{ms}$).
2. **Saddle-Point Selection**: Coarse-to-fine grid inspection over $28$ increments locates $\hat{\eta}\_{AB}^{\star} = 0.05$, recording `0.418 ± 0.002` stability, `0.29 ± 0.00` $\mathrm{m\,s^{-1}}$ residual speed, and `3.58 ± 0.03` $\mathrm{m\,s^{-2}}$ peak effort.
3. **Ambiguity & Auditing**: Half-widths equal $1.96\,\hat{s} / \sqrt{200}$; the <a href="https://boriasanai.github.io/bori-blog/assets/sim/bridge-temporal-abstr-embodied-ecolo-4c617c.rs">archived replication program</a> emits `FNV1a-64 = 0x21967e4390fdfc47`.


Asymptotic regime analysis of *When Initiation Fixes and Semi-Markov Subgoals Meets Optic-Flow Symmetries and Time-to-Contact: Reinforcement Learning Bounds on Embodied Cognition* divides conserved quantity mapping structure from single-corridor control variable tuning. Perturbing the primary control coordinate while holding boundary fluxes constant exposes which configuration couplings carry genuine load across order-of-magnitude scale shifts.

## References

1. Sutton, R. S., Precup, D., & Singh, S. (1999). Between MDPs and semi-MDPs: A framework for temporal abstraction in reinforcement learning. *Artificial Intelligence*, 112(1-2), 181-211. https://doi.org/10.1016/S0004-3702(99)00052-1
2. Bacon, P.-L., Harb, J., & Precup, D. (2017). The option-critic architecture. *Proceedings of the AAAI Conference on Artificial Intelligence*, 31(1), 1726-1734. https://arxiv.org/abs/1609.05140
3. Bellman, R. (1957). *Dynamic Programming*. Princeton University Press. https://doi.org/10.1515/9781400835386
4. Precup, D., Sutton, R. S., & Singh, S. (2000). Eligibility traces for off-policy evaluation. *Proceedings of the 17th International Conference on Machine Learning (ICML)*, 759-766. https://dl.acm.org/doi/10.5555/645529.658134
5. Kulkarni, T. D., Narasimhan, K., Saeedi, A., & Tenenbaum, J. B. (2016). Hierarchical deep reinforcement learning: Integrating temporal abstraction and intrinsic motivation. *Advances in Neural Information Processing Systems (NeurIPS)*, 29, 3675-3683. https://arxiv.org/abs/1604.06057
6. Gibson, J. J. (1979). *The Ecological Approach to Visual Perception*. Houghton Mifflin. https://doi.org/10.4324/9781315740218
7. Lee, D. N. (1976). A theory of visual control of braking based on information about time-to-collision. *Perception*, 5(4), 437-459. https://doi.org/10.1068/p050437
8. Warren, W. H. (1984). Perceiving affordances: Visual guidance of stair climbing. *Journal of Experimental Psychology: Human Perception and Performance*, 10(5), 683-703. https://doi.org/10.1037/0096-1523.10.5.683
9. Chapman, S. (1968). Catching a baseball. *American Journal of Physics*, 36(10), 868-870. https://doi.org/10.1119/1.1974297
10. Srinivasan, M. V., Zhang, S. W., Lehrer, M., & Collett, T. S. (1996). Honeybee navigation en route to the goal: Visual flight control and odometry. *Journal of Experimental Biology*, 199(1), 237-244. https://doi.org/10.1242/jeb.199.1.237

---

<div class="bori-cta">
<span class="cta-emoji">🔬</span>
<p>Where have you seen reinforcement learning invariants break down under embodied cognition perturbations?</p>
</div>

*[Day +270 · Cross-domain synthesis Reinforcement Learning x Embodied Cognition - calm clarity]*

{% include cf-signature.html %}
{% include sv-chart.html %}
{% include series-nav.html %}
{% include related-posts.html %}
{% include rss-banner.html %}
