# Contributing

## Development loop

```sh
raco pkg install --auto --name foreman .
raco test -p foreman
raco setup --check-pkg-deps foreman
raco scribble --htmls --dest /tmp/foreman-doc foreman-doc/scribblings/foreman.scrbl
racket examples/warehouse.rkt
```

CI must be green on `main`; whoever pushes a red `main` fixes or reverts on the spot.

## Rules

- Read `AGENTS.md` before changing code; the invariants there are normative.
- Conflict-resolution order is normative semantics: recency, then specificity, then declaration order. Any change lands with tests on all three.
- Public API changes land in the same change as their scribble documentation and both READMEs.
