#lang racket/base

(require racket/class
         racket/contract
         racket/match)

(provide display%
         display?
         dsp-logger)

(module+ test
  (require rackunit))

(define-logger dsp)

(define/contract display%
  (class/c [command (->m string? void?)]
           [ready! (->m void?)]
           [wait-ready (->m void?)]
           (override [wait-done (->m void?)])
           (override [do-command (->m string? void?)]))
  (class object%
    (super-new)

    (define ready-semaphore (make-semaphore))
    (define/public-final (wait-ready)
      (semaphore-wait ready-semaphore))
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

    (define/public-final (command command)
      (thread-send worker command))

    (abstract do-command wait-done)))

(define/contract (display? display)
  (any/c . -> . boolean?)
  (is-a? display display%))

(module+ test
  (check-false (display? 1))
  (let ([display (new (class display%
                        (super-new)
                        (define/override (do-command command) (displayln command))
                        (define/override (wait-done) (sleep 0.01))))])
    (check-true (display? display))
    (check-exn exn:fail? (lambda() (send display command)))
    (check-exn exn:fail? (lambda() (send display command 1)))
    (check-exn exn:fail? (lambda() (send display ready! 1)))
    (check-exn exn:fail? (lambda() (send display wait-ready 1)))
    ))
