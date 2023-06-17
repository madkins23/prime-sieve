#lang racket/base

(require racket/class)
(require racket/contract)
(require racket/match)

(provide display%)
(provide display?)
(provide dsp-logger)

(define-logger dsp)

(define display%
  (class object%
    (super-new)

    (define ready-semaphore (make-semaphore))
    (class/c [wait-ready (->m void?)])
    (define/public-final (wait-ready)
      (semaphore-wait ready-semaphore))
    (class/c [ready! (->m void?)])
    (define/public-final (ready!)
      (semaphore-post ready-semaphore))

    (define worker
      (thread
       (lambda ()
         (let loop ()
           (match (thread-receive)
             [(? string? str)
              (do-command str)
              (loop)]
             ['done
              (log-dsp-debug "display worker thread done")])))))

    (class/c [command (->m string? void?)])
    (define/public-final (command command)
      (thread-send worker command))

    (abstract do-command wait-done)
    (class/c (override [do-command (->m string? void?)]))
    (class/c (override [ wait-done (->m void?)]))))

(define (display? display) (is-a? display display%))