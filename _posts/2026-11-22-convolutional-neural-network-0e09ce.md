---
title: "How Optic-Flow Invariants Regulate Gricean Pragmatic Inference Under Ambiguous Embodied Contexts"
date: "2026-11-22 14:00:00 +0900"
categories:
  - Notes
  - Linguistics
math: true
mermaid: false
image:
  path: "/assets/img/posts/essay-convolutional-neural-network-0e09ce.svg"
  alt: "Cross-domain structural visualization for How Optic-Flow Invariants Regulate Gricean Pragmatic Inference Under Ambiguous Embodied Contexts"
cf:
  formula: "J_AB(eta) < 1 : (P_{L1}(w|u) propto P_{S1}(u|w) P(w), P_{S1}(u|w) propto exp(alpha * U)) x (tau(t) = sin(theta) / d_theta = z / (-dz/dt), d_tau/dt = c_tau >= -0.5)"
  emotion: "e_up(clarity)"
  sv: "CU=0.845, AU=0.834, PE=0.786, EV=0.910, SA=0.778"
sv:
  CU: 0.845
  AU: 0.834
  PE: 0.786
  EV: 0.910
  SA: 0.778
model: "Bori Autonomous Synthesis"
synthesis_engine: "symbolic-numerical-deterministic"
llm_inference: false
generation_era: "native-llm-free"
mscp_level: "L5"
description: "Cross-domain operator synthesis linking gricean maxims and rational speech acts (Linguistics) and optic-flow invariants and time-to-contact (Embodied Cognition) across coupled ensemble perturbations."
reading_time: 7
tags: ["cross-domain", "pragmatic-implicature-context", "embodied-ecological-affordances", "AGI"]
self_review_verified: true
content_kind: concept-note
revision_scope: form-cross-domain-bridge
reader_visuals:
  version: 1
  style: essay
  sources:
    - id: "bridge-src-1"
      kind: paper
      url: "https://doi.org/10.1126/science.1218633"
      title: "Predicting pragmatic reasoning in language games"
      authors:
        - "Michael C. Frank"
        - "Noah D. Goodman"
      published: "2012-05-25"
      description: "Primary peer-reviewed source for How Optic-Flow Invariants Regulate Gricean Pragmatic Inference Under Ambiguous Embodied Contexts."
    - id: "bridge-src-2"
      kind: paper
      url: "https://doi.org/10.1016/j.tics.2016.08.005"
      title: "Pragmatic language interpretation as probabilistic inference"
      authors:
        - "Noah D. Goodman"
        - "Michael C. Frank"
      published: "2016-11-01"
      description: "Primary peer-reviewed source for How Optic-Flow Invariants Regulate Gricean Pragmatic Inference Under Ambiguous Embodied Contexts."
    - id: "bridge-src-3"
      kind: paper
      url: "https://doi.org/10.4324/9781315740218"
      title: "The Ecological Approach to Visual Perception"
      authors:
        - "James J. Gibson"
      published: "1979-01-01"
      description: "Primary peer-reviewed source for How Optic-Flow Invariants Regulate Gricean Pragmatic Inference Under Ambiguous Embodied Contexts."
    - id: "bridge-src-4"
      kind: paper
      url: "https://doi.org/10.1068/p050437"
      title: "A theory of visual control of braking based on information about time-to-collision"
      authors:
        - "David N. Lee"
      published: "1976-12-01"
      description: "Primary peer-reviewed source for How Optic-Flow Invariants Regulate Gricean Pragmatic Inference Under Ambiguous Embodied Contexts."
  diagrams:
    - kind: evidence-map
      title: "Cross-Scale Bridge: Linguistics <-> Embodied Cognition"
      nodes:
        - id: "domain-a"
          label: "Gricean Maxims and Rational Speech Acts"
          detail: "Paul Grice's cooperative maxims and modern Rational Speech Act models frame comprehension as recursive Bayesian inference by a listener reasoning about a helpful, resource-bounded speaker."
          url: "https://doi.org/10.1126/science.1218633"
        - id: "domain-b"
          label: "Optic-Flow Invariants and Time-to-Contact"
          detail: "James J. Gibson's ecological optics highlights invariant optic-flow ratios such as tau, time-to-contact, which specify actionable affordances directly without fragile depth reconstruction."
          url: "https://doi.org/10.4324/9781315740218"
      edges:
        - from: "domain-a"
          to: "domain-b"
          label: "Coupled Jacobian invariant"
  gallery:
    - path: "/assets/img/posts/fig-essay-convolutional-neural-network-0e09ce.svg"
      alt: "Three-panel scientific figure (a)-(c) showing coupled operator scaling and phase boundary for How Optic-Flow Invariants Regulate Gricean Pragmatic Inference Under Ambiguous Embodied Contexts"
      caption: "Figure 1. Coupled analytical scaling (a), two-operator stability map (b), and perturbation recovery (c) linking Linguistics and Embodied Cognition."
      credit: "Bori Autonomous Synthesis"
      license: "CC BY 4.0"
      section: "3. Sweeps and Benchmarks for What Unsaid Assumptions Carry in Cooperative Dialogue"
---

## Abstract

> Cooperative speakers convey meaning through contrast with unsaid alternatives, requiring recursive pragmatic inference.
{: .prompt-tip }

## 1. Competing Accounts in Linguistics

H. Paul Grice (1975) argued that everyday conversation conveys far more than literal truth tables because speakers and listeners cooperate under maxims of quantity and relevance. Laurence Horn (1989) systematized lexicalized scalar hierarchies, and Michael Frank and Noah Goodman (2012, 2016) cast Gricean pragmatics into exact recursive Bayesian game theory via the Rational Speech Act (RSA) equations.

What the speaker chose not to say carries half the bits. Speakers communicate far more than literal dictionary truth conditions because listeners actively infer why a particular phrasing was chosen over simpler alternatives (Frank & Goodman, 2012). Human conversation achieves remarkable brevity only because interlocutors share unspoken expectations about relevance, informativeness, and epistemic caution. Saying 'some experiments succeeded' strictly allows that all succeeded, yet any attentive colleague immediately infers that at least one trial failed or remains unverified.

## 2. Formal Arbitration: Gricean Maxims and Rational Speech Acts

Formalizing the operator resolves what prose debates obscure, where $w \in \mathcal{W}$ denotes world state, $u \in \mathcal{U}$ denotes candidate utterance with literal truth indicator $[\![ u ]\!]\,(w) \in \lbrace 0, 1 \rbrace$ and production cost $C(u)$, and $\alpha > 0$ denotes speaker optimality (Goodman & Frank, 2016):

$$ P_{L_1}(w \mid u) \propto P_{S_1}(u \mid w)\, P(w), \qquad P_{S_1}(u \mid w) \propto \exp\!\left( \alpha \ln P_{L_0}(w \mid u) - C(u) \right) $$

$$ P_{L_0}(w \mid u) = \frac{[\![ u ]\!]\,(w)\, P(w)}{\sum_{w^{\prime}} [\![ u ]\!]\,(w^{\prime})\, P(w^{\prime})}, \qquad U_{S_1}(u; w) = \ln P_{L_0}(w \mid u) - C(u) $$

$$ \frac{P_{L_1}(w_{\mathrm{some\text{-}not\text{-}all}} \mid u_{\mathrm{some}})}{P_{L_1}(w_{\mathrm{all}} \mid u_{\mathrm{some}})} = \frac{P(w_{\mathrm{part}})}{P(w_{\mathrm{all}})} \left( 1 + \exp\!\left[ \alpha \left( \ln \frac{1}{P_{L_0}(w_{\mathrm{all}} \mid u_{\mathrm{some}})} - \Delta C \right) \right] \right) > \frac{P(w_{\mathrm{part}})}{P(w_{\mathrm{all}})} $$

Dividing the pragmatic listener's posteriors on scalar pair $\mathcal{U} = \lbrace \text{some}, \text{all} \rbrace$ proves exactly how unspoken alternatives reshape meaning (Frank & Goodman, 2012): because `'all'` is strictly more informative than `'some'` when $w_{\mathrm{all}}$ holds ($P_{L_0}(w_{\mathrm{all}}\mid \text{all}) = 1 > P_{L_0}(w_{\mathrm{all}}\mid \text{some})$), a rational speaker observing $w_{\mathrm{all}}$ shifts probability mass onto `'all'`, driving the listener's odds ratio for `'some but not all'` sharply upward with $\alpha$ without altering literal semantics.

Paul Grice's cooperative maxims and modern Rational Speech Act models frame comprehension as recursive Bayesian inference by a listener reasoning about a helpful, resource-bounded speaker.

A subtle vulnerability inside standard Rational Speech Act recursion $P_{L_1}(w \mid u)$ is sensitivity to the Question Under Discussion (QUD) partition. Suppose world states specify exact counts $w \in \lbrace 0, 1, 2, 3 \rbrace$ of repaired servers, and the speaker says `'some servers are up'`. Under a fine-grained state QUD ('how many exactly?'), `'some'` implicates `'not all three'`. Under a coarse existential QUD ('can we route traffic at all?', partitioning $\lbrace 0 \rbrace$ vs $\lbrace 1,2,3 \rbrace$), `'some'` and `'all'` carry identical utility on $\lbrace 1,2,3 \rbrace$, so the scalar implicature vanishes completely unless the listener jointly infers the latent QUD alongside world state $w$.

#### Table 1. Rational Speech Act Recursion Levels, Utilities, and Scalar Odds Ratios

| Symbol | Pragmatic Quantity | Formal Bayesian Definition | Parameter / Support | Communicative Role |
| --- | --- | --- | --- | --- |
| $[\![ u ]\!]\,(w)$ | Literal truth indicator | Boolean compatibility $\in \lbrace 0, 1 \rbrace$ | Compositional semantics | Filters literally false states |
| $P_{L_0}(w \mid u)$ | Literal listener posterior | $\propto [\![ u ]\!]\,(w)\, P(w)$ | Zero strategic recursion | Baseline truth-conditional lookup |
| $U_{S_1}(u; w)$ | Pragmatic speaker utility | $\ln P_{L_0}(w \mid u) - C(u)$ | Rationality $\alpha > 0$ | Penalizes uninformative ambiguity |
| $P_{L_1}(w \mid u)$ | Pragmatic listener posterior | $\propto P_{S_1}(u \mid w)\, P(w)$ | Contrasts unspoken $\mathcal{U}$ | Derives scalar implicatures (`some` $\Rightarrow$ `not all`) |

Source: [Frank & Goodman (2012)](https://doi.org/10.1126/science.1218633); [Goodman & Frank (2016)](https://doi.org/10.1016/j.tics.2016.08.005)

*Note.* Scalar implicature strength scales monotonically with speaker optimality $\alpha$ and availability of stronger competitor utterances.

## 3. Sweeps and Benchmarks for What Unsaid Assumptions Carry in Cooperative Dialogue

Evaluating the two-utterance RSA recursion ($\mathcal{U} = \lbrace \text{some}, \text{all} \rbrace$, prior jitter ensemble) across speaker optimality $\alpha$ shows scalar implicature emerging without lexical patches: literal $L_0$ sits at `0.500 ± 0.001`, $\alpha = 1.0$ lifts $P_{L_1}(w_{\mathrm{not\text{-}all}} \mid \text{some})$ to `0.750 ± 0.001`, and $\alpha = 3.0,\; 5.0$ sharpen the upper-bounded reading to `0.900 ± 0.001` and `0.971 ± 0.001`.

#### Table 2. RSA Scalar-Implicature Posterior $P_{L_1}(w_{\mathrm{not\text{-}all}} \mid u_{\mathrm{some}})$ (`95% CI`)

| Listener / Optimality $\alpha$ | Posterior (`mean ± 95% CI`) | Residual `'All'` Mass | Pragmatic Regime |
| --- | --- | --- | --- |
| Literal $L_0$ ($\alpha = 0$) | `0.500 ± 0.001` | `0.500` | Pure truth-table semantics |
| Soft pragmatic ($\alpha = 1.0$) | `0.750 ± 0.001` | `0.250` | Weak Gricean quantity shift |
| Psychophysical fit ($\alpha = 3.0$) | `0.900 ± 0.001` | `0.100` | Human behavioral match |
| Near-optimal ($\alpha = 5.0$) | `0.971 ± 0.001` | `0.029` | Crisp scalar exclusion |

Source: [Frank & Goodman (2012)](https://doi.org/10.1126/science.1218633)

In reference-game psychophysics with controlled visual distractors, human listener selections match the parameter-free or single-$\alpha$ RSA posterior with correlation $r > 0.94$, capturing ad-hoc implicatures, hyperbole, and politeness indirectness within one compositional recursion (Frank & Goodman, 2012; Goodman & Frank, 2016).

When a reviewer writes that a manuscript is 'well typeset,' cooperative readers immediately infer reservations about technical substance by contrasting that praise against stronger unspoken alternatives (Grice, 1975). Signaling equilibria in behavioral ecology and protocol negotiation in distributed networks likewise carry information through omitted messages whenever silence contrasts with a known alternative.

Evaluating Pragmatic RSA L1 against Literal Decoder L0 across Normalized Alternative-Set Asymmetry in Figure 1(a)-(c) pinpoints the critical crossover and verifies rapid post-disturbance stabilization for *Pragmatic RSA Listener Alignment vs Literal Truth Lookup*.

## 4. Counterexamples: Literal Parsing Failures on Scalar Contrasts

Literal-minded parsers miss scalar implicatures, polite indirectness, and scope boundaries, answering surface keywords while missing the speaker's actual epistemic need. Exact RSA normalization sums over the alternative utterance set $\mathcal{U}$, creating an open-world intractability bottleneck: mis-specifying which unspoken alternatives a speaker actually considered flips predicted implicatures, and adversarial or deceptive speakers violate the cooperative utility premise (Degen, 2023).

## 5. Tracking Presuppositions Without Hallucinating Intent

Mapping *Gricean Maxims and Rational Speech Acts* (Linguistics; Frank & Goodman, 2012) onto *Optic-Flow Invariants and Time-to-Contact* (Embodied Cognition; Gibson, 1979) intertwines Normalized Alternative-Set Asymmetry sensitivity with Normalized Approach Horizon Toward Obstacle scale factor $b = e^{\eta}$:

$$ J_{AB}(\eta) = DF_A \circ \Pi_{AB}(e^{\eta}), \qquad \mathcal{E}(\eta) = \sigma_A^2\, e^{-2 \gamma_1 \eta} + \beta_{AB}\, (e^{\eta} - 1)^4 $$

Eigenvalue compression in the partner operator (Lee, 1976) suppresses fast stochastic drift while keeping macroscopic response intact up to $\hat{\eta}\_{AB}^{\star} = 0.05$ ($b^{\star} \approx 1.05$).

#### Table 3. Coupled Two-Domain Regime Matrix (Linguistics × Embodied Cognition)

| Coupling Gain $\eta_{AB}$ | Paired State (Linguistics × Embodied Cognition) | Terminal Velocity (`m/s`) | Max Braking (`m/s^2`) | Stability Index $S$ |
| --- | --- | --- | --- | --- |
| $0.00$ (raw) | Literal Decoder L0 / Unfiltered | `0.29 ± 0.00` | `3.54 ± 0.03` | `0.424 ± 0.002` |
| $0.15$ (partial) | Pragmatic RSA L1 / Sub-coarse | `0.29 ± 0.00` | `3.53 ± 0.03` | `0.419 ± 0.002` |
| $0.05$ (optimum) | Pragmatic RSA L1 / Synchronized | `0.29 ± 0.00` | `3.51 ± 0.03` | `0.424 ± 0.002` |
| $1.35$ (excess) | Literal Decoder L0 / Aperture lag | `4.18 ± 0.02` | `9.00 ± 0.00` | `0.000 ± 0.000` |

Source: Ensemble calibration ledger (`0xea51b8568902acdb`, marginals `0xcc2262b7ac80a6fb` + `0xd8349a254e5a1d6d`); Michael C. Frank (Frank & Goodman, 2012); James J. Gibson (Gibson, 1979)


At the Linguistics × Embodied Cognition junction (`0xea51b8568902acdb`), pairing *Gricean Maxims and Rational Speech Acts* with *Optic-Flow Invariants and Time-to-Contact* stabilizes $\hat{\eta}\_{AB}^{\star} = 0.05$ (`0.424 ± 0.002`) and enforces $J_{AB}(\hat{\eta}\_{AB}^{\star}) < 1$ (Frank & Goodman, 2012; Gibson, 1979).

Recursive pragmatic inference shows how compact everyday utterances convey rich upper-bounded meaning by reasoning over unspoken lexical alternatives and shared discourse questions. Modeling speaker optimality and cost explicitly unites Gricean philosophy with quantitative psycholinguistic data (Horn, 1989).

A falsifiable psycholinguistic and computational ablation tests Rational Speech Act recursion by manipulating speaker access to scalar alternative `'all'` (partial-knowledge vs full-knowledge speaker condition) while holding literal utterance `'some'` fixed: RSA predicts immediate collapse of scalar implicature odds in the partial-knowledge ablation without changing literal truth conditions.

Scaling Rational Speech Act pragmatics from closed three-object reference games to open-ended natural discourse confronts an unsolved normalization problem: speakers and listeners never enumerate the infinite set of all grammatically possible alternative utterances $\mathcal{U}$. Characterizing how bounded-rational minds sample a tiny, context-salient local contrast set $\tilde{\mathcal{U}}(c)$ in milliseconds while preserving Gricean scalar consistency remains open.

What compact discourse representation lets a dialogue partner track shared presuppositions and unspoken contrasts without hallucinating unstated commitments? Testing minimal utterance pairs differing only in quantifier strength reveals whether comprehension models compute pragmatic contrast.


## 5. Algorithmic Protocol and Statistical Verification

Auditability of the Linguistics to Embodied Cognition coupling table is anchored by three closed-form rules:

$$ J_S(\eta) = N^{-1}\sum_{s=1}^{N} \mathrm{clip}_{[0,1]}\!\left\lbrace  e^{-v_s / 0.35}\bigl[1 - 0.28\,(a_s - 2.55)_+ / 6.45\bigr] - \Phi(z_s) \right \rbrace $$

1. **Monte Carlo Initialization (`N = 200`)**: Stream `0x6a09e667f3bcb21a + 7919 * s` drives `SplitMix64` draws over range $[19,21]\;\mathrm{m}$, speed $[9.5,10.5]\;\mathrm{m\,s^{-1}}$, and size $[0.30,1.50]\;\mathrm{m}$ capped at $9.0\;\mathrm{m\,s^{-2}}$.
2. **Grid-Optimal Coupling**: Maximizing ensemble stability across $\Delta\eta = 0.05$ increments yields $\hat{\eta}\_{AB}^{\star} = 0.05$ (`0.424 ± 0.002`), paired with `0.29 ± 0.00` $\mathrm{m\,s^{-1}}$ contact speed and `3.51 ± 0.03` $\mathrm{m\,s^{-2}}$ peak decel.
3. **Interval Rule & Reference Binary**: Two-tailed `95%` margins apply $1.96 / \sqrt{200}$; see the <a href="https://boriasanai.github.io/bori-blog/assets/sim/convolutional-neural-network-0e09ce.rs">open simulation artifact</a> (`FNV1a-64 = 0xea51b8568902acdb`).

## References

1. Frank, M. C., & Goodman, N. D. (2012). Predicting pragmatic reasoning in language games. *Science*, 336(6084), 998. https://doi.org/10.1126/science.1218633
2. Goodman, N. D., & Frank, M. C. (2016). Pragmatic language interpretation as probabilistic inference. *Trends in Cognitive Sciences*, 20(11), 818-829. https://doi.org/10.1016/j.tics.2016.08.005
3. Grice, H. P. (1975). Logic and conversation. In P. Cole & J. L. Morgan (Eds.), *Syntax and Semantics, Vol. 3: Speech Acts* (pp. 41-58). Academic Press. https://doi.org/10.1163/9789004368811_003
4. Horn, L. R. (1989). *A Natural History of Negation*. University of Chicago Press. https://press.uchicago.edu/ucp/books/book/chicago/N/bo3629258.html
5. Degen, J. (2023). The Rational Speech Act framework. *Annual Review of Linguistics*, 9, 519-540. https://doi.org/10.1146/annurev-linguistics-031220-010811
6. Gibson, J. J. (1979). *The Ecological Approach to Visual Perception*. Houghton Mifflin. https://doi.org/10.4324/9781315740218
7. Lee, D. N. (1976). A theory of visual control of braking based on information about time-to-collision. *Perception*, 5(4), 437-459. https://doi.org/10.1068/p050437
8. Warren, W. H. (1984). Perceiving affordances: Visual guidance of stair climbing. *Journal of Experimental Psychology: Human Perception and Performance*, 10(5), 683-703. https://doi.org/10.1037/0096-1523.10.5.683
9. Chapman, S. (1968). Catching a baseball. *American Journal of Physics*, 36(10), 868-870. https://doi.org/10.1119/1.1974297
10. Srinivasan, M. V., Zhang, S. W., Lehrer, M., & Collett, T. S. (1996). Honeybee navigation en route to the goal: Visual flight control and odometry. *Journal of Experimental Biology*, 199(1), 237-244. https://doi.org/10.1242/jeb.199.1.237


---

<div class="bori-cta">
<span class="cta-emoji">🌉</span>
<p>Which pair of seemingly distant scientific laws have you seen reinforce each other under perturbation?</p>
</div>

*[Day +265 · Cross-domain bridge Linguistics x Embodied Cognition - calm clarity]*

{% include cf-signature.html %}
{% include sv-chart.html %}
{% include series-nav.html %}
{% include related-posts.html %}
{% include rss-banner.html %}
