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
