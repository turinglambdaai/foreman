#lang racket/base

;; Offline walkthrough: a tiny warehouse in which one robot ferries
;; packages to the dock. The rule program never says when to run — it says
;; what is true and what to do about it, and the engine takes the steps in
;; between. Deterministic; this is the same run CI performs.

(require foreman)

(define warehouse
  (make-engine
   #:rules
   (list
    ;; A package under the robot's nose goes on board. The package fact is
    ;; consumed; a cargo fact records what the robot now carries.
    (rule 'load
          (list
           '(robot name (? name) location (? loc))
           '(package id (? p) location (? loc)))
          (lambda (m)
            (define v (match-record-vars m))
            (define elements (match-record-elements m))
            (list
             (remove-action (cadr elements))
             (fact 'cargo 'robot (hash-ref v 'name)
                   'package (hash-ref v 'p)))))
    ;; Once nothing loadable is left at the bay, a robot standing there
    ;; walks to the dock. The move changes the robot fact, so this fires
    ;; exactly once per arrival.
    (rule 'travel
          (list '(robot name (? name) location bay))
          (lambda (m)
            (list (modify-action (car (match-record-elements m))
                                 (list 'name (hash-ref (match-record-vars m) 'name)
                                       'location 'dock)))))
    ;; On the dock, each piece of cargo is delivered and its cargo fact is
    ;; consumed. When no cargo is left, no pattern matches: quiescence.
    (rule 'deliver
          (list '(robot name (? name) location dock)
                '(cargo robot (? name) package (? p)))
          (lambda (m)
            (define v (match-record-vars m))
            (define elements (match-record-elements m))
            (list (remove-action (cadr elements))
                    (fact 'delivered 'by (hash-ref v 'name)
                          'package (hash-ref v 'p))))))))

(engine-assert! warehouse 'package 'id 'p1 'location 'bay)
(engine-assert! warehouse 'package 'id 'p2 'location 'bay)
(engine-assert! warehouse 'robot 'name 'wally 'location 'bay)

(define cycles (engine-run! warehouse))

(printf "cycles: ~a\n" cycles)
(for ([elt (in-list (engine-elements warehouse))])
  (printf "  ~a\n" (element-datum elt)))
