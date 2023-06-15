#lang racket/base

(require racket/class)
(require racket/contract)
(require racket/logging)
(require racket/match)

(provide display%)
(provide dsp-logger)

(define-logger dsp)

(module+ test
  (require rackunit))

(define display%
  (class object%
    (super-new)

    (define ready-semaphore (make-semaphore))
    (class/c [ready (->m void?)])
    (define/public-final (ready)
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
              (log-dsp-debug "Done!")])))))

    (class/c [command (->m string? void?)])
    (define/public (command command)
      (thread-send worker command))

    (class/c (override [do-command (->m string? void?)]))
    (define/public (do-command command)  (error 'do-command "TBD"))
    
    (class/c (override [wait (->m void?)]))
    (define/public (wait) (error 'wait "TBD"))))

(module+ test
  (define display (new display%))

  (check-exn  exn:fail:contract:arity?
              (lambda () (send display command)))

  (check-exn  exn:fail?
              (lambda () (send display do-command "command")))
  (check-exn  exn:fail:contract:arity?
              (lambda () (send display do-command)))
  )