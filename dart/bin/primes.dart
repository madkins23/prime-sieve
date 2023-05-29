import 'dart:async';
import 'dart:io';
import 'dart:math';

const appName = "Most Inefficient Prime Number Sieve Web Server";

late final HttpServer server;

main() async {
  print("Starting $appName");
  try {
    // No Dart facility for embedding file data into String during build.
    // Load it from a file in a (hopefully) known location.
    List<String> path = Platform.script.toFilePath().split("/");
    path.removeLast();
    String scriptDir = path.join("/");
    String displayPage = await File("$scriptDir/display.html").readAsString();

    // Note: Use io.HttpServer instead of shelf/shelf_io package.
    server = await HttpServer.bind('localhost', 0);
    print("> Connect to http://localhost:${server.port}/");
    await server.forEach((HttpRequest request) async {
      switch (request.uri.path) {
        case "/":
          print("    PageHandler");
          request.response.headers.contentType = ContentType.html;
          request.response.write(displayPage);
          request.response.close();
        case "/sieve/":
          print("    SieveHandler");
          // These settings are required for server push.
          // There is no predefined ContentType for text/event-stream.
          request.response.headers.add("Content-Type", "text/event-stream");
          request.response.headers.add("Cache-Control", "no-cache");
          // Note: Must turn off buffering or we don't get immediate updates.
          request.response.bufferOutput = false;
          final commandStream = CommandStream();
          sendCommands(request.response, commandStream.stream);
          generate(commandStream);
        case "/favicon.ico":
          request.response.statusCode = HttpStatus.notFound;
          request.response.close();
        default:
          print("!   Unknown URI path: ${request.uri.path}");
          request.response.statusCode = HttpStatus.badRequest;
          request.response.close();
      }
    });
  } finally {
    print("Finished $appName");
  }
}

/// Accept commands and add them to the controller stream.
///
/// Does not implement onListen(), onPause(), onResume() or onCancel()
/// as the stream has limited, well-defined usage.
class CommandStream {
  CommandStream() : controller = StreamController();
  final StreamController<String> controller;

  Stream<String> get stream => controller.stream;

  send(String command) {
    controller.add(command);
  }
}

/// Filter numbers from further up the chain.
///
/// A filter is created in the chain for each prime number found.
/// Numbers are passed to the filter for evaluation.
/// Commands are sent to the display page to animate results.
class Filter {
  Filter(this.prime, this.commandStream) {
    // Make a new box in the display for this filter.
    commandStream.send("make $prime");
  }
  final int prime;
  final CommandStream commandStream;
  Filter? next;

  static const int visibilityWait = 250; // milliseconds
  static final random = Random();

  /// Wait a bit to allow browser animation to be visible to the user.
  Future<void> wait() {
    return Future.delayed(Duration(
        milliseconds: visibilityWait + random.nextInt(visibilityWait)));
  }

  evaluate(int number) async {
    // Show the number in the filter box on the browser.
    commandStream.send("eval $prime $number");
    await wait();

    // Evaluate the number to see if the filter's prime divides evenly.
    if (number % prime == 0) {
      commandStream.send("fail $prime");
    } else {
      commandStream.send("pass $prime");
      await wait();
      commandStream.send("clear $prime");

      if (next != null) {
        next!.evaluate(number);
      } else {
        next = Filter(number, commandStream);
      }
    }
  }
}

void sendCommands(HttpResponse response, Stream<String> commands) async {
  await for (final command in commands) {
    response.write("data: $command\n\n");
    await response.flush();
  }
}

void generate(CommandStream commandStream) async {
  int i = 2;
  Filter? filter;
  while (true) {
    commandStream.send("gen $i");
    await Future.delayed(Duration(seconds: 1));

    filter ??= Filter(i, commandStream);
    filter.evaluate(i++);

    commandStream.send("gen");
  }
}
