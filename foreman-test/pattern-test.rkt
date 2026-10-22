#lang racket/base

(require racket/hash
         rackunit
         foreman)

(define monkey (make-element 'monkey 'location 'tree1 'holds 'nil))

(test-case "constants match, mismatches do not"
  (check-equal? (match-pattern '(monkey location tree1) monkey (hash))
                (hash))
  (check-false (match-pattern '(monkey location dock) monkey (hash)))
  (check-false (match-pattern '(banana location tree1) monkey (hash))))

(test-case "wildcards and variables bind"
  (check-equal? (match-pattern '(monkey location _ holds (? h)) monkey (hash))
                (hash 'h 'nil))
  (check-equal? (match-pattern '(monkey location (? loc)) monkey (hash))
                (hash 'loc 'tree1)))

(test-case "a repeated variable constrains within one pattern"
  (define pair (make-element 'pair 'left 'a 'right 'a))
  (define other (make-element 'pair 'left 'a 'right 'b))
  (check-equal? (match-pattern '(pair left (? s) right (? s)) pair (hash))
                (hash 's 'a))
  (check-false (match-pattern '(pair left (? s) right (? s)) other (hash))))

(test-case "an existing binding acts as a join constraint"
  (check-equal? (match-pattern '(monkey location (? loc)) monkey (hash 'loc 'tree1))
                (hash 'loc 'tree1))
  (check-false (match-pattern '(monkey location (? loc)) monkey (hash 'loc 'dock))))

(test-case "arity mismatches do not match"
  (check-false (match-pattern '(monkey location tree1 holds nil extra) monkey (hash))))

(test-case "specificity counts constants"
  (check-equal? (pattern-specificity '(monkey location tree1 holds (? h))) 3)
  (check-equal? (pattern-specificity '(monkey location (? loc) holds _)) 2))
