package main

import (
	_ "embed"
	"errors"
	"fmt"
	"math/rand"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

const AppName = "Most Inefficient Prime Number Sieve Web Server"

// Single HTML display page that contains client and display code.
//
//go:embed display.html
var page string

// Global HTTP server.
var server http.Server

// Main program sets up web handlers and starts the web server.
func main() {
	fmt.Println("Starting " + AppName)
	defer fmt.Println("Finished " + AppName)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Main page is in a constant defined below.
		fmt.Println("    PageHandler")
		_, _ = fmt.Fprintf(w, page)
	})
	http.HandleFunc("/sieve/", func(w http.ResponseWriter, r *http.Request) {
		// Sieve runs as server push and uses multiple server-side threads.
		fmt.Println("    SieveHandler")
		// These settings are required for server push.
		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Cache-Control", "no-cache")

		// Channel for commands to server push handler in browser client.
		c := make(chan string)
		// Thread to pick up commands from channel and send to response writer.
		go commander(w, c)
		// Generate infinite numbers in this handler thread to hold it open.
		generator(c)
	})

	// Getting an unused port is a little complicated.
	// First use net.Listen() to get one.
	var err error
	var listener net.Listener
	if listener, err = net.Listen("tcp", ":0"); err != nil {
		fmt.Printf("!   Unable to create listener port: %s\n", err)
		return
	} else {
		// At this point the port found by the Listener is available.
		fmt.Printf(">   Connect to http://localhost:%d/\n",
			listener.Addr().(*net.TCPAddr).Port)
	}
	// There's no need to configure any fields in the http.Server object.
	server = http.Server{}
	handleInterrupts() // Depends on the existence of the global server object.
	// Use the pre-existing listener to serve web pages.
	if err := server.Serve(listener); err != nil {
		if errors.Is(err, http.ErrServerClosed) {
			fmt.Println("!   Server terminated")
		} else {
			fmt.Printf("*   Error running web server: %s\n", err)
		}
	}
}

// Pull strings from command channel and send to response writer.
// These are server pushed to open connection to client handler.
func commander(w http.ResponseWriter, commands chan string) {
	for {
		cmd := <-commands
		if _, err := w.Write([]byte("data: " + cmd + "\n\n")); err != nil {
			fmt.Println("!   Command channel (browser page) closed")
			_ = server.Close()
			return
		}

		// Flush after every dump.
		if f, ok := w.(http.Flusher); ok {
			f.Flush()
		}
	}
}

// Filter numbers from further up the chain.
// This is run as a separate thread for each prime number 'window'.
// It is called from the number generator and from subsequent filters.
func filter(commands chan string, c chan int, prime int) {
	var o chan int

	// Creating a new filter means a new display box.
	commands <- "make " + strconv.Itoa(prime)

	for {
		// Get the number from the input channel.
		number := <-c
		id := strconv.Itoa(prime)
		// Show the number under generator in the prime box and wait a bit.
		commands <- "generator " + id + " " + strconv.Itoa(number)
		time.Sleep(time.Duration(250+rand.Intn(250)) * time.Millisecond)

		if number%prime == 0 {
			// Number is divisible by this prime, it 'fails' and gets destroyed.
			commands <- "fail " + id
		} else {
			// Number is not divisible, 'success' means going on the chain.
			commands <- "pass " + id
			time.Sleep(time.Duration(250+rand.Intn(250)) * time.Millisecond)
			commands <- "generator " + strconv.Itoa(prime)

			if o == nil {
				// There is no output channel yet, so we have a new prime;
				// make the next filter in the chain.
				o = make(chan int)
				go filter(commands, o, number)
			} else {
				// The next filter is already there, push the number on.
				o <- number
			}
		}
	}
}

// Generate numbers for filtering for prime numbers.
func generator(commands chan string) {
	var c chan int

	for i := 2; ; i++ {
		// Show the new number in the generator box and wait a bit.
		commands <- "gen " + strconv.Itoa(i)
		time.Sleep(time.Duration(250+rand.Intn(250)) * time.Millisecond)

		if c == nil {
			// The first filter must be created here.
			c = make(chan int)
			go filter(commands, c, i)
		} else {
			// The first filter exists, just push the number on the channel.
			c <- i
		}

		commands <- "gen"
	}
}

// Handle user- and system- generated interrupts by closing the HTTP server.
func handleInterrupts() {
	userChannel := make(chan os.Signal)
	signal.Notify(userChannel, os.Interrupt)
	go func() {
		<-userChannel
		// No exlamation point here as program always prints '^C' at the beginning.
		fmt.Println("  User interrupt")
		_ = server.Close()
	}()
	sysChannel := make(chan os.Signal)
	signal.Notify(sysChannel, syscall.SIGTERM)
	go func() {
		<-sysChannel
		fmt.Println("!   System interrupt")
		_ = server.Close()
	}()
}
