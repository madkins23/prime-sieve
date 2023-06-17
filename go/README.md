# prime-sieve

Most Inefficient Prime Number Sieve Web Server

## Go

Go provides concurrent processing via the `goroutine` mechanism.
[Officially](https://go.dev/tour/concurrency/1)
a "_goroutine_ is a lightweight thread managed by the Go runtime."
These are not OS threads or processes but cooperating, non-preemptive (or _partially_ preemptive)
threadlike entities that _may_ run on separate OS threads.
[To put this another way](https://www.ardanlabs.com/blog/2018/08/scheduling-in-go-part2.html):

> The Go scheduler is part of the Go runtime, and the Go runtime is built into your application.
> This means the Go scheduler runs in user space, above the kernel. 
> The current implementation of the Go scheduler is not a preemptive scheduler but a cooperating scheduler.
> Being a cooperating scheduler means the scheduler needs well-defined user space events
> that happen at safe points in the code to make scheduling decisions.

While provides a set of standard asynchronous tools (e.g. locks),
the preferred way to handle thread coordination and communication is via channels.
These are typed conduits that can connect goroutines in a flexible manner.

The combination of goroutines and channels was inspired by C.A.R. Hoare's
[1978 paper](https://www.cs.cmu.edu/~crary/819-f09/Hoare78.pdf) and
[1985 book](https://www.amazon.com/Communicating-sequential-processes-Prentice-Hall-International/dp/0131532715)
_Communicating Sequential Processes_, [now available for free online](http://www.usingcsp.com/cspbook.pdf).[^1]

The Go version of the Most Inefficient Prime Number Sieve Web Server uses goroutines and channels.

## Usage

Build and run the `primes.go` file from the `go` directory:
```shell
$ go run cmd/primes.go
Starting Most Inefficient Prime Number Sieve Web Server
>   Connect to http://localhost:42689/
```
Connect to the specified URL in a web browser.
The port number will be different each time.

[^1]: I've had a copy of the 1985 book since it came out.
I've attempted to read it on several occasions but never made it through.[^2]

[^2]: The same happened with _Dianetics_, but in that case I feel OK about it.