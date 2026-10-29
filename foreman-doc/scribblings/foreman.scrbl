#lang scribble/manual

@title{Foreman}
@author{TurLamAI}

Public module: @tt{foreman}

Foreman is a production rule system: a program is a set of rules whose
left-hand sides are declarative patterns over working memory and whose
right-hand sides are ordinary Racket procedures. The engine cycles — match
everything, fire one, repeat — and stops when nothing matches. You describe
what is true and what to do about it; the engine owns the control flow.

@section{Working memory}

@verbatim{
(make-element class attr val ...) -> element?
(element-class e) -> symbol?
(element-ref e attr) -> any/c
(engine-assert! e class attr val ...) -> element?
(engine-elements e) -> (listof element?)
(engine-count-of-class e class) -> exact-nonnegative-integer?
}

An element is a flat datum — @tt{(monkey location tree1 holds nil)} — with a
unique id and a logical time stamp. The clock is global and monotonic; time
stamps feed recency, the first conflict-resolution criterion.

@section{Patterns and rules}

@verbatim{
(rule name patterns action) -> rule?
  name     : symbol?
  patterns : (listof pattern?)
  action   : (-> match-record? (listof action?))
(match-record vars elements) -> match-record?
}

A pattern mirrors the element layout: @tt{(monkey location (? loc) holds _)}.
Slots are constants, the wildcard @tt{_}, or variables @tt{(? name)}. The
same variable in one pattern demands equal values; across a rule's patterns
it joins them.

The right-hand side receives the matched variable bindings and the matched
elements themselves, and returns actions:

@verbatim{
(make-action class slots)          ; a new fact
(remove-action element)            ; the fact is gone
(modify-action element new-slots)  ; remove + make: a fresh fact
}

Everything the patterns cannot say, the procedure says with the full
language. modify is remove plus make by design: a changed fact is a new
event, and downstream recency sees it.

@section{The cycle}

@verbatim{
(make-engine #:rules rules) -> engine?
(engine-run! e #:max-cycles max) -> exact-nonnatural-integer?
}

One cycle collects every instantiation of every rule, fires exactly one,
applies its actions, and repeats. The winner is chosen by the classic
cascade: newest elements first (recency), then the most constants in the
patterns (specificity), then declaration order. Ties keep enumeration
order, so a program is deterministic given a deterministic assert order.

A right-hand side that changes nothing matches again next cycle; the
@tt{#:max-cycles} cap turns any such stall into a bounded, observable run
instead of a hang.

@section{Invariants}

@itemlist[
 @item{Matching is structural and read-only; elements are immutable. The
   only way memory changes is through right-hand-side actions.}
 @item{One firing per cycle, always; a program's behavior does not depend
   on batch effects.}
 @item{The engine is deterministic: same rules, same asserts, same
   outcome — no hidden randomness.}
]
