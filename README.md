<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

A Dart package to communicate with an OPDS Server or alternative server such as a 
[Komga Server](https://komga.org/), facilitates requests for data on server.

Currently a work in progress, not ready for production use.

## Features

### Retrieves Books 
Allows books to be retrieved from the connected server with properties available, 
properties may differ based on what kind of server is hosting the book

### Retrieves Series
Allows Book Series to be retrieved from the server with relevant properties including 
what specific books belong to it.

### Allows for Page Streaming
On Servers that support it, page streaming is allowed using available url information on the
connected server

### Supports special directories provided
On supported servers, special directories may be retrieved that server special purposes such as 
keeping track of books currently being read, are retrieved an made available


## Getting started


## Usage

```dart
final LibraryLibrarian librarian =
LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

await librarian.libraryCard.validateServer();

final Map<String, dynamic> keepReadingData =
await librarian.libraryCard.getKeepReading();
```
