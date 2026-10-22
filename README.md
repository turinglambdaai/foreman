# Foreman

**A production rule system for Racket — declarative patterns, procedural right-hand sides.**

[![CI](https://github.com/turinglambdaai/foreman/actions/workflows/ci.yml/badge.svg)](https://github.com/turinglambdaai/foreman/actions/workflows/ci.yml) ![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

**English** · [中文](README.zh-CN.md)

Foreman runs rule programs: facts go into working memory, rules declare which fact shapes they care about and what to do about them, and the engine cycles — match everything, fire one, repeat — until nothing matches. The left-hand side stays declarative; the right-hand side is an ordinary Racket procedure with the full language behind it.

Foreman is not a forward-chaining planner or an expert-system shell with an inference DSL. It is one small, deterministic engine with three explicit conflict-resolution criteria (recency, specificity, declaration order) and no hidden semantics.

## Quick start

```racket
(require foreman)

(define engine
  (make-engine
   #:rules
   (list
    (rule 'count-up
          (list '(counter value (? v)))
          (lambda (m)
            (define v (hash-ref (match-record-vars m) 'v))
            (define counter (car (match-record-elements m)))
            (if (< v 5)
                (list (modify-action counter (list 'value (+ v 1))))
                (list (remove-action counter))))))))

(engine-assert! engine 'counter 'value 0)
(engine-run! engine)   ; fires six times: five increments, then the removal
```

A runnable walkthrough lives in `examples/warehouse.rkt` — one robot, two packages, three rules — and runs in CI.

## Design notes

- **Declarative where it counts.** Patterns are plain data: constants, the wildcard `_`, and `(? variables)`. The same variable joins across patterns; nothing else to learn.
- **Procedural where it pays.** Right-hand sides are Racket procedures returning actions (`make-action`, `remove-action`, `modify-action`). Conditions over aggregates, arithmetic, logging, I/O — all just Racket.
- **Deterministic by construction.** Newest facts first, then most-specific patterns, then declaration order; ties keep enumeration order. Same program, same asserts, same outcome.
- **Stalls are bounded.** A right-hand side that changes nothing re-matches next cycle; `#:max-cycles` turns any such stall into a bounded, observable run.

## Development

```sh
raco pkg install --auto --name foreman .
raco test -p foreman
raco setup --check-pkg-deps foreman
racket examples/warehouse.rkt
```

CI runs the test suite on Linux, Windows, and macOS against Racket 9.0 and 9.3, then checks declared dependencies, builds the reference manual, and runs the walkthrough.

## License

[Apache-2.0](LICENSE)
