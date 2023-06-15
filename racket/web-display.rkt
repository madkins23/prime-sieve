#lang racket/base

(require racket/class)
(require racket/file)
(require racket/logging)
(require web-server/dispatch)
(require web-server/http/response-structs)
(require web-server/http/request-structs)
(require web-server/servlet-env)

(require "display.rkt")

(provide web-display%)

(define-logger web #:parent dsp-logger)

(module+ test
  (require rackunit))

(define main-page-html
  (file->string "display.html" #:mode 'text))

(define web-display%
  (class display%
    (super-new)

    (class/c (field [launch boolean?]))
    (init [launch #t])
    (define launch-browser launch)

    (inherit ready!)
    (inherit ready)
    
    (define/private (main-page)
      (log-web-debug "main-page")
      (response
       200 #"OK"
       (current-seconds) TEXT/HTML-MIME-TYPE
       '() ; no headers
       (lambda (op) (display main-page-html op))))

    (define/private (sieve-server)
      (log-web-debug "sieve-server")
      (response
       200 #"OK"
       (current-seconds) TEXT/HTML-MIME-TYPE
       (list
        (header #"Content-Type" #"text/event-stream")
        (header #"Cache-Control" #"no-cache"))
       (lambda (op)
         (write-bytes #"<html><body>sieve-server</body></html>" op))))

    (define/private(dispatcher)
      (define-values (dispatch _)
        (dispatch-rules
         [("") (lambda (_) (main-page))]
         ; Note: extra string-arg handles case where trailing slash does not match.
         ; Just throw that argument away.
         [("sieve" (string-arg)) (lambda (_ __) (sieve-server))]))
      dispatch )
    
    (define server-thread
      (thread
       (lambda()
         (ready!)
         (serve/servlet
          (dispatcher)
          #:servlet-path ""
          #:servlet-regexp #rx""
          #:port 0
          #:launch-browser? launch-browser))))

    (define/override (wait)
      (thread-wait server-thread)
      (log-web-debug "server thread terminated"))

    ; For unit testing (at the current time).
    (class/c [kill! (->m void?)])
    (define/public (kill!) (kill-thread server-thread))))

(module+ test
  (define display (new web-display% [launch #f]))
  (send display ready)

  (check-exn  exn:fail:contract:arity?
              (lambda () (send display command)))

  (check-exn  exn:fail?
              (lambda () (send display do-command "command")))
  (check-exn  exn:fail:contract:arity?
              (lambda () (send display do-command)))

  (send display kill!)
  (send display wait))