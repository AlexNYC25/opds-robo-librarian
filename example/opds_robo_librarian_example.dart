import 'package:opds_robo_librarian/src/librarian/library_librarian.dart';

void main() async {
  final String username = 'username';
  final String password = 'password';
  final String url = 'https://example.com/opds';

  final LibraryLibrarian librarian = LibraryLibrarian(username, password, url);

  bool credentialsWorking = await librarian.validateServer();

  if (credentialsWorking == true) {
    print('Server is setup correctly');
  } else {
    // replace with your own error handling
  }

  // request data from server
  Map<String, dynamic> data = await librarian.libraryCard.getKeepReading();

  print(data);
}
