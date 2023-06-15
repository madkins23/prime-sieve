#lang racket/base

(require racket/class)

(require try-catch-finally)

(require "web-display.rkt")

;; Main program starts here:
(define display (new web-display%))

(define app-name (string-append-immutable "Prime Sieve " (send display get-type)))

(try
 (printf "Starting ~a~n" app-name)
 (send display wait)
 (finally
  (printf "Finished ~a~n" app-name)))
