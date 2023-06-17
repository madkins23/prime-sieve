# prime-sieve

Most Inefficient Prime Number Sieve Web Server

## Racket

Racket is a variant of Scheme, one of the two main families of Lisp (the other being Common Lisp).
Racket provides green threads that run in the same OS thread.
Each thread has a mailbox for incoming messages.
There are also semaphores, channels and other features to support concurrency.

The Racket version of the Most Inefficient Prime Number Sieve Web Server uses threads and their mailboxes
as well as a few semaphores.

### Two Versions

Racket provides a basic GUI package supporting windows, dialogs, and various controls.
These are limited in function as they are based on underlying platform-specific widgets.

Since this package is provided, the Racket implementation here is twofold:
* the usual solution using the `display.html` page and a browser and
* a GUI solution using the Racked-provided GUI package.

## Usage

### Web Version

Build and run the `primes-web.rkt` file from the `racket` directory:
```shell
$ racket primes-web.rkt
Starting Prime Sieve Web
Your Web application is running at http://localhost:37309.
Stop this program at any time to terminate the Web Server.
```
The browser should start the `display.html` page in a new tab automatically.
Closing this tab should terminate the application:
```
Web Server stopped.
Finished Prime Sieve Web
```
`<Ctrl>-C` should also terminate the application:
```
^Cuser break
  context...:
   /home/marc/work/prime-sieve/racket/web-display.rkt:92:4: wait-done method in web-display%
   /home/marc/snap/racket/13/.local/share/racket/8.9/pkgs/try-catch-finally-lib/main.rkt:33:28
   /snap/racket/current/usr/share/racket/collects/racket/contract/private/arrow-higher-order.rkt:375:33
   body of "/home/marc/work/prime-sieve/racket/primes-web.rkt"
Finished Prime Sieve Web
```

### GUI Version

Build and run the `primes-gui.rkt` file from the `racket` directory:
```shell
$ racket primes-gui.rkt
Starting Prime Sieve GUI
```
The browser should spawn a window with a somewhat primitive version of the sieve display.
Closing the window should terminate the application:
```
Finished Prime Sieve GUI
```
`<Ctrl>-C` should also terminate the application:
```
^Cuser break
  context...:
   /home/marc/snap/racket/13/.local/share/racket/8.9/pkgs/try-catch-finally-lib/main.rkt:33:28
   /snap/racket/current/usr/share/racket/collects/racket/contract/private/arrow-higher-order.rkt:375:33
   body of "/home/marc/work/prime-sieve/racket/primes-gui.rkt"
Finished Prime Sieve GUI
```

## Caveats

### GUI Version Limitations

Since the Racket GUI package uses platform-specific GUI widgets there are some limitations on the GUI display.
In particular, the background color changes used by `display.html` are not (easily) possible.

I apologize to anyone with red/green color blindness.
I went to some trouble to fix `display.html` to be more accessible to those with that disorder.

### Killing the Beast

When working in the DrRacket IDE (provided with the Racket installation) it can be difficult
to get the applications to completely stop.
There have been times when it has been necessary to stop DrRacket to get out of it.
At this point most if not all of those issues have been addressed,
though there are places where they have been fixed with a hammer.
