#lang racket/base

(require racket/class)
(require racket/gui)

(require "display.rkt")

(provide gui-display%)

(define-logger gui #:parent dsp-logger)

(define box-shim 10)
(define box-size 25)

(define gui-box%
  (class group-box-panel%
    (super-new
     [stretchable-height box-size]
     [stretchable-width box-size])
    (define msg
      (new message%
           [parent this]
           [label "XXX"]
           [min-height box-size]
           [min-width box-size]
           [stretchable-height box-size]
           [stretchable-width box-size]))))

(define gui-pane%
  (class pane%
    (super-new)
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
    (define pane (new gui-pane% [parent frame]))
    (define gen-box (new gui-box% [label "Gen#"] [parent pane]))
    (send frame show #t)
    (ready!)

    (define/override (do-command command)
      (log-gui-debug "command: ~a" command))
    
    (define/override (wait-done)
      (semaphore-wait done-semaphore))))

(module+ test
  (define gd (new gui-display%))
  (send gd wait-done))
