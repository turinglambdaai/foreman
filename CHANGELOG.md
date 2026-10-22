# Changelog

## 0.1.0 — 2026-10-22

- Working memory of immutable fact elements with ids and a monotonic logical clock.
- Declarative LHS patterns (constants, wildcard, joinable variables) with intra-pattern equality constraints.
- Procedural RHS: match-record in, actions out (make / remove / modify-as-remove-plus-make).
- Deterministic conflict resolution: recency, then specificity, then declaration order.
- Bounded cycles (#:max-cycles) turn stalled programs into observable runs.
