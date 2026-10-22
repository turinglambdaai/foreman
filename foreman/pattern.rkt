#lang racket/base

;; Patterns and matching. A pattern mirrors the element layout:
;; (class slot slot ...) where each slot is a constant, the wildcard _, or
;; a variable (? name). The same variable name in one pattern constrains
;; two positions to be equal; across a rule's patterns it joins them.
;; Matching is structural and read-only — the cleverness budget goes to
;; the engine loop, not the matcher.

(require racket/list
         "memory.rkt")

(provide pattern?
         variable?
         match-pattern
         pattern-specificity)

;; A variable marker is (? name). The wildcard is the underscore symbol.
(define (variable? slot)
  (and (pair? slot) (= (length slot) 2) (eq? (car slot) '?)
       (symbol? (cadr slot))))

(define (pattern? p)
  (and (pair? p)
       (symbol? (car p))
       (andmap (lambda (slot)
                 (or (variable? slot) (eq? slot '_) #t))
               (cdr p))))

;; EXTENDS bindings (hash name -> value) or returns #f on any mismatch.
(define (match-pattern pattern element bindings)
  (and (eq? (car pattern) (element-class element))
       (let loop ([slots (cdr pattern)]
                  [values (cdr (element-datum element))]
                  [b bindings])
         (cond
           [(null? slots) b]
           [(null? values) #f]
           [else
            (define slot (car slots))
            (define value (car values))
            (define b2
              (cond
                [(variable? slot)
                 (define name (cadr slot))
                 (cond
                   [(hash-ref b name #f)
                    => (lambda (bound) (if (equal? bound value) b #f))]
                   [else (hash-set b name value)])]
                [(eq? slot '_) b]
                [else (if (equal? slot value) b #f)]))
            (and b2 (loop (cdr slots) (cdr values) b2))]))))

;; Count of constant slots — the specificity tiebreaker. A pattern full
;; of constants demands more of the world, so it wins ties against loose
;; patterns.
(define (pattern-specificity pattern)
  (for/sum ([slot (in-list (cdr pattern))])
    (if (or (variable? slot) (eq? slot '_)) 0 1)))
