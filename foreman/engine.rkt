#lang racket/base

;; The engine. One cycle: collect every rule instantiation that matches
;; working memory, pick one to fire (recency, then specificity, then
;; declaration order), apply its actions, repeat. When nothing matches, or
;; the cycle cap is hit, the engine stops and reports how far it got.

(require racket/list
         "memory.rkt"
         "pattern.rkt"
         "rule.rkt")

(provide (struct-out engine)
         make-engine
         engine-assert!
         engine-elements
         engine-count-of-class
         engine-run!
         engine-apply-actions!)

;; rules is a (listof rule?) in declaration order; the order is the last
;; conflict-resolution criterion, so it is part of a program's semantics.
(struct engine (rules [memory #:mutable] [cycle-count #:mutable])
  #:transparent)

(define engine-next-id
  (let ([id 0])
    (lambda ()
      (set! id (add1 id))
      id)))

(define (make-engine #:rules rules)
  (unless (and (list? rules) (andmap rule? rules))
    (raise-argument-error 'make-engine "(listof rule?)" rules))
  (engine rules '() 0))

(define (engine-assert! e . datum)
  (define element (apply make-element datum))
  (set-engine-memory! e (cons element (engine-memory e)))
  element)

(define (engine-elements e)
  (reverse (engine-memory e)))

(define (engine-count-of-class e class)
  (count (lambda (elt) (eq? (element-class elt) class))
         (engine-memory e)))

;; Every instantiation of RULE against current memory: ordered combinations
;; of distinct elements (one per pattern) whose joint bindings survive
;; matching. The enumeration order follows memory order, newest first.
(define (rule-instantiations e rule)
  (define memory (engine-memory e))
  (let loop ([patterns (rule-patterns rule)]
             [used-ids '()]
             [bindings (hash)]
             [matched '()])
    (if (null? patterns)
        (list (match-record bindings (reverse matched)))
        (apply append
               (for/list ([element (in-list memory)]
                          #:unless (member (element-id element) used-ids))
                 (define b (match-pattern (car patterns) element bindings))
                 (if b
                     (loop (cdr patterns)
                           (cons (element-id element) used-ids)
                           b
                           (cons element matched))
                     '()))))))

;; Recency of a match: its elements' time tags sorted newest first.
(define (match-time-tags m)
  (sort (map element-time (match-record-elements m)) >))

(define (tags-newer? a b)
  (cond
    [(null? a) #f]
    [(null? b) #t]
    [(= (car a) (car b)) (tags-newer? (cdr a) (cdr b))]
    [else (> (car a) (car b))]))

(define (rule-specificity rule)
  (apply + (map pattern-specificity (rule-patterns rule))))

;; #t when candidate A fires before candidate B: newer beats older, more
;; specific beats looser, earlier-declared beats later. Racket's sort is
;; stable, so fully tied candidates keep their enumeration order, which
;; makes the whole engine deterministic.
(define (fires-first? a b)
  (define ta (match-time-tags (candidate-match a)))
  (define tb (match-time-tags (candidate-match b)))
  (cond
    [(not (equal? ta tb)) (tags-newer? ta tb)]
    [(not (= (candidate-specificity a) (candidate-specificity b)))
     (> (candidate-specificity a) (candidate-specificity b))]
    [else (< (candidate-rule-index a) (candidate-rule-index b))]))

(struct candidate (rule-index rule match specificity) #:transparent)

(define (collect-conflict-set e)
  (for/list ([r (in-list (engine-rules e))]
             [index (in-naturals)])
    (define matches (rule-instantiations e r))
    (define specificity (rule-specificity r))
    (for/list ([m (in-list matches)])
      (candidate index r m specificity))))

;; One RHS action, applied to the engine. modify is remove + make: the old
;; fact is gone and a new fact exists, so downstream recency sees a fresh
;; event — the change is visible to whatever rule watches for it.
(define (engine-apply-actions! e actions)
  (for ([action (in-list actions)])
    (cond
      [(make-action? action)
       (set-engine-memory!
        e
        (cons (element (engine-next-id) (next-time!)
                       (make-action-datum action))
              (engine-memory e)))]
      [(remove-action? action)
       (set-engine-memory!
        e
        (remq (remove-action-element action) (engine-memory e)))]
      [(modify-action? action)
       (define old (modify-action-element action))
       (define fresh
         (element (engine-next-id) (next-time!)
                  (cons (car (element-datum old))
                        (modify-action-new-slots action))))
       (set-engine-memory!
        e
        (cons fresh (remq old (engine-memory e))))])))

;; Runs the engine to quiescence or the cycle cap; returns cycles fired.
(define (engine-run! e #:max-cycles [max-cycles 1000])
  (let cycle ([n 0])
    (if (>= n max-cycles)
        n
        (let ([conflict-set (apply append (collect-conflict-set e))])
          (if (null? conflict-set)
              n
              (let ([winner (car (sort conflict-set fires-first?))])
                (engine-apply-actions!
                 e
                 ((rule-action (candidate-rule winner))
                  (candidate-match winner)))
                (cycle (add1 n))))))))
