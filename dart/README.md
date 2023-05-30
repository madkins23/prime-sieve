# prime-sieve

Most Inefficient Prime Number Sieve Web Server

## Dart

Dart doesn't provide threads or basic concurrency support.
Initially intended to replace Javascript in web browsers (which goal has been dropped)
it inherits a single-threaded approach managed by `Future` objects and event processing.
On top of this Dart provides a variety of asynchronous features that mask somewhat
the use of futures and make Dart code look quite sequential.

In addition to futures, Dart provides streams which can be processed as event flows.
Streams can be collected, processed, and transformed into other streams.
While there are no threads in Dart, starting an `async` function that returns a future
has a very similar feel.

The Dart version of the Most Inefficient Prime Number Sieve Web Server uses futures and streams.

## Usage

Build and run the `primes.dart` file from the `dart` directory:
```shell
$ dart run bin/primes.dart
Starting Most Inefficient Prime Number Sieve Web Server
> Connect to http://localhost:8123/
```
Connect to the specified URL in a web browser.
The port number will be different each time.

## Caveats

### Killing the Beast

The Dart application doesn't seem to want to stop.
User (`<ctrl>-C`) and system interrupts are captured and the server is shut down but the application just hangs.
This is undoubtedly a problem with the code but a fair amount of experimentation never fixed the problem
so a larger hammer (i.e. `exit()`) was employed.

Note that Android Studio doesn't use either of these interrupts when killing an ongoing Dart application.
Instead the IDE uses `SIGKILL` to assassinate the running application with extreme prejudice.
Within Dart, however, it is not possible to capture that interrupt.

In addition, killing the browser tab that shows the `display.html` animation does not stop the application.
There doesn't seem to be any straightforward way to find out that the browser isn't out there any more.

All of this is handled properly in the Go version of the application.