# prime-sieve

Most Inefficient Prime Number Sieve Web Server

# Usage

Build and run the `server.go` file.
When it runs it will display a URL, e.g.

    Connect to http://localhost:8123

Open this URL in a web browser.

# Display

The prime number sieve creates a series of goroutines representing prime numbers.
Integers are fed in from the top left and they pass through the chain of goroutines,
represented as boxes in the browser.
Each box shows its prime in the top border.
As integers pass throw the boxes they may be found evenly divisible,
in which case they show red and disappear.
Any integer that makes it though the entire chain creates a new
goroutine and its attendant box.
