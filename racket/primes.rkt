#lang racket/base

(require racket/class)

(require try-catch-finally)

(require "sieve.rkt")
(require "web-display.rkt")

(define app-name "Prime Sieve Web")

(try ; Main program:
 (printf "Starting ~a~n" app-name)
 (define display (new web-display%))
 (send display ready?)
 (thread (generator display))
 (send display done?)
 (finally
  (printf "Finished ~a~n" app-name)))
