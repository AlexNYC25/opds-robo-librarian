import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:opds_robo_librarian/src/library_card/library_card.dart';
//import 'package:opds_robo_librarian/src/book/book.dart';

class LibraryCardOpds2 extends LibraryCard {
  /// Map of available entries in catalog broken down in categories:
  /// links, navigation, and groups
  Map<String, Map<String, dynamic>> opdsManifest = {};

  // ***************************************************************
  // Constructors
  // ***************************************************************

  LibraryCardOpds2(super.url, {super.username, super.password});

  // ***************************************************************
  // Server Validation
  // ***************************************************************

  /// Validates server settings to ensure that the server is set up correctly
  /// as well as parses the catalog to get the available entries. Sets the result
  /// to the [isSetUp] variable and the catalog is parsed to the [opdsManifest]
  @override
  Future<void> validateServer() async {
    int statusCode = await getRootUrlStatusCode();
    if (statusCode != 200) {
      isSetUp = false;
      return;
    }

    opdsManifest = await _buildsOpdsManifest();

    if (statusCode == 200) {
      isSetUp = true;
    }
  }

  // ***************************************************************
  // Manifest functions
  // ***************************************************************

  /// Builds the opdsManifest from the root document, returns a [Future] of a
  /// [Map] of the opdsManifest
  Future<Map<String, Map<String, dynamic>>> _buildsOpdsManifest() async {
    String rawBody = await getRootUrlContents();

    Map<String, dynamic> rootDocument = json.decode(rawBody);

    List<Map<String, dynamic>> linkEntries = [];
    List<Map<String, dynamic>> navigationEntries = [];
    List<Map<String, dynamic>> groupsEntries = [];

    List<dynamic> linkEntriesRaw = rootDocument['links'] ?? [];
    if (linkEntriesRaw.isNotEmpty) {
      linkEntries = _readLinksFromRootJson(linkEntriesRaw);
    }

    List<dynamic> navigationEntriesRaw = rootDocument['navigation'] ?? [];
    if (navigationEntriesRaw.isNotEmpty) {
      navigationEntries = _readNavigationFromRootJson(navigationEntriesRaw);
    }

    List<dynamic> groupsEntriesRaw = rootDocument['groups'] ?? [];
    if (groupsEntriesRaw.isNotEmpty) {
      groupsEntries = _readGroupsFromRootJson(groupsEntriesRaw);
    }

    Map<String, Map<String, dynamic>> opdsManifest = {
      'links': {
        'title': 'Link Entries',
        'links': linkEntries,
      },
      'navigation': {
        'title': 'Navigation Entries',
        'links': navigationEntries,
      },
      'groups': {
        'title': 'Groups Entries',
        'links': groupsEntries,
      },
    };

    return opdsManifest;
  }

  /// Parses a list of raw link objects from the root document and returns a list
  /// of formatted link objects in the form of a map
  List<Map<String, dynamic>> _readLinksFromRootJson(List<dynamic> linksRaw) {
    List<Map<String, dynamic>> links = [];

    // check through each link in the linksRaw list
    for (dynamic link in linksRaw) {
      // if the link is a map, add it to the links list
      if (link is Map<String, dynamic>) {
        Map<String, dynamic> linkMap = link;
        // if the link is not a self link, add it to the links list
        if (linkMap['rel'] != 'self') {
          links.add(linkMap);
        }
      }
    }

    return links;
  }

  /// Parses a list of raw navigation objects from the root document and returns a list
  /// of formatted navigation objects in the form of a map
  List<Map<String, dynamic>> _readNavigationFromRootJson(
      List<dynamic> navigationRaw) {
    List<Map<String, dynamic>> navigation = [];

    // check through each navigation entry in the navigationRaw list
    for (dynamic nav in navigationRaw) {
      // if the navigation entry is a map, add it to the navigation list
      if (nav is Map<String, dynamic>) {
        Map<String, dynamic> navMap = nav;
        // if the navigation entry is not a self link, add it to the navigation list
        if (navMap['rel'] != 'self') {
          navigation.add(navMap);
        }
      }
    }

    return navigation;
  }

  /// Parses a list of raw groups objects from the root document and returns a list
  List<Map<String, dynamic>> _readGroupsFromRootJson(List<dynamic> groupsRaw) {
    List<Map<String, dynamic>> groupsEntries = [];

    // check through each group entry in the groupsRaw list
    for (dynamic entry in groupsRaw) {
      // if the group entry is a map, add it to the groupsEntries list
      if (entry is Map<String, dynamic>) {
        Map<String, dynamic> entryMap = entry;
        // Try to find a title for the group entry, if not found, use 'No title found'
        String title = entryMap['metadata']['title'] ?? 'No title found';
        // Note: A group entry can have links and navigation entries, so we need to
        // check both and add them to the groupsEntries list
        List<Map<String, dynamic>> linksRaw =
            List<Map<String, dynamic>>.from(entryMap['links'] ?? []);
        List<Map<String, dynamic>> navigationRaw =
            List<Map<String, dynamic>>.from(entryMap['navigation'] ?? []);

        // parse the link entries
        for (dynamic link in linksRaw) {
          // if the link is a map
          if (link is Map<String, dynamic>) {
            Map<String, dynamic> linkMap = link;
            // check for possible rel value for the link entry, if not found, use the title
            String rel = linkMap['rel'] != null && linkMap['rel'] != 'self'
                ? linkMap['rel']
                : title;

            // create a formatted entry map
            Map<String, dynamic> formattedEntry = {
              'title': linkMap['title'] ?? title,
              'href': linkMap['href'] ?? '',
              'type': linkMap['type'] ?? '',
              'rel': rel,
            };
            // add the formatted entry to the groupsEntries list
            groupsEntries.add(formattedEntry);
          }
        }

        // parse the navigation entries
        for (dynamic nav in navigationRaw) {
          // if the navigation entry is a map
          if (nav is Map<String, dynamic>) {
            Map<String, dynamic> navMap = nav;
            // check that the navigation entry is not a self link
            if (navMap['rel'] != 'self') {
              // create a formatted entry map
              Map<String, dynamic> formattedEntry = {
                'title': navMap['title'] ?? title,
                'href': navMap['href'] ?? '',
                'type': navMap['type'] ?? '',
                'rel': navMap['rel'] ?? title,
              };
              // add the formatted entry to the groupsEntries list
              groupsEntries.add(formattedEntry);
            }
          }
        }
      }
    }

    return groupsEntries;
  }

  // ***************************************************************
  // Exclusive class functions
  // ***************************************************************

  /// Checks if there is a link entry with the passed [title] and returns the entry
  /// if found, otherwise returns an empty map
  Map<String, dynamic> _getEntry(String title) {
    Map<String, dynamic> entry = {};

    opdsManifest.forEach((key, value) {
      List<Map<String, dynamic>> links = value['links'];

      for (Map<String, dynamic> link in links) {
        if (link['title'] == title) {
          entry = link;
        }
      }
    });

    return entry;
  }

  /// checks if the passed [map] has a next page link entry, returns bool true if found
  /// otherwise returns bool false
  bool _nextPageExists(Map<String, dynamic> map) {
    bool nextFound = false;

    for (dynamic entry in map['links']) {
      if (entry is Map<String, dynamic>) {
        Map<String, dynamic> entryMap = entry;
        if (entryMap['rel'] == 'next') {
          nextFound = true;
        }
      }
    }

    return nextFound;
  }

  /// returns a list of book entries from the passed [responseBody] of type
  /// Map<String, dynamic> that is returned from the server
  List<Map<String, dynamic>> _getBookEntriesFromMap(
      Map<String, dynamic> responseBody) {
    List<Map<String, dynamic>> entries = [];

    if (responseBody['groups'] != null) {
      entries = _readGroupsFromRootJson(responseBody['groups']);
    } else if (responseBody['navigation'] != null) {
      for (dynamic entry in responseBody['navigation']) {
        if (entry is Map<String, dynamic>) {
          Map<String, dynamic> entryMap = entry;
          // check if the entry rel is not self,start,search, next if so, add it to the entries list
          entries.add(entryMap);
        }
      }
    } else {
      for (dynamic entry
          in responseBody['publications'] ?? responseBody['links']) {
        // check if the entry is a map
        if (entry is Map<String, dynamic>) {
          Map<String, dynamic> entryMap = entry;
          // check if the entry rel is not self,start,search, next if so, add it to the entries list
          entries.add(entryMap);
        }
      }
    }

    return entries;
  }

  // ***************************************************************
  // Generic Media Functions
  // ***************************************************************

  /// Handles the request for data for the different media types
  /// [checkFunction] is a function that checks if the media type is available
  /// [fetchFunction] is a function that fetches the data from the server
  /// [page] is an optional parameter that can be passed to get a specific page
  /// [searchFunction] is an optional parameter that can be passed to search the
  /// a list of entries
  /// [sortFunction] is an optional parameter that can be passed to sort the
  /// a list of entries
  Future<Map<String, dynamic>> handleRequestForData(
      bool Function() checkFunction,
      Future<http.Response> Function({int page}) fetchFunction,
      {int? page,
      List<Map<String, dynamic>> Function(List<Map<String, dynamic>>, String)?
          searchFunction,
      List<Map<String, dynamic>> Function(List<Map<String, dynamic>>)?
          sortFunction,
      String? searchString}) async {
    if (!isSetUp) {
      return cardHasNotBeenSetUp(
          errorMessage:
              'Library Card has not been set up, cannot use this functionality');
    }

    if (opdsManifest.isEmpty) {
      opdsManifest = await _buildsOpdsManifest();
    }

    if (checkFunction() == false) {
      return cardHasNotBeenSetUp(
          errorMessage:
              'This functionality is not available for this server: URL is not valid');
    }

    if (page != null && page >= 0) {
      http.Response response = await fetchFunction(page: page);
      Map<String, dynamic> responseBody = json.decode(response.body);

      List<Map<String, dynamic>> entries = _getBookEntriesFromMap(responseBody);

      return formattedDataMap(data: entries);
    }

    http.Response response = await fetchFunction();
    Map<String, dynamic> responseBody = json.decode(response.body);

    List<Map<String, dynamic>> entries = _getBookEntriesFromMap(responseBody);

    int currentPage = 1;
    int totalPages = 1;

    while (true) {
      if (_nextPageExists(responseBody)) {
        response = await fetchFunction(page: currentPage);
        responseBody = json.decode(response.body);
        entries.addAll(_getBookEntriesFromMap(responseBody));

        currentPage++;
        totalPages++;
      } else {
        break;
      }
    }

    if (searchFunction != null) {
      entries = searchFunction(entries, searchString ?? '');
    }

    if (sortFunction != null) {
      entries = sortFunction(entries);
    }

    return formattedDataMap(data: entries, totalPages: totalPages);
  }

  /// Handles the request for data for the different media types, but for search
  /// results
  /// [checkFunction] is a function that checks if the media type is available
  /// [fetchFunction] is a function that fetches the data from the server
  /// [page] is an optional parameter that can be passed to get a specific page
  /// [searchString] is an optional parameter that can be passed to search the
  /// a list of entries
  Future<Map<String, dynamic>> handleRequestForDataSearch(
      bool Function() checkFunction,
      Future<http.Response> Function(String query, {int page}) fetchFunction,
      {int? page,
      String searchString = ''}) async {
    if (!isSetUp) {
      return cardHasNotBeenSetUp(
          errorMessage:
              'Library Card has not been set up, cannot use getKeepReading');
    }

    if (checkFunction() == false) {
      return cardHasNotBeenSetUp(
          errorMessage:
              'Keep Reading not available for this server: Keep Reading URL is not valid');
    }

    if (page != null && page >= 0) {
      http.Response response = await fetchFunction(searchString, page: page);
      Map<String, dynamic> responseBody = json.decode(response.body);

      List<Map<String, dynamic>> entries = _getBookEntriesFromMap(responseBody);

      return formattedDataMap(data: entries);
    }

    http.Response response = await fetchFunction(searchString);
    Map<String, dynamic> responseBody = json.decode(response.body);

    List<Map<String, dynamic>> entries = _getBookEntriesFromMap(responseBody);

    int currentPage = 1;
    int totalPages = 1;

    while (true) {
      if (_nextPageExists(responseBody)) {
        response = await fetchFunction(searchString, page: currentPage);
        responseBody = json.decode(response.body);
        entries.addAll(_getBookEntriesFromMap(responseBody));

        currentPage++;
        totalPages++;
      } else {
        break;
      }
    }

    return formattedDataMap(data: entries, totalPages: totalPages);
  }

  // ***************************************************************
  // search, sort filters
  // ***************************************************************
  List<Map<String, dynamic>> searchByTitle(
      List<Map<String, dynamic>> entries, String query) {
    List<Map<String, dynamic>> filteredEntries = [];

    for (Map<String, dynamic> entry in entries) {
      if (entry['metadata'] != null &&
          entry['metadata']['title'] != null &&
          entry['metadata']['title'] != '' &&
          (entry['metadata']['title'] as String)
              .toLowerCase()
              .contains(query.toLowerCase())) {
        filteredEntries.add(entry);
      }
    }

    return filteredEntries;
  }

  List<Map<String, dynamic>> sortByUpdated(List<Map<String, dynamic>> entries) {
    List<Map<String, dynamic>> filteredEntries = [];

    // if they don't have a metadata.modified field, set it to the current time
    for (Map<String, dynamic> entry in entries) {
      if (entry['metadata'] == null || entry['metadata']['modified'] == null) {
        entry['metadata'] = {};
        entry['metadata']['modified'] = DateTime.now().toIso8601String();
      }
    }

    for (Map<String, dynamic> entry in entries) {
      if (entry['metadata'] != null &&
          entry['metadata']['modified'] != null &&
          entry['metadata']['modified'] != '') {
        filteredEntries.add(entry);
      }
    }

    filteredEntries.sort((a, b) {
      DateTime aDate = DateTime.parse(a['metadata']['modified']);
      DateTime bDate = DateTime.parse(b['metadata']['modified']);

      return bDate.compareTo(aDate);
    });

    return filteredEntries;
  }

  // ***************************************************************
  // Keep Reading
  // ***************************************************************

  /// Checks if the Keep Reading functionality is available for the server
  bool _getKeepReadingAvailable() {
    return _getEntry('Keep Reading').isNotEmpty;
  }

  /// Creates a request to get the Keep Reading response from the server
  /// [page] is an optional parameter that can be passed to get a specific page
  Future<http.Response> _getKeepReadingResponse({int page = 0}) async {
    Map<String, dynamic> entry = _getEntry('Keep Reading');

    String keepReadingUrl = '';

    if (entry['href'] != null && isValidUrl(entry['href'])) {
      keepReadingUrl = entry['href'];
    }

    Uri uri = Uri.parse(keepReadingUrl)
        .replace(queryParameters: {'page': page.toString()});

    http.Response response = await getUrl(uri);
    return response;
  }

  /// Requests the books that are currently being read by the user determined
  /// by the combination of the username, password and server url.
  ///
  /// Optionally a [page] variable can be passed to get a specific page, otherwise
  /// by default it gets all pages available
  @override
  Future<Map<String, dynamic>> getKeepReading({int? page}) async {
    return handleRequestForData(
        _getKeepReadingAvailable, _getKeepReadingResponse,
        page: page);
  }

  // ***************************************************************
  // On Deck
  // ***************************************************************
  /// Checks if the On Deck functionality is available for the server
  bool _getNextReadyToReadAvailable() {
    return _getEntry('On Deck').isNotEmpty;
  }

  /// Creates a request to get the On Deck response from the server
  /// [page] is an optional parameter that can be passed to get a specific page
  Future<http.Response> _getNextReadyToReadResponse({int page = 0}) async {
    Map<String, dynamic> entry = _getEntry('On Deck');

    String nextReadyToReadUrl = '';

    if (entry['href'] != null && isValidUrl(entry['href'])) {
      nextReadyToReadUrl = entry['href'];
    }

    Uri uri = Uri.parse(nextReadyToReadUrl)
        .replace(queryParameters: {'page': page.toString()});

    http.Response response = await getUrl(uri);
    return response;
  }

  /// returns a map response including a list of book entries that are next in line
  /// to be read
  @override
  Future<Map<String, dynamic>> getNextReadyToRead({int? page}) async {
    return handleRequestForData(
        _getNextReadyToReadAvailable, _getNextReadyToReadResponse,
        page: page);
  }

  // ***************************************************************
  // Latest Series
  // ***************************************************************
  /// Checks if the Latest Series functionality is available for the server
  bool _getLatestSeriesAvailable() {
    return _getEntry('Latest Series').isNotEmpty;
  }

  /// Creates a request to get the Latest Series response from the server
  /// [page] is an optional parameter that can be passed to get a specific page
  Future<http.Response> _getLatestSeriesResponse({int page = 0}) async {
    Map<String, dynamic> entry = _getEntry('Latest Series');

    String latestSeriesUrl = '';

    if (entry['href'] != null && isValidUrl(entry['href'])) {
      latestSeriesUrl = entry['href'];
    }

    Uri uri = Uri.parse(latestSeriesUrl)
        .replace(queryParameters: {'page': page.toString()});

    http.Response response = await getUrl(uri);
    return response;
  }

  /// returns a map response including a list of series entries that are the latest
  /// series added to the server
  @override
  Future<Map<String, dynamic>> getLatestSeries({int? page}) async {
    return handleRequestForData(
        _getLatestSeriesAvailable, _getLatestSeriesResponse,
        page: page);
  }

  // ***************************************************************
  // Latest Books
  // ***************************************************************
  /// Checks if the Latest Books functionality is available for the server
  bool _getLatestBooksAvailable() {
    return _getEntry('Latest Books').isNotEmpty;
  }

  /// Creates a request to get the Latest Books response from the server
  /// [page] is an optional parameter that can be passed to get a specific page
  Future<http.Response> _getLatestBooksResponse({int page = 0}) async {
    Map<String, dynamic> entry = _getEntry('Latest Books');

    String latestBooksUrl = '';

    if (entry['href'] != null && isValidUrl(entry['href'])) {
      latestBooksUrl = entry['href'];
    }

    Uri uri = Uri.parse(latestBooksUrl)
        .replace(queryParameters: {'page': page.toString()});

    http.Response response = await getUrl(uri);
    return response;
  }

  /// returns a map response including a list of book entries that are the latest
  /// books added to the server
  @override
  Future<Map<String, dynamic>> getLatestBooks({int? page}) async {
    return handleRequestForData(
        _getLatestBooksAvailable, _getLatestBooksResponse,
        page: page);
  }

  // ***************************************************************
  // Recently Updated Series
  // ***************************************************************

  /// Requests the latest series updated in the library.
  ///
  /// Optionally a [page] variable can be passed to get a specific page, otherwise
  /// by default it gets all pages available
  @override
  Future<Map<String, dynamic>> getRecentlyUpdatedSeries({int? page}) async {
    return handleRequestForData(
        _getLatestSeriesAvailable, _getLatestSeriesResponse,
        page: page, sortFunction: sortByUpdated);
  }

  // ***************************************************************
  // Libraries
  // ***************************************************************
  /// Checks if the Libraries functionality is available for the server
  bool _getLibrariesAvailable() {
    return _getEntry('Libraries').isNotEmpty;
  }

  /// Creates a request to get the Libraries response from the server
  /// [page] is an optional parameter that can be passed to get a specific page
  Future<http.Response> _getLibrariesResponse({int page = 0}) async {
    Map<String, dynamic> entry = _getEntry('Libraries');

    String librariesUrl = '';

    if (entry['href'] != null && isValidUrl(entry['href'])) {
      librariesUrl = entry['href'];
    }

    Uri uri = Uri.parse(librariesUrl)
        .replace(queryParameters: {'page': page.toString()});

    http.Response response = await getUrl(uri);
    return response;
  }

  /// Requests the Libraries available to the user determined by the combination
  /// of the username, password and server url.
  ///
  /// Note: [page] is not used in this method, but is required to be passed in
  /// as a parameter to match the method signature of the parent class.
  @override
  Future<Map<String, dynamic>> getLibraries({int? page}) async {
    return handleRequestForData(_getLibrariesAvailable, _getLibrariesResponse,
        page: page);
  }

  // ***************************************************************
  // Collections
  // ***************************************************************
  /// Checks if the Collections functionality is available for the server
  bool _getCollectionsAvailable() {
    return _getEntry('Collections').isNotEmpty;
  }

  /// Creates a request to get the Collections response from the server
  /// [page] is an optional parameter that can be passed to get a specific page
  Future<http.Response> _getCollectionsResponse({int page = 0}) async {
    Map<String, dynamic> entry = _getEntry('Collections');

    String collectionsUrl = '';

    if (entry['href'] != null && isValidUrl(entry['href'])) {
      collectionsUrl = entry['href'];
    }

    Uri uri = Uri.parse(collectionsUrl)
        .replace(queryParameters: {'page': page.toString()});

    http.Response response = await getUrl(uri);
    return response;
  }

  /// Requests the Collections available to the user determined by the combination
  /// of the username, password and server url.
  ///
  /// Optionally a [page] variable can be passed to get a specific page, otherwise
  /// by default it gets all pages available
  @override
  Future<Map<String, dynamic>> getCollections({int? page}) async {
    return handleRequestForData(
        _getCollectionsAvailable, _getCollectionsResponse,
        page: page);
  }

  // ***************************************************************
  // Search Books
  // ***************************************************************

  /// Requests a list of books that match the given [query] string.
  ///
  /// NOTE: [page] is not used for this function, but is included for consistency
  /// Due to the nature of the search function, it is not possible to get a specific
  /// page of results, only after getting the list of all books, then can the search
  /// function be applied to the list of books to get the results for a [query]
  @override
  Future<Map<String, dynamic>> getSearchResults(String query,
      {int? page}) async {
    return handleRequestForData(
        _getLatestBooksAvailable, _getLatestBooksResponse,
        page: page, searchFunction: searchByTitle, searchString: query);
  }

  // ***************************************************************
  // Read Lists
  // ***************************************************************
  /// Checks if the Read Lists functionality is available for the server
  bool _getReadListsAvailable() {
    return _getEntry('Read lists').isNotEmpty;
  }

  /// Creates a request to get the Read Lists response from the server
  /// [page] is an optional parameter that can be passed to get a specific page
  Future<http.Response> _getReadListsResponse({int page = 0}) async {
    Map<String, dynamic> entry = _getEntry('Read lists');

    String readListsUrl = '';

    if (entry['href'] != null && isValidUrl(entry['href'])) {
      readListsUrl = entry['href'];
    }

    Uri uri = Uri.parse(readListsUrl)
        .replace(queryParameters: {'page': page.toString()});

    http.Response response = await getUrl(uri);
    return response;
  }

  /// Requests the available read lists for the user determined by the combination
  /// of the username, password and server url.
  ///
  /// Optionally a [page] variable can be passed to get a specific page, otherwise
  /// by default it gets all pages available
  @override
  Future<Map<String, dynamic>> getReadLists({int? page}) async {
    return handleRequestForData(_getReadListsAvailable, _getReadListsResponse,
        page: page);
  }

  // ***************************************************************
  // Search Results by Series
  // ***************************************************************
  /// Checks if the Search Results by Series functionality is available for the server
  bool _getSearchAvailable() {
    return _getEntry('Search').isNotEmpty;
  }

  /// Creates a request to get the Search Results by Series response from the server
  /// [page] is an optional parameter that can be passed to get a specific page
  /// [query] is a required parameter that is the search string to search for
  Future<http.Response> _getSearchResponse(String query, {int page = 0}) async {
    Map<String, dynamic> entry = _getEntry('Search');

    String searchUrl = '';

    if (entry['href'] != null && isValidUrl(entry['href'])) {
      searchUrl = entry['href'];
    }

    // remove {?query} from searchUrl
    searchUrl = searchUrl.replaceAll('{?query}', '');

    Uri uri = Uri.parse(searchUrl)
        .replace(queryParameters: {'query': query, 'page': page.toString()});

    http.Response response = await getUrl(uri);
    return response;
  }

  /// Requests the search results for series that match the given [query] string.
  ///
  /// Optionally a [page] variable can be passed to get a specific page, otherwise
  /// by default it gets all pages available
  @override
  Future<Map<String, dynamic>> getSearchResultsBySeries(String query,
      {int? page}) async {
    return handleRequestForDataSearch(_getSearchAvailable, _getSearchResponse,
        page: page, searchString: query);
  }
}
