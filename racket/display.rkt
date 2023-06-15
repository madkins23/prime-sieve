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

    (class/c (override [get-type (->m string?)]))
    (define/public (get-type) (error 'type "TBD"))

    (define ready-semaphore (make-semaphore))
    (class/c [ready (->m void?)])
    (define/public-final (ready)
      (semaphore-wait ready-semaphore))
    (class/c [ready! (->m void?)])
    (define/public-final (ready!)
      (semaphore-post ready-semaphore))

    (class/c (override [do-command (->m string? void?)]))
    (define/public (do-command command)  (error 'do-command "TBD"))

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

    (class/c (override [command (->m string? void?)]))
    (define/public (command command)
      (thread-send worker command))
    
    (class/c (override [wait (->m void?)]))
    (define/public (wait) (error 'wait "TBD"))

    ))

(define/contract display+c%
  (class/c
   [ready (->m void?)]
   [ready! (->m void?)])
  display%)

(module+ test
  (define display (new display%))

  (check-exn  exn:fail:contract:arity?
              (lambda () (send display command)))

  (check-exn  exn:fail?
              (lambda () (send display do-command "command")))
  (check-exn  exn:fail:contract:arity?
              (lambda () (send display do-command)))
  )