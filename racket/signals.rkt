#lang racket/base
(require unix-signals)

(provide signals)

(define (signals) 
  (capture-signal! 'SIGABRT)
  (capture-signal! 'SIGINT)
  (capture-signal! 'SIGQUIT)
  (capture-signal! 'SIGKILL)
  (capture-signal! 'SIGTERM)
  (thread
   (let loop ()
     (define signum (read-signal))
     (displayln (lookup-signal-name signum))
     (exit 0))))

(module+ test
  (displayln "Testing...")
  (signals)
  (sleep 60))

(module+ main
  ; Show defined signals
  (require srfi/54) ; (cat) https://docs.racket-lang.org/srfi/srfi-std/srfi-54.html
  (for ([n (in-range 1 32)]) (printf "~a ~v~n" (cat n 2) (lookup-signal-name n))))