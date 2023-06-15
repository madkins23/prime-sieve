#lang racket/base

(require racket/class)

(require try-catch-finally)

(require "web-display.rkt")

(define app-name "Prime Sieve Web")

(try ; Main program:
 (printf "Starting ~a~n" app-name)
 (define display (new web-display%))
 (send display wait)
 (finally
  (printf "Finished ~a~n" app-name)))
