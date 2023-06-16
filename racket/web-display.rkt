#lang racket/base

(require racket/class)
(require racket/file)
(require racket/match)
(require web-server/dispatch)
(require web-server/http/response-structs)
(require web-server/http/request-structs)
(require web-server/servlet-env)

(require "display.rkt")

(provide web-display%)

(define-logger web #:parent dsp-logger)

(define main-page-html
  (file->string "display.html" #:mode 'text))

(define web-display%
  (class display%
    (super-new)

    (inherit ready!)
    (inherit ready?)
    
    (define/private (main-page)
      (log-web-debug "main-page")
      (response
       200 #"OK"
       (current-seconds) TEXT/HTML-MIME-TYPE
       '() ; no headers
       (lambda (op) (display main-page-html op))))

    (define command-thread #f)
    (define/private (sieve-server)
      (log-web-debug "sieve-server")
      (response
       200 #"OK"
       (current-seconds) TEXT/HTML-MIME-TYPE
       (list
        (header #"Content-Type" #"text/event-stream")
        (header #"Cache-Control" #"no-cache"))
       (lambda (command-port)
         ; The output port closes when this function returns,
         ; but we need it to remain open to continue sending commands.
         ; Generate a thread to keep running and send commands on the port.
         (set! command-thread
               (thread
                (lambda ()
                  (let loop ()
                    (match (thread-receive)
                      [(? string? str)
                       (fprintf command-port "data: ~a\n\n" str)
                       (flush-output command-port)
                       (loop)]
                      ['done
                       (log-web-debug "command thread done")])))))
         (ready!)
         ; Wait on the thread to complete before returning.
         (thread-wait command-thread))))

    (define/override (do-command command)
      (log-web-debug "command: ~a" command)
      (thread-send command-thread command))

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
         (serve/servlet
          (dispatcher)
          #:servlet-path ""
          #:servlet-regexp #rx""
          #:port 0
          #:connection-close? #f
          #:launch-browser? #t))))
    
    (define/override (done?)
      (thread-wait server-thread)
      (log-web-debug "server thread terminated"))))
