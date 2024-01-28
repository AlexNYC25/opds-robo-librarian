import 'package:opds_robo_librarian/src/librarian/library_librarian.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';

void main() {
  var env = DotEnv(includePlatformEnvironment: true)..load();

  String komgaBase = env['KOMGA_BASE'] ?? '';
  String komgaUrl = env['KOMGA_URL'] ?? '';
  String opdsUrl = env['OPDS_URL'] ?? '';
  String opds2Url = env['OPDS2_URL'] ?? '';

  String adminUser = env['ADMIN_USERNAME'] ?? '';
  String adminPassword = env['ADMIN_PASSWORD'] ?? '';
  String adminWrongPassword = env['ADMIN_WRONG_PASSWORD'] ?? '';

  String testUser = env['TEST_USERNAME'] ?? '';
  String testPassword = env['TEST_PASSWORD'] ?? '';

  group('Initial Robo Librarian Tests', () {
    test(
        'Establishing connection with correct Komga credentials, for Komga api',
        () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(adminUser, adminPassword, komgaUrl, isKomga: true);
      await librarian.libraryCard.validateServer();

      print(komgaUrl);

      expect(librarian.libraryCard.isSetUp, isTrue);
    });

    test(
        'Establishing connection with incorrect komga credentials, for komga api',
        () async {
      final LibraryLibrarian librarian = LibraryLibrarian(
          adminPassword, adminWrongPassword, komgaUrl,
          isKomga: true);
      await librarian.libraryCard.validateServer();

      expect(librarian.libraryCard.isSetUp, isFalse);
    });

    test('Establishing connection with correct komga credentials for OPDS api',
        () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(adminUser, adminPassword, opdsUrl, isKomga: false);

      await librarian.libraryCard.validateServer();

      expect(librarian.libraryCard.isSetUp, isTrue);
    });

    test(
        'Establishing connection with incorrect komga credentials for OPDS api',
        () async {
      final LibraryLibrarian librarian = LibraryLibrarian(
          adminUser, adminWrongPassword, opds2Url,
          isKomga: false);

      await librarian.libraryCard.validateServer();

      expect(librarian.libraryCard.isSetUp, isFalse);
    });

    test('Establishing connection with correct credentials for OPDS 2 api',
        () async {
      final LibraryLibrarian librarian = LibraryLibrarian(
          adminUser, adminPassword, opds2Url,
          isKomga: false, isOpds2: true);

      await librarian.libraryCard.validateServer();

      //expect(librarian.libraryCard?.isSetUp, isTrue);
    });
  });

  group('Komga API Tests', () {
    test('Komga API getKeepReading', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> keepReadingData =
          await librarian.libraryCard.getKeepReading();

      print(keepReadingData);

      expect(keepReadingData['data'], isNotEmpty);
    });

    test('Komga API getNextReadyToRead', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> nextReadyToReadData =
          await librarian.libraryCard.getNextReadyToRead();

      expect(nextReadyToReadData['data'].length, greaterThanOrEqualTo(0));
    });

    test('Komga API getLatestSeries', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> latestSeriesData =
          await librarian.libraryCard.getLatestSeries();

      expect(latestSeriesData['data'], isNotEmpty);
    });

    test('Komga API getLatestBooks', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> latestBooksData =
          await librarian.libraryCard.getLatestBooks();

      print(latestBooksData);

      expect(latestBooksData['data'], isNotEmpty);
    }, timeout: Timeout(Duration(minutes: 3)));

    test('Komga API getRecentlyReadBooks', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> recentlyReadBooksData =
          await librarian.libraryCard.getRecentlyReadBooks();

      expect(recentlyReadBooksData['data'], isNotEmpty);
    });

    test('Komga API getRecentlyUpdatedSeries', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> recentlyUpdatedSeriesData =
          await librarian.libraryCard.getRecentlyUpdatedSeries();

      expect(recentlyUpdatedSeriesData['data'], isNotEmpty);
    });

    test('Komga API getLibraries', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> librariesData =
          await librarian.libraryCard.getLibraries();

      print(librariesData);

      expect(librariesData['data'], isNotEmpty);
    });

    test('Komga API getCollections', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> collectionsData =
          await librarian.libraryCard.getCollections();

      print(collectionsData);

      expect(collectionsData['data'], isNotEmpty);
    });

    test('Komga API getSearchResults', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> searchResultsData =
          await librarian.libraryCard.getSearchResults('Walking dead');

      expect(searchResultsData['data'], isNotEmpty);
    });

    test('Komga API getReadLists', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> readListsData =
          await librarian.libraryCard.getReadLists();

      expect(readListsData['data'], isNotEmpty);
    });

    test('Komga API getPublishers', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> publishersData =
          await librarian.libraryCard.getPublishers();

      expect(publishersData['data'], isNotEmpty);
    });

    test('Komga API getSearchResultsBySeries', () async {
      final LibraryLibrarian librarian =
          LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

      await librarian.libraryCard.validateServer();

      final Map<String, dynamic> searchResultsBySeriesData =
          await librarian.libraryCard.getSearchResultsBySeries('Walking dead');

      expect(searchResultsBySeriesData['data'], isNotEmpty);
    });

    group('OPDS 1 Tests', () {
      test('OPDS 1 getKeepReading', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> keepReadingData =
            await librarian.libraryCard.getKeepReading();

        expect(keepReadingData['data'].length, greaterThanOrEqualTo(0));
      });

      test('OPDS 1 getNextReadyToRead', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> nextReadyToReadData =
            await librarian.libraryCard.getNextReadyToRead();

        expect(nextReadyToReadData['data'].length, greaterThanOrEqualTo(0));
      });

      // let test run for 5 minutes

      test('OPDS 1 getLatestSeries', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> latestSeriesData =
            await librarian.libraryCard.getLatestSeries(page: 1);

        expect(latestSeriesData['data'], isNotEmpty);
      });

      test('OPDS 1 getLatestBooks', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> latestBooksData =
            await librarian.libraryCard.getLatestBooks(page: 1);

        expect(latestBooksData['data'], isNotEmpty);
      });

      test('OPDS 1 getRecentlyUpdatedSeries', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> recentlyUpdatedSeriesData =
            await librarian.libraryCard.getRecentlyUpdatedSeries(page: 1);

        expect(recentlyUpdatedSeriesData['data'], isNotEmpty);
      });

      test('OPDS 1 getRecentlyReadBooks', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> recentlyReadBooksData =
            await librarian.libraryCard.getRecentlyReadBooks();

        expect(recentlyReadBooksData['success'], false);
      });

      test('OPDS 1 getLibraries', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> librariesData =
            await librarian.libraryCard.getLibraries();

        expect(librariesData['data'], isNotEmpty);
      });

      test('OPDS 1 getCollections', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> collectionsData =
            await librarian.libraryCard.getCollections();

        print(collectionsData);

        expect(collectionsData['data'], isNotEmpty);
      });

      test('OPDS 1 getSearchResults', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> searchResultsData =
            await librarian.libraryCard.getSearchResults('Walking dead');

        print(searchResultsData);

        expect(searchResultsData['data'], isNotEmpty);
      }, timeout: Timeout(Duration(minutes: 10)));

      test('OPDS 1 getReadLists', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> readListsData =
            await librarian.libraryCard.getReadLists();

        expect(readListsData['data'], isNotEmpty);
      });

      test('OPDS 1 getPublishers', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> publishersData =
            await librarian.libraryCard.getPublishers();

        expect(publishersData['data'], isNotEmpty);
      });

      test('OPDS 1 getSearchResultsBySeries', () async {
        final LibraryLibrarian librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> searchResultsBySeriesData = await librarian
            .libraryCard
            .getSearchResultsBySeries('Walking dead');

        print(searchResultsBySeriesData);

        expect(searchResultsBySeriesData['data'], isNotEmpty);
      });
    }, timeout: Timeout(Duration(minutes: 5)));

    group('OPDS 2 Tests', () {
      test('OPDS 2 getKeepReading', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> keepReadingData =
            await librarian.libraryCard.getKeepReading();

        //dynamic data = keepReadingData?['data'][0];

        expect(keepReadingData['data'].length, greaterThanOrEqualTo(0));
      });

      test('OPDS 2 getNextReadyToRead', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> nextReadyToReadData =
            await librarian.libraryCard.getNextReadyToRead();

        expect(nextReadyToReadData['data'].length, greaterThanOrEqualTo(0));
      });

      test('OPDS 2 getLatestSeries', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> latestSeriesData =
            await librarian.libraryCard.getLatestSeries();

        expect(latestSeriesData['data'], isNotEmpty);
      });

      test('OPDS 2 getLatestBooks', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> latestBooksData =
            await librarian.libraryCard.getLatestBooks();

        expect(latestBooksData['data'], isNotEmpty);
      });

      test('OPDS 2 getRecentlyUpdatedSeries', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> recentlyUpdatedSeriesData =
            await librarian.libraryCard.getRecentlyUpdatedSeries();

        expect(recentlyUpdatedSeriesData['data'], isNotEmpty);
      });

      test('OPDS 2 getRecentlyReadBooks', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> recentlyReadBooksData =
            await librarian.libraryCard.getRecentlyReadBooks();

        expect(recentlyReadBooksData['success'], false);
      });

      test('OPDS 2 getLibraries', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> librariesData =
            await librarian.libraryCard.getLibraries();

        expect(librariesData['data'], isNotEmpty);
      });

      test('OPDS 2 getCollections', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> collectionsData =
            await librarian.libraryCard.getCollections();

        expect(collectionsData['data'], isNotEmpty);
      });

      test('OPDS 2 getSearchResults', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> searchResultsData =
            await librarian.libraryCard.getSearchResults('Spy');

        expect(searchResultsData['data'], isNotEmpty);
      });

      test('OPDS 2 getReadLists', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> readListsData =
            await librarian.libraryCard.getReadLists();

        expect(readListsData['data'], isNotEmpty);
      });

      test('OPDS 2 getPublishers', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> publishersData =
            await librarian.libraryCard.getPublishers();

        expect(publishersData['success'], false);
      });

      test('OPDS 2 getSearchResultsBySeries', () async {
        final LibraryLibrarian librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await librarian.libraryCard.validateServer();

        final Map<String, dynamic> searchResultsBySeriesData = await librarian
            .libraryCard
            .getSearchResultsBySeries('Walking dead');

        expect(searchResultsBySeriesData['data'], isNotEmpty);
      });
    }, timeout: Timeout(Duration(minutes: 3)));

    group('getKeepReading Comparison tests', () {
      test('initial first element comparison', () async {
        final komgaLibrarian =
            LibraryLibrarian(testUser, testPassword, komgaBase, isKomga: true);

        final opds1Librarian =
            LibraryLibrarian(testUser, testPassword, opdsUrl, isKomga: false);

        final opds2Librarian = LibraryLibrarian(
            testUser, testPassword, opds2Url,
            isKomga: false, isOpds2: true);

        await komgaLibrarian.libraryCard.validateServer();
        await opds1Librarian.libraryCard.validateServer();
        await opds2Librarian.libraryCard.validateServer();

        /*
        final Map<String, dynamic>? komgaKeepReadingData =
            await komgaLibrarian.libraryCard?.getKeepReading();

        final Map<String, dynamic>? opds1KeepReadingData =
            await opds1Librarian.libraryCard?.getKeepReading();

        final Map<String, dynamic>? opds2KeepReadingData =
            await opds2Librarian.libraryCard?.getKeepReading();
        */
      });
    });
  });
}
