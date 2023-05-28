# prime-sieve

Most Inefficient Prime Number Sieve Web Server

[![Go Report Card](https://goreportcard.com/badge/github.com/madkins23/prime-sieve)](https://goreportcard.com/report/github.com/madkins23/prime-sieve)
[![Go Reference](https://pkg.go.dev/badge/github.com/madkins23/prime-sieve.svg)](https://pkg.go.dev/github.com/madkins23/prime-sieve)

## Usage

Build and run the `primes.go` file from the `go` directory:
```shell
$ go run cmd/primes.go
Starting Most Inefficient Prime Number Sieve Web Server
>   Connect to http://localhost:42689/
```
Connect to the specified URL in a web browser.
The port number will be different each time.

## Display

The prime number sieve creates a series of goroutines representing prime numbers.
Integers are fed in from the top left and they pass through the chain of goroutines,
represented as boxes in the browser.
Each box shows its prime in the top border.
As integers pass throw the boxes they may be found evenly divisible,
in which case they show red and disappear.
Any integer that makes it though the entire chain creates a new
goroutine and its attendant box.
