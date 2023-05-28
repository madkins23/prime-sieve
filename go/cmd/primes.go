package main

import (
	_ "embed"
	"errors"
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

const AppName = "Most Inefficient Prime Number Sieve Web Server"
const PortNum = 8123

//go:embed display.html
var page string

var server http.Server

// Main program sets up web handlers and starts web server
func main() {
	fmt.Println("Starting " + AppName)
	fmt.Println("> Connect to http://localhost:" + strconv.Itoa(PortNum) + "/")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Main page is in a constant defined below
		fmt.Println("  PageHandler")
		_, _ = fmt.Fprintf(w, page)
	})
	http.HandleFunc("/sieve/", func(w http.ResponseWriter, r *http.Request) {
		// Sieve runs as server push and uses multiple server-side threads
		fmt.Println("  SieveHandler")
		// These settings required for server push
		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Cache-Control", "no-cache")

		// Channel for commands to server push handler in browser client
		c := make(chan string)
		// Thread to pick up commands from channel and send to response writer
		go commander(w, c)
		// Generate infinite numbers in this handler thread to hold it open
		generator(c)
	})
	server = http.Server{Addr: ":" + strconv.Itoa(PortNum)}
	handleInterrupts()
	if err := server.ListenAndServe(); err != nil {
		if errors.Is(err, http.ErrServerClosed) {
			fmt.Println("! Server terminated")
		} else {
			fmt.Printf("* Error running web server: %s\n", err)
		}
	}

	fmt.Println("Finished " + AppName)
}

// Pull strings from command channel and send to response writer.
// These are server pushed to open connection to client handler.
func commander(w http.ResponseWriter, commands chan string) {
	for {
		cmd := <-commands
		if _, err := w.Write([]byte("data: " + cmd + "\n\n")); err != nil {
			fmt.Println("! Command channel closed")
			_ = server.Close()
			return
		}

		// Flush after every dump
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

	// Creating a new filter means a new display box
	commands <- "make " + strconv.Itoa(prime)

	for {
		// get the number from the input channel
		number := <-c
		args := strconv.Itoa(prime) + " " + strconv.Itoa(number)
		// show the number under generator in the prime box and wait a bit
		commands <- "generator " + args
		time.Sleep(time.Duration(250+rand.Intn(250)) * time.Millisecond)

		if number%prime == 0 {
			// number is divisible by this prime, it 'fails' and gets destroyed
			commands <- "fail " + args
		} else {
			// number not divisible, 'success' means going on the chain
			commands <- "pass " + args
			time.Sleep(time.Duration(250+rand.Intn(250)) * time.Millisecond)
			commands <- "generator " + strconv.Itoa(prime)

			if o == nil {
				// there is no output channel yet so we have a new prime,
				// make the next filter in the chain
				o = make(chan int)
				go filter(commands, o, number)
			} else {
				// next filter already there, push the number on
				o <- number
			}
		}
	}
}

// Generate numbers for filtering for prime numbers.
func generator(commands chan string) {
	var c chan int

	for i := 2; ; i++ {
		// show new number in generator box and wait a bit
		commands <- "gen " + strconv.Itoa(i)
		time.Sleep(time.Duration(250+rand.Intn(250)) * time.Millisecond)

		if c == nil {
			// first filter must be created here
			c = make(chan int)
			go filter(commands, c, i)
		} else {
			// after that just push the number on the channel
			c <- i
		}

		commands <- "gen"
	}
}

func handleInterrupts() {
	userChannel := make(chan os.Signal)
	signal.Notify(userChannel, os.Interrupt)
	go func() {
		<-userChannel
		fmt.Println("! User interrupt")
		_ = server.Close()
	}()
	sysChannel := make(chan os.Signal)
	signal.Notify(sysChannel, syscall.SIGTERM)
	go func() {
		<-sysChannel
		fmt.Println("! System interrupt")
		_ = server.Close()
	}()
}
