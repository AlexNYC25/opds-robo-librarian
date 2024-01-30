import 'package:opds_robo_librarian/src/library_card/Library_Card.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;

/// A class that represents a library card for an OPDS 1.2 server instance
class LibraryCardOpds1 extends LibraryCard {
  /// Manifest of the OPDS feed with links
  Map<String, dynamic> opdsManifest = {};

  // ***************************************************************
  // Constructors
  // ***************************************************************

  LibraryCardOpds1(super.url, {super.username, super.password});

  // ***************************************************************
  // Server Validation
  // ***************************************************************

  /// Validates server settings to ensure that the server is set up correctly
  /// as well as parses the catalog to get the available entries. Sets the result
  /// to the [isSetUp] variable and the catalog is parsed to the [opdsManifest]
  @override
  Future<void> validateServer() async {
    try {
      // check the status code of the root url with a get request, using the
      // provided username and password if they exist
      int statusCode = await getRootUrlStatusCode();

      if (statusCode != 200) {
        isSetUp = false;
        return;
      }

      // check the headers of the root url with a get request, and check if the
      // content-type header contains application/atom+xml
      List<String> headers = await getRootUrlHeaders(type: 'content-type');

      if (!headers.contains('application/atom+xml')) {
        isSetUp = false;
        return;
      }

      // checks done, now we build the opds manifest
      opdsManifest = await buildOpdsManifest();
      isSetUp = true;
    } catch (error) {
      isSetUp = false;
    }
  }

  // ***************************************************************
  // Manifest functions
  // ***************************************************************

  /// Converts a given functional [entry] xml element to a map
  Map<String, dynamic> convertFunctionalEntryToMap(XmlElement entry) {
    String id = entry.getElement('id')?.text ?? '';
    String title = entry.getElement('title')?.text ?? '';
    String href = entry.getElement('link')?.getAttribute('href') ?? '';
    String type = entry.getElement('link')?.getAttribute('type') ?? '';

    return {
      'id': id,
      'title': title,
      'href': href,
      'type': type,
    };
  }

  // function to get the contents of the root url, and parse them
  Future<Map<String, dynamic>> buildOpdsManifest() async {
    String body = await getRootUrlContents();

    // get the root document
    final XmlDocument rootDocument = XmlDocument.parse(body);

    // get all entry elements in the root document
    final List<XmlElement> rootEntries =
        rootDocument.findAllElements('entry').toList();

    // get all link elements in the root document
    // TODO: check what link id's we may want to get from the root document
    final List<XmlElement> rootLinks =
        rootDocument.findAllElements('link').toList();

    // this list contains the ids of all functional entries we want to get from the root document
    // ids may differ from server to server, so this list may need to be updated
    List functionalEntriesIds = [
      'onDeck',
      'keepReading',
      'recentlyAdded',
      'wantToRead',
      'allSeries',
      'allLibraries',
      'allCollections',
      'latestSeries',
      'latestBooks',
      'allReadLists',
      'allPublishers'
    ];

    // create the list of functional entries and book entries
    List<Map<String, dynamic>> manifestFunctionalEntriesMap = [];
    List<Map<String, dynamic>> manifestBookEntriesMap = [];
    List<Map<String, dynamic>> manifestLinksMap = [];

    // loop through all entries in the root document
    for (XmlElement entry in rootEntries) {
      String id = entry.getElement('id')?.text ?? '';
      // check if the entry id is in the list of functional entries if so
      // parse them as a functional entry, otherwise parse them as a book entry
      if (functionalEntriesIds.contains(id)) {
        Map<String, dynamic> entryTest = convertFunctionalEntryToMap(entry);
        manifestFunctionalEntriesMap.add(entryTest);
      } else {
        Map<String, dynamic> entryTest = convertBookEntryToMap(entry);
        manifestBookEntriesMap.add(entryTest);
      }
    }

    // loop through all links in the root document
    for (XmlElement link in rootLinks) {
      String href = link.getAttribute('href') ?? '';
      String type = link.getAttribute('type') ?? '';
      String rel = link.getAttribute('rel') ?? '';

      manifestLinksMap.add({
        'href': href,
        'type': type,
        'rel': rel,
      });
    }

    return {
      'data': {
        'functionalEntries': manifestFunctionalEntriesMap,
        'bookEntries': manifestBookEntriesMap,
        'links': manifestLinksMap,
      },
      'success': true,
      'responseCode': 200,
      'responseMessage': 'Manifest retrieved successfully'
    };
  }

  // ***************************************************************
  // Exclusive class functions
  // ***************************************************************

  /// Converts relevant data from the book entry xml element to a map
  Map<String, dynamic> convertBookEntryToMap(XmlElement entry) {
    String id = entry.getElement('id')?.text ?? '';
    String title = entry.getElement('title')?.text ?? '';
    String href = entry.getElement('link')?.getAttribute('href') ?? '';
    String type = entry.getElement('link')?.getAttribute('type') ?? '';
    String updated = entry.getElement('updated')?.text ?? '';
    String content = entry.getElement('content')?.text ?? '';

    List<Map<String, dynamic>> links = [];
    List<XmlElement> linkElements = entry.findAllElements('link').toList();
    // loop through all link elements in the entry and add them to the links list
    for (XmlElement linkElement in linkElements) {
      String linkHref = linkElement.getAttribute('href') ?? '';
      String linkType = linkElement.getAttribute('type') ?? '';
      String linkRel = linkElement.getAttribute('rel') ?? '';
      String wstxns1 = linkElement.getAttribute('xmlns:wstxns1') ?? '';
      String wstxns1Count = linkElement.getAttribute('wstxns1:count') ?? '';
      String wstxns1LastRead =
          linkElement.getAttribute('wstxns1:lastRead') ?? '';
      String wstxns1LastReadDate =
          linkElement.getAttribute('wstxns1:lastReadDate') ?? '';

      links.add({
        'href': linkHref,
        'type': linkType,
        'rel': linkRel,
        'xmlns:wstxns1': wstxns1,
        'wstxns1:count': wstxns1Count,
        'wstxns1:lastRead': wstxns1LastRead,
        'wstxns1:lastReadDate': wstxns1LastReadDate,
      });
    }

    return {
      'id': id,
      'title': title,
      'href': href,
      'type': type,
      'updated': updated,
      'content': content,
    };
  }

  bool checkNextLinkExists(XmlDocument document) {
    List<XmlElement> linkElements = document.findAllElements('link').toList();

    bool nextLinkExists = false;
    for (XmlElement linkElement in linkElements) {
      String linkRel = linkElement.getAttribute('rel') ?? '';
      if (linkRel == 'next') {
        String linkHref = linkElement.getAttribute('href') ?? '';
        // check if linkHref is not empty and is a valid url
        if (linkHref.isNotEmpty && isValidUrl(linkHref)) {
          nextLinkExists = true;
          break;
        }
      }
    }

    return nextLinkExists;
  }

  // ***************************************************************
  // Generic Media Functions
  // ***************************************************************

  Future<Map<String, dynamic>> handleRequestForData(
      bool Function() checkFunction,
      Future<http.Response> Function({int page}) fetchFunction,
      {int? page,
      List<Map<String, dynamic>> Function(
              List<Map<String, dynamic>> entries, String q)?
          searchFunction,
      String? query = ''}) async {
    if (!isSetUp) {
      return cardHasNotBeenSetUp(
          errorMessage:
              'Library Card has not been set up, cannot use this functionality');
    }

    if (opdsManifest.isEmpty) {
      opdsManifest = await buildOpdsManifest();
    }

    if (checkFunction() == false) {
      return cardHasNotBeenSetUp(
          errorMessage:
              'This functionality is not available for this server: URL is not valid');
    }

    if (page != null && page >= 0) {
      http.Response response = await fetchFunction(page: page);
      XmlDocument document = XmlDocument.parse(response.body);

      if (response.statusCode == 400) {
        return responseIsNotValid(
            errorMessage:
                'This functionality is not available for this server: URL is not valid');
      }

      int totalPages = 1;

      List<XmlElement> documentEntries =
          document.findAllElements('entry').toList();

      List<Map<String, dynamic>> entriesMap = [];

      for (XmlElement entry in documentEntries) {
        Map<String, dynamic> entryMap = convertBookEntryToMap(entry);
        entriesMap.add(entryMap);
      }

      if (searchFunction != null && query != null && query.isNotEmpty) {
        entriesMap = searchFunction(entriesMap, query);
      }

      return formattedDataMap(data: entriesMap, totalPages: totalPages);
    }

    http.Response response = await fetchFunction();
    XmlDocument document = XmlDocument.parse(response.body);

    if (response.statusCode == 400) {
      return responseIsNotValid(
          errorMessage:
              'This functionality is not available for this server: URL is not valid');
    }

    List<XmlElement> documentEntries =
        document.findAllElements('entry').toList();

    List<Map<String, dynamic>> entriesMap =
        documentEntries.map((entry) => convertBookEntryToMap(entry)).toList();

    int currentPage = 1;
    int totalPages = 1;

    do {
      http.Response response = await fetchFunction(page: currentPage);

      if (response.statusCode == 400) {
        break;
      }

      XmlDocument document = XmlDocument.parse(response.body);

      List<XmlElement> entries = document.findAllElements('entry').toList();

      for (XmlElement entry in entries) {
        Map<String, dynamic> entryMap = convertBookEntryToMap(entry);
        entriesMap.add(entryMap);
      }

      bool nextLinkExists = checkNextLinkExists(document);

      if (!nextLinkExists) {
        break;
      }

      currentPage++;
    } while (true);

    if (searchFunction != null && query != null && query.isNotEmpty) {
      entriesMap = searchFunction(entriesMap, query);
    }

    return formattedDataMap(data: entriesMap, totalPages: totalPages);
  }

  Future<Map<String, dynamic>> handleRequestForDataWithSearch(
      bool Function() checkFunction,
      Future<http.Response> Function(String query, {int page}) fetchFunction,
      String query,
      {int? page}) async {
    if (!isSetUp) {
      return cardHasNotBeenSetUp(
          errorMessage:
              'Library Card has not been set up, cannot use this functionality');
    }

    if (opdsManifest.isEmpty) {
      opdsManifest = await buildOpdsManifest();
    }

    if (checkFunction() == false) {
      return cardHasNotBeenSetUp(
          errorMessage:
              'This functionality is not available for this server: URL is not valid');
    }

    if (page != null && page >= 0) {
      http.Response response = await fetchFunction(query, page: page);
      XmlDocument document = XmlDocument.parse(response.body);

      if (response.statusCode == 400) {
        return responseIsNotValid(
            errorMessage:
                'This functionality is not available for this server: URL is not valid');
      }

      int totalPages = 1;

      List<XmlElement> documentEntries =
          document.findAllElements('entry').toList();

      List<Map<String, dynamic>> entriesMap = [];

      for (XmlElement entry in documentEntries) {
        Map<String, dynamic> entryMap = convertBookEntryToMap(entry);
        entriesMap.add(entryMap);
      }

      return formattedDataMap(data: entriesMap, totalPages: totalPages);
    }

    http.Response response = await fetchFunction(query);
    XmlDocument document = XmlDocument.parse(response.body);

    if (response.statusCode == 400) {
      return responseIsNotValid(
          errorMessage:
              'This functionality is not available for this server: URL is not valid');
    }

    List<XmlElement> documentEntries =
        document.findAllElements('entry').toList();

    List<Map<String, dynamic>> entriesMap =
        documentEntries.map((entry) => convertBookEntryToMap(entry)).toList();

    int currentPage = 1;
    int totalPages = 1;

    do {
      http.Response response = await fetchFunction(query, page: currentPage);

      if (response.statusCode == 400) {
        break;
      }

      XmlDocument document = XmlDocument.parse(response.body);

      List<XmlElement> entries = document.findAllElements('entry').toList();

      for (XmlElement entry in entries) {
        Map<String, dynamic> entryMap = convertBookEntryToMap(entry);
        entriesMap.add(entryMap);
      }

      bool nextLinkExists = checkNextLinkExists(document);

      if (!nextLinkExists) {
        break;
      }
    } while (true);

    return formattedDataMap(data: entriesMap, totalPages: totalPages);
  }

  // ***************************************************************
  // search, sort functions
  // ***************************************************************

  List<Map<String, dynamic>> searchByTitle(
      List<Map<String, dynamic>> entries, String query) {
    List<Map<String, dynamic>> searchResults = [];

    for (Map<String, dynamic> entry in entries) {
      if (entry['title'].toLowerCase().contains(query.toLowerCase())) {
        searchResults.add(entry);
      }
    }

    return searchResults;
  }

  // ***************************************************************
  // keep Reading
  // ***************************************************************

  /// Checks if the 'keepReading' functional entry is available in the opds
  /// manifest, returning a [bool] value representing if it is available or not.
  bool getKeepReadingAvailable() {
    if (opdsManifest.isEmpty) {
      return false;
    }

    Map<String, dynamic> keepReadingEntry = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'keepReading');

    if (keepReadingEntry.isNotEmpty) {
      String keepReadingUrl = keepReadingEntry['href'];

      if (keepReadingUrl.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Creates a request to to the 'keepReading' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// otherwise by default it gets the first page of results.
  Future<http.Response> getKeepReadingResponse({int page = 0}) async {
    Map<String, dynamic> keepReadingResult = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'keepReading');
    String keepReadingUrl = keepReadingResult['href'];

    Uri url = Uri.parse(keepReadingUrl).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the currently reading books, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getKeepReading({int? page}) async {
    return handleRequestForData(
      getKeepReadingAvailable,
      getKeepReadingResponse,
      page: page,
    );
  }

  // ***************************************************************
  // On Deck
  // ***************************************************************

  /// Checks if the 'ondeck' functional entry is available in the opds manifest,
  /// returning a [bool] value representing if it is available or not.
  bool getNextReadyToReadAvailable() {
    if (opdsManifest.isEmpty) {
      return false;
    }

    Map<String, dynamic> nextReadyToReadEntry = opdsManifest['data']
            ['bookEntries']
        .firstWhere((entry) => entry['id'] == 'ondeck');

    if (nextReadyToReadEntry.isNotEmpty) {
      String nextReadyToReadUrl = nextReadyToReadEntry['href'];

      if (nextReadyToReadUrl.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Creates a request to to the 'ondeck' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// otherwise by default it gets the first page of results.
  Future<http.Response> getNextReadyToReadResponse({int page = 0}) async {
    Map<String, dynamic> nextReadyToReadResult = opdsManifest['data']
            ['bookEntries']
        .firstWhere((entry) => entry['id'] == 'ondeck');
    String nextReadyToReadUrl = nextReadyToReadResult['href'];

    Uri url = Uri.parse(nextReadyToReadUrl).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the next on deck books, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getNextReadyToRead({int? page}) async {
    return handleRequestForData(
      getNextReadyToReadAvailable,
      getNextReadyToReadResponse,
      page: page,
    );
  }

  // ***************************************************************
  // Latest Series
  // ***************************************************************

  /// Checks if the 'recentlyAdded' functional entry is available in the opds
  /// manifest, returning a [bool] value representing if it is available or not.
  bool getLatestSeriesAvailable() {
    if (opdsManifest.isEmpty) {
      return false;
    }

    Map<String, dynamic> latestSeriesEntry = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'latestSeries');

    if (latestSeriesEntry.isNotEmpty) {
      String latestSeriesUrl = latestSeriesEntry['href'];

      if (latestSeriesUrl.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Creates a request to to the 'latestSeries' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// otherwise by default it gets the first page of results.
  Future<http.Response> getLatestSeriesResponse({int page = 0}) async {
    Map<String, dynamic> latestSeriesResult = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'latestSeries');
    String latestSeriesUrl = latestSeriesResult['href'];

    Uri url = Uri.parse(latestSeriesUrl).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the latest series, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getLatestSeries({int? page}) async {
    return handleRequestForData(
      getLatestSeriesAvailable,
      getLatestSeriesResponse,
      page: page,
    );
  }

  // ***************************************************************
  // Latest Books
  // ***************************************************************

  /// Checks if the 'latestBooks' functional entry is available in the opds
  /// manifest, returning a [bool] value representing if it is available or not.
  bool getLatestBooksAvailable() {
    if (opdsManifest.isEmpty) {
      return false;
    }

    Map<String, dynamic> latestBooksEntry = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'latestBooks');

    if (latestBooksEntry.isNotEmpty) {
      String latestBooksUrl = latestBooksEntry['href'];

      if (latestBooksUrl.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Creates a request to to the 'latestBooks' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// otherwise by default it gets the first page of results.
  Future<http.Response> getLatestBooksResponse({int page = 0}) async {
    Map<String, dynamic> latestBooksResult = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'latestBooks');
    String latestBooksUrl = latestBooksResult['href'];

    Uri url = Uri.parse(latestBooksUrl).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the latest books, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getLatestBooks({int? page}) async {
    return handleRequestForData(
      getLatestBooksAvailable,
      getLatestBooksResponse,
      page: page,
    );
  }

  // ***************************************************************
  // Recently updated series
  // ***************************************************************

  /// Checks if the 'allSeries' functional entry is available in the opds
  /// manifest, returning a [bool] value representing if it is available or not.
  bool getRecentlyUpdatedSeriesAvailable() {
    if (opdsManifest.isEmpty) {
      return false;
    }

    Map<String, dynamic> recentlyUpdatedSeriesEntry = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'allSeries');

    if (recentlyUpdatedSeriesEntry.isNotEmpty) {
      String recentlyUpdatedSeriesUrl = recentlyUpdatedSeriesEntry['href'];

      if (recentlyUpdatedSeriesUrl.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Creates a request to to the 'allSeries' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// otherwise by default it gets the first page of results.
  Future<http.Response> getRecentlyUpdatedSeriesResponse({int page = 0}) async {
    Map<String, dynamic> recentlyUpdatedSeriesResult = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'allSeries');
    String recentlyUpdatedSeriesUrl = recentlyUpdatedSeriesResult['href'];

    Uri url = Uri.parse(recentlyUpdatedSeriesUrl).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the recently updated series, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getRecentlyUpdatedSeries({int? page}) async {
    return handleRequestForData(
      getRecentlyUpdatedSeriesAvailable,
      getRecentlyUpdatedSeriesResponse,
      page: page,
    );
  }

  // ***************************************************************
  // Libraries
  // ***************************************************************

  /// Checks if the 'allLibraries' functional entry is available in the opds
  /// manifest, returning a [bool] value representing if it is available or not.
  bool getLibrariesAvailable() {
    if (opdsManifest.isEmpty) {
      return false;
    }

    Map<String, dynamic> librariesEntry = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'allLibraries');

    if (librariesEntry.isNotEmpty) {
      String librariesUrl = librariesEntry['href'];

      if (librariesUrl.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Creates a request to to the 'allLibraries' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// otherwise by default it gets the first page of results.
  Future<http.Response> getLibrariesResponse({int page = 0}) async {
    Map<String, dynamic> librariesResult = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'allLibraries');
    String librariesUrl = librariesResult['href'];

    Uri url = Uri.parse(librariesUrl).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the libraries, returning a [Future] object of type
  /// [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getLibraries({int? page}) async {
    return handleRequestForData(
      getLibrariesAvailable,
      getLibrariesResponse,
      page: page,
    );
  }

  // ***************************************************************
  // Collections
  // ***************************************************************

  /// Checks if the 'allCollections' functional entry is available in the opds
  /// manifest, returning a [bool] value representing if it is available or not.
  bool getCollectionsAvailable() {
    if (opdsManifest.isEmpty) {
      return false;
    }

    Map<String, dynamic> collectionsEntry = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'allCollections');

    if (collectionsEntry.isNotEmpty) {
      String collectionsUrl = collectionsEntry['href'];

      if (collectionsUrl.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Creates a request to to the 'allCollections' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// otherwise by default it gets the first page of results.
  Future<http.Response> getCollectionsResponse({int page = 0}) async {
    Map<String, dynamic> collectionsResult = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'allCollections');
    String collectionsUrl = collectionsResult['href'];

    Uri url = Uri.parse(collectionsUrl).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the collections, returning a [Future] object of type
  /// [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getCollections({int? page}) async {
    return handleRequestForData(
      getCollectionsAvailable,
      getCollectionsResponse,
      page: page,
    );
  }

  // ***************************************************************
  // Read Lists
  // ***************************************************************

  /// Checks if the 'allReadLists' functional entry is available in the opds
  /// manifest, returning a [bool] value representing if it is available or not.
  bool getReadListsAvailable() {
    if (opdsManifest.isEmpty) {
      return false;
    }

    Map<String, dynamic> readListsEntry = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'allReadLists');

    if (readListsEntry.isNotEmpty) {
      String readListsUrl = readListsEntry['href'];

      if (readListsUrl.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Creates a request to to the 'allReadLists' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// otherwise by default it gets the first page of results.
  Future<http.Response> getReadListsResponse({int page = 0}) async {
    Map<String, dynamic> readListsResult = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'allReadLists');
    String readListsUrl = readListsResult['href'];

    Uri url = Uri.parse(readListsUrl).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the read lists, returning a [Future] object of type
  /// [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getReadLists({int? page}) async {
    return handleRequestForData(
      getReadListsAvailable,
      getReadListsResponse,
      page: page,
    );
  }

  // ***************************************************************
  // Publishers
  // ***************************************************************

  /// Checks if the 'allPublishers' functional entry is available in the opds
  /// manifest, returning a [bool] value representing if it is available or not.
  bool getPublishersAvailable() {
    if (opdsManifest.isEmpty) {
      return false;
    }

    Map<String, dynamic> publishersEntry = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'allPublishers');

    if (publishersEntry.isNotEmpty) {
      String publishersUrl = publishersEntry['href'];

      if (publishersUrl.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Creates a request to to the 'allPublishers' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  Future<http.Response> getPublishersResponse({int page = 0}) async {
    Map<String, dynamic> publishersResult = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'allPublishers');
    String publishersUrl = publishersResult['href'];

    Uri url = Uri.parse(publishersUrl).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the publishers, returning a [Future] object of type
  /// [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getPublishers({int? page}) async {
    return handleRequestForData(
      getPublishersAvailable,
      getPublishersResponse,
      page: page,
    );
  }

  // ***************************************************************
  // Search Books
  // ***************************************************************

  /// Creates a request to to the 'latestBooks' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// otherwise by default it gets the first page of results.
  Future<http.Response> getLatestBooksResponseSearch({int page = 0}) async {
    Map<String, dynamic> latestBooksResult = opdsManifest['data']
            ['functionalEntries']
        .firstWhere((entry) => entry['id'] == 'latestBooks');
    String latestBooksUrl = latestBooksResult['href'];

    Uri url = Uri.parse(latestBooksUrl).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the latest books, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getSearchResults(String query,
      {int? page}) async {
    return handleRequestForData(getLatestBooksAvailable, getLatestBooksResponse,
        searchFunction: searchByTitle, query: query);
  }

  // ***************************************************************
  // Search Series
  // ***************************************************************

  /// Checks if the 'searchBySeries' functional entry is available in the opds
  /// manifest, returning a [bool] value representing if it is available or not.
  bool getSearchResultsBySeriesAvailable() {
    if (opdsManifest.isEmpty) {
      return false;
    }

    Map<String, dynamic> searchResultsBySeriesEntry = opdsManifest['data']
            ['links']
        .firstWhere((entry) => entry['rel'] == 'search');

    if (searchResultsBySeriesEntry.isNotEmpty) {
      String searchResultsBySeriesUrl = searchResultsBySeriesEntry['href'];

      if (searchResultsBySeriesUrl.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Creates a request to to the 'search' url assuming it exists, returning
  /// a [Future] object of type [http.Response]
  Future<http.Response> getSearchResultsBySeriesResponse(String query,
      {int page = 0}) async {
    Map<String, dynamic> searchResultsBySeriesResult = opdsManifest['data']
            ['links']
        .firstWhere((entry) => entry['rel'] == 'search');
    String searchResultsBySeriesUrl = searchResultsBySeriesResult['href'];

    Uri templateUri = Uri.parse(searchResultsBySeriesUrl);

    http.Response templateResponse = await getUrl(templateUri);

    XmlDocument templateDocument = XmlDocument.parse(templateResponse.body);

    XmlElement templateUrlElement = templateDocument
        .findAllElements('OpenSearchDescription')
        .first
        .findAllElements('Url')
        .first;

    String template = templateUrlElement.getAttribute('template') ?? '';

    if (template.isEmpty) {
      return http.Response('', 400);
    }

    Uri url = Uri.parse(template).replace(
      queryParameters: {
        'search': query,
        'page': page.toString(),
      },
    );

    http.Response response = await getUrl(url);
    return response;
  }

  /// Handles the request for the search results by series, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getSearchResultsBySeries(String query,
      {int? page}) async {
    return handleRequestForDataWithSearch(
      getSearchResultsBySeriesAvailable,
      getSearchResultsBySeriesResponse,
      query,
      page: page,
    );
  }
}
