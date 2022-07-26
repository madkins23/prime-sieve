package main

import (
    "fmt"
    "math/rand"
    "net/http"
    "strconv"
    "time"
)

const AppName = "Most Inefficient Prime Number Sieve Web Server"
const PortNum = 8123

// Main program sets up web handlers and starts web server
func main() {
    fmt.Println("Starting " + AppName)
    fmt.Println("Connect to http://localhost:" + strconv.Itoa(PortNum) + "/")

    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
    	// Main page is in a constant defined below
		fmt.Println("PageHandler")
		fmt.Fprintf(w, page)
    })
    http.HandleFunc("/sieve/", func(w http.ResponseWriter, r *http.Request) {
    	// Sieve runs as server push and uses multiple server-side threads
		fmt.Println("SieveHandler")
		// These settings required for server push
		w.Header().Set("Content-Type",  "text/event-stream")
		w.Header().Set("Cache-Control", "no-cache")

		// Channel for commands to server push handler in browser client
		c := make(chan string)
		// Thread to pick up commands from channel and send to response writer
		go commander(w, c)
		// Generate infinite numbers in this handler thread to hold it open
		generator(c)
    })
    http.ListenAndServe(":" + strconv.Itoa(PortNum), nil)

    fmt.Println("Finished " + AppName);
}

// Pull strings from command channel and send to response writer.
// These are server pushed to open connection to client handler.
func commander(w http.ResponseWriter, commands chan string) {
    for {
        cmd := <-commands
        w.Write([]byte("data: " + cmd + "\n\n"))

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
    commands<-("make " + strconv.Itoa(prime))

    for {
    	// get the number from the input channel
        number := <-c
        args := strconv.Itoa(prime) + " " + strconv.Itoa(number)
        // show the number under test in the prime box and wait a bit
        commands<-("test " + args)
        time.Sleep(time.Duration(250 + rand.Intn(250)) * time.Millisecond)

        if number % prime == 0 {
        	// number is divisible by this prime, it 'fails' and gets destroyed
            commands<-("fail " + args)
        } else {
        	// number not divisible, 'success' means going on the chain
            commands<-("pass " + args)
            time.Sleep(time.Duration(250 + rand.Intn(250)) * time.Millisecond)
            commands<-("test " + strconv.Itoa(prime))

            if (o == nil) {
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
        commands<-("gen " + strconv.Itoa(i))
        time.Sleep(time.Duration(250 + rand.Intn(250)) * time.Millisecond)

        if c == nil {
        	// first filter must be created here
            c = make(chan int)
            go filter(commands, c, i)
        } else {
        	// after that just push the number on the channel
            c <- i
        }

        commands<-("gen")
    }
}

const page = `
<html>
<head>
  <title>Most Inefficient Prime Number Sieve</title>

  <style>
    div#blackboard {
      background-color: linen;
    }
    div.box {
      display: inline-block;
      border: 4px outset violet;
      padding: 3px;
      margin:  3px;
      background-color: mauve;
      width: 50px;
      height: 50px;
    }
    div.box span {
      display: block;
      height: 21px;
      width: 46px;
      padding: 2px;
    }

    div.box span.prime {
      font-weight: bold;
      background-color: gray;
      color: azure;
    }

    div.box span.current {
      float: right;
      text-align: right;
      vertical-align: bottom;
    }

    div.box span.fail {
      background-color: red;
    }

    div.box span.pass {
      background-color: lime;
    }
  </style>

  <script>
    console.log("Starting JavaScript")

    var source = new EventSource("/sieve/handler/");

    function makeFilter(id) {
        var filter = document.createElement('div');

        filter.id = "filter-" + id;
        filter.className = 'box';

        var span = document.createElement('span');

        span.textContent = id;
        span.className = 'prime';
        filter.appendChild(span);

        span = document.createElement('span');
        span.className = 'current';
        filter.appendChild(span);

        return filter;
    }

    source.onmessage = function(event) {
        console.log(source + ".onmessage('" + event.data + "')")

        var data = event.data.split(" ");
        var what = data.shift();

        if (what == "gen") {
            document.getElementById("generator")
                    .getElementsByClassName("current")[0]
                    .textContent = data.shift();
        } else if (what == "make") {
            document.getElementById("blackboard")
                    .appendChild(makeFilter(data.shift()));
        } else if (what == "test" || what == "pass" || what == "fail") {
            var id = data.shift();
            var current = document.getElementById('filter-' + id)
                                  .getElementsByClassName("current")[0];

            if (what == 'test') {
                current.className = 'current';
                current.textContent = data.shift();
            } else if (what == 'pass') {
                current.className = 'current pass';
            } else if (what == 'fail') {
                current.className = 'current fail';
            }
        } else {
            console.log("*** Unknown *** " + what + " | " + data);
        }
    };

    console.log("Finished JavaScript")
  </script>
</head>

<body>
  <div id="blackboard">
    <div id="generator" class="box">
      <span class="prime">Gen#</span>
      <span class="current"></span>
    </div>
  </div>
</body>
</html>
`