# prime-sieve

Most Inefficient Prime Number Sieve Web Server

![GitHub](https://img.shields.io/github/license/madkins23/prime-sieve)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/madkins23/prime-sieve)


## Background

In the 1980s I saw a demonstration of an early Ada compiler
([Intellimac](https://www.computerhistory.org/collections/catalog/102743800))
that showed  a prime number sieve made up of a chain of parallel tasks
displayed using some sort of primitive text-based display.
It seemed really cool (remember, the 1980s) and since then I've
re-implemented the concept off and on for my own enjoyment.

Two such examples are presented in this repository:

* Go
* Dart

More details about the language choices and application configuration
may be found in the `README.md` files in the language specific subdirectories.

## How It Works

The basic concept is a chain of prime number "filters",
each representing a single prime number.
Integers are passed through the chain of filters,
starting with the first filter in the chain.
As each filter in turn gets the next integer one of three things happens:
 
1. The prime number divides evenly into the integer: the number is discarded.
2. There is a further filter in the sequence: the number is passed to the next filter.
3. A new filter is created for the integer which is the newest prime.

The filters are intended to operate concurrently and
to present the progress of the integer stream through the chain
in an animated display.

## HTML Display

Not all modern languages come with a display package.
For some years now I've been using a web browser for
command, control, and display for various tools and applications.
HTTP and HTML are always available in the nearest browser.

A single display page is provided in the file `display.html`.
This file is located at the top level of the repository and also
within the language-specific subdirectories.
The top level file is the official version,
the subdirectory copies are for ease of access by the applications.

The page includes Javascript that provides a display
controlled by HTTP/2 Server Push from the application.
All the actual prime number filtering is done in the application,
the HTML page and code are only responsible for displaying the filter operation.

Commands from the application are:

| Command                    | Action                                                                                     |
|----------------------------|--------------------------------------------------------------------------------------------|
| `gen [<integer>]`          | Show a new integer being generated at the beginning of the chain or clear it if no integer |
| `make <integer>`           | Add a new filter at the end of the chain with the specified integer                        |
| `eval <prime> [<integer>]` | Show the prime filter evaluating the specified integer or clear it if no integer           |
| `pass <prime>`             | Show the prime filter passing the current integer                                          |
| `fail <prime>`             | Show the prime filter failing the current integer                                          |

Filters are represented as boxes in the browser.
Each box shows its prime in the top border,
with the integer operands shown inside the box as they are passed down the chain.
Results of the filter's evaluation of the number are shown as:
* `pass` number is bold and background is green
* `fail` number is faded with a line through it and background is red

## Caveats

* The display page and code have only been run on Chrome.
* Development and testing of applications were done on Ubuntu Linux.
* Configuring development environments to build and run the code is an exercise for the reader.
