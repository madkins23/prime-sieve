#lang racket/base

(require racket/class)
(require racket/contract)

(require "display.rkt")

(provide generator)

(define/contract (wait-a-bit)
  (-> void?)
  (sleep (+ 0.25 (* 0.25 (random)))))

(define-logger flt)
(define/contract (filter prime display)
  (-> positive? display? void?)
  (log-flt-debug "start ~a" prime)
  (send display command (format "make ~a" prime))
  (let ([next-filter #f])
    (let loop ([number (string->number (thread-receive))])
      (log-flt-debug "~a number ~a" prime number)
      (send display command (format "eval ~a ~a" prime number))
      (wait-a-bit)
      (if (equal? (modulo number prime) 0)
          (begin
            (send display command (format "fail ~a" prime))
            (wait-a-bit))
          (begin
            (send display command (format "pass ~a" prime))
            (wait-a-bit)
            (if next-filter
                (thread-send next-filter (number->string number))
                (set! next-filter
                      (thread (lambda () (filter number display)))))))
      (send display command (format "eval ~a" prime))
      (loop  (string->number (thread-receive))))))

(define-logger gen)
(define/contract (generator display)
  (-> display? void?)
  (log-gen-debug "start")
  (let ([first-filter #f])
    (for ([i (in-naturals 2)])
      (log-gen-debug "number ~a" i)
      (send display command (format "gen ~a" i))
      (sleep 1)
      (if first-filter
          (thread-send first-filter (number->string i))
          (set! first-filter
                (thread (lambda () (filter i display)))))
      (send display command "gen"))))
