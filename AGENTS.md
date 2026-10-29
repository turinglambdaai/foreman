# AGENTS.md

## Scope

Foreman is the production-rule-system layer of the TurLamAI product
family: declarative pattern matching over working memory with procedural
right-hand sides. It is not an expert-system shell, a planner, or a
business-rules UI.

## Dependency direction

```text
product -> foreman

foreman -X-> product
foreman -X-> any other family library
```

Foreman is a leaf: it depends on nothing beyond base.

## Invariants

- Elements are immutable; memory changes only through right-hand-side
  actions. Matching is read-only.
- Conflict resolution is exactly: recency, then specificity, then
  declaration order. These are semantics, not implementation details.
- modify is remove plus make: a changed fact is a new event with a fresh
  time stamp. No partial-update semantics hides which fact version a match
  used.
- The engine is deterministic given a deterministic assert order; no
  hidden randomness anywhere.
- A stalled program terminates at the cycle cap — bounded and observable,
  never an unbounded hang.
- Public API changes land in the same change as their scribble
  documentation and both READMEs.
