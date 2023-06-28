#lang racket/base

(require racket/class)

(require "sieve.rkt")
(require "web-display.rkt")

(module+ main
  (sieve "Prime Sieve Web" (new web-display%)))
