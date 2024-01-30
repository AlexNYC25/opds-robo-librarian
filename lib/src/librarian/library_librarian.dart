import 'package:opds_robo_librarian/src/library_card/library_card.dart';
import 'package:opds_robo_librarian/src/library_card/library_card_komga.dart';
import 'package:opds_robo_librarian/src/library_card/library_card_opds_1.dart';
import 'package:opds_robo_librarian/src/library_card/library_card_opds_2.dart';

class LibraryLibrarian {
  String? username;
  String? password;
  String url = '';

  late LibraryCard libraryCard;

  bool isKomga = false;
  bool isOpds2 = false;

  LibraryLibrarian(this.username, this.password, this.url,
      {this.isKomga = false, this.isOpds2 = false}) {
    setUpLibraryCard();
  }

  void setUpLibraryCard() {
    if (isKomga && !isOpds2) {
      libraryCard =
          LibraryCardKomga(url, username: username, password: password)
              as LibraryCard;
    } else if (isOpds2 && !isKomga) {
      libraryCard =
          LibraryCardOpds2(url, username: username, password: password)
              as LibraryCard;
    } else {
      libraryCard =
          LibraryCardOpds1(url, username: username, password: password)
              as LibraryCard;
    }
  }

  Future<bool> validateServer() async {
    await libraryCard.validateServer();

    return libraryCard.isSetUp;
  }
}
