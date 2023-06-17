#lang racket/base

(require racket/class)

(require "sieve.rkt")
(require "gui-display.rkt")

(sieve "Prime Sieve GUI" (new gui-display%))
