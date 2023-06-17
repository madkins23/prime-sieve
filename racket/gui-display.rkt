#lang racket/base

(require racket/class)
(require racket/gui)

(require "display.rkt")

(provide gui-display%)

(define-logger gui #:parent dsp-logger)

(define box-shim 10)
(define box-size 50)
(define font-size 12)

(define gui-box%
  (class group-box-panel%
    (super-new
     [alignment '(center center)]
     [min-height box-size]
     [min-width box-size]
     [stretchable-height box-size]
     [stretchable-width box-size])

    (define msg-font
      (send the-font-list find-or-create-font
            font-size 'modern 'normal 'bold))
    
    (define msg
      (new message%
           [parent this]
           [label ""]
           [auto-resize #t]
           [font msg-font]))

    (class/c [set-content (->m string? void?)])
    (define/public (set-content str)
      (send msg set-color "Black")
      (send msg set-label str))

    (class/c [pass (->m void?)])
    (define/public (pass)
      (send msg set-color "Lime"))

    (class/c [fail (->m void?)])
    (define/public (fail)
      (send msg set-color "Red"))))

(define gui-panel%
  (class panel%
    (super-new [style '(vscroll)])
    (define/override (place-children info width height)
      (let ([x box-shim][y box-shim])
        (for/list ([child-info info])
          (let ([child-width (first child-info)]
                [child-height (second child-info)])
            (when (> (+ x box-shim child-width) width)
              (set! x box-shim)
              (set! y (+ y box-shim child-height)))
            (let ([item (list x y child-width child-height)])
              (set! x (+ x box-shim child-width))
              item)))))))

(define gui-display%
  (class display%
    (super-new)

    (inherit ready!)
    (inherit wait-ready)

    (define done-semaphore (make-semaphore))

    (define frame
      ; Without creating a new eventspace code hangs at (wait-done).
      ; In particular, the windows close box won't work at all and
      ; the on-close augment is not called to post done-semaphore.
      (let ([new-es (make-eventspace)])
        (parameterize ([current-eventspace new-es])
          (new
           (class frame%
             (super-new
              [label "Most Inefficient Prime Number Sieve"]
              [height 400]
              [width 500]
              [style '(fullscreen-button)])
             ; Augment the frame's close box to signal display is done.
             (define/augment (on-close)
               (log-gui-debug "frame close")
               (semaphore-post done-semaphore)))))))
    (define panel (new gui-panel% [parent frame]))
    (define gen-box (new gui-box% [label "Gen#"] [parent panel]))
    (send frame show #t)
    (ready!)

    (define/private (gen [num ""])
      (send gen-box set-content num))

    (define prime-boxes (make-hash))
    (define/private (make prime)
      (hash-set! prime-boxes prime
                 (new gui-box% [label prime] [parent panel])))
    
    (define/private (eval prime [num ""])
      (send (hash-ref prime-boxes prime) set-content num))
    
    (define/private (pass prime)
      (send (hash-ref prime-boxes prime) pass))
    
    (define/private (fail prime)
      (send (hash-ref prime-boxes prime) fail))

    (define/override (do-command command)
      (log-gui-debug "command: ~a" command)
      (match (string-split command)
        [(list "gen") (gen)]
        [(list "gen" number) (gen number)]
        [(list "make" prime) (make prime)]
        [(list "eval" prime) (eval prime)]
        [(list "eval" prime number) (eval prime number)]
        [(list "pass" prime) (pass prime)]
        [(list "fail" prime) (fail prime)]
        [_ (log-gui-warning "command? ~a" command)]))
    
    (define/override (wait-done)
      (semaphore-wait done-semaphore))))

(module+ test
  (define gd (new gui-display%))
  (define (seq num)
    (send gd command (format "gen ~a" num))
    (sleep 1)
    (send gd command (format "make ~a" num))
    (sleep 1)
    (send gd command (format "eval ~a ~a" num 63))
    (sleep 1)
    (send gd command (format "fail ~a" num))
    (sleep 1)
    (send gd command (format "eval ~a" num))
    (sleep 1)
    (send gd command (format "eval ~a ~a" num 79))
    (sleep 1)
    (send gd command (format "pass ~a" num))
    (sleep 1)
    (send gd command (format "eval ~a" num)))
  (sleep 1)
  (seq 13)
  (seq 17)
  (seq 23)
  (send gd command "gen")
  (send gd command "oops")
  (send gd wait-done))
