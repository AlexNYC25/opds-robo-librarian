import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:opds_robo_librarian/src/library_card/library_card.dart';
//import 'package:opds_robo_librarian/src/book/book.dart';

/// A class that represents a Library Card for a Komga server instance.
class LibraryCardKomga extends LibraryCard {
  // ***************************************************************
  // Constructors
  // ***************************************************************

  LibraryCardKomga(super.url, {super.username, super.password});

  // ***************************************************************
  // Generic Media Functions
  // ***************************************************************

  Future<Map<String, dynamic>> handleRequestForData(
      Future<http.Response> Function({int page}) fetchFunction,
      {int? page}) async {
    if (!isSetUp) {
      return cardHasNotBeenSetUp(
          errorMessage:
              'Library Card has not been set up, cannot use this function');
    }

    if (page != null && page >= 0) {
      int pageFetch = page;
      http.Response response = await fetchFunction(page: pageFetch);

      Map<String, dynamic> responseBody = json.decode(response.body) is List
          ? {'content': json.decode(response.body)}
          : json.decode(response.body);

      if (response.statusCode == 400) {
        return responseIsNotValid(
            statusCode: response.statusCode,
            errorMessage: responseBody['error']);
      }

      int totalPages = 0;
      List results = [];

      results.addAll(responseBody['content']);

      return formattedDataMap(
          statusCode: response.statusCode,
          data: results,
          totalPages: totalPages);
    }

    // get all pages of results
    http.Response response = await fetchFunction();
    // check json response if it is a map or a list, if a list then convert to a map
    Map<String, dynamic> responseBody = json.decode(response.body) is List
        ? {'content': json.decode(response.body)}
        : json.decode(response.body);

    if (response.statusCode == 400) {
      return responseIsNotValid(
        statusCode: response.statusCode,
        errorMessage: responseBody['error'],
      );
    }

    int totalPages = 1;
    List results = [];

    results.addAll(responseBody['content']);

    for (int i = 1; i < totalPages; i++) {
      response = await fetchFunction(page: i);
      responseBody = json.decode(response.body) is List
          ? {'content': json.decode(response.body)}
          : json.decode(response.body);

      if (response.statusCode == 200) {
        results.addAll(responseBody['content']);
      } else {
        break;
      }
    }

    return formattedDataMap(
        statusCode: response.statusCode, data: results, totalPages: totalPages);
  }

  Future<Map<String, dynamic>> handleRequestForDataWithSearch(
      Future<http.Response> Function(String query, {int page}) fetchFunction,
      String query,
      {int? page}) async {
    if (!isSetUp) {
      return cardHasNotBeenSetUp(
          errorMessage:
              'Library Card has not been set up, cannot use this function');
    }

    if (page != null && page >= 0) {
      int pageFetch = page;
      http.Response response = await fetchFunction(query, page: pageFetch);

      Map<String, dynamic> responseBody = json.decode(response.body) is List
          ? {'content': json.decode(response.body)}
          : json.decode(response.body);

      if (response.statusCode == 400) {
        return responseIsNotValid(
            statusCode: response.statusCode,
            errorMessage: responseBody['error']);
      }

      int totalPages = 0;
      List results = [];

      results.addAll(responseBody['content']);

      return formattedDataMap(
          statusCode: response.statusCode,
          data: results,
          totalPages: totalPages);
    }

    // get all pages of results
    http.Response response = await fetchFunction(query);
    // check json response if it is a map or a list, if a list then convert to a map
    Map<String, dynamic> responseBody = json.decode(response.body) is List
        ? {'content': json.decode(response.body)}
        : json.decode(response.body);

    if (response.statusCode == 400) {
      return responseIsNotValid(
        statusCode: response.statusCode,
        errorMessage: responseBody['error'],
      );
    }

    int totalPages = 1;
    List results = [];

    results.addAll(responseBody['content']);

    for (int i = 1; i < totalPages; i++) {
      response = await fetchFunction(query, page: i);
      responseBody = json.decode(response.body) is List
          ? {'content': json.decode(response.body)}
          : json.decode(response.body);

      if (response.statusCode == 200) {
        results.addAll(responseBody['content']);
      } else {
        break;
      }
    }

    return formattedDataMap(
        statusCode: response.statusCode, data: results, totalPages: totalPages);
  }

  // ***************************************************************
  // Keep Reading
  // ***************************************************************

  /// Creates a request to the /books endpoint of the Komga server, returning a
  /// [Future] object of type [http.Response] object
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// otherwise by default it gets the first page of results.
  Future<http.Response> getCurrentlyReadingResponse({int page = 0}) async {
    // Need to set the sort parameter to readProgress.readDate,desc, with the
    // read_status parameter set to IN_PROGRESS, in order to use the /books route
    // to get the currently reading books
    Uri currentlyReadingUrl =
        Uri.parse('$url/api/v1/books').replace(queryParameters: {
      'sort': 'readProgress.readDate,desc',
      'read_status': 'IN_PROGRESS',
      'page': '$page',
    });

    http.Response response = await getUrl(currentlyReadingUrl);
    return response;
  }

  /// Handles the request for the currently reading books, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getKeepReading({int? page}) async {
    return handleRequestForData(getCurrentlyReadingResponse, page: page);
  }

  // ***************************************************************
  // On Deck
  // ***************************************************************

  /// Creates a request to the /books/ondeck endpoint of the Komga server,
  /// returning a [Future] object of type [http.Response] object
  ///
  /// Optionally a [page] number can be passed to get a specific page of results.
  Future<http.Response> getNextOnDeckResponse({int page = 0}) async {
    Uri nextOnDeckUrl =
        Uri.parse('$url/api/v1/books/ondeck').replace(queryParameters: {
      'page': '$page',
    });

    http.Response response = await getUrl(nextOnDeckUrl);
    return response;
  }

  /// Handles the request for the next on deck books, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getNextReadyToRead({int? page}) async {
    return handleRequestForData(getNextOnDeckResponse, page: page);
  }

  // ***************************************************************
  // Latest Series
  // ***************************************************************

  /// Creates a request to the /series/new endpoint of the Komga server,
  /// returning a [Future] object of type [http.Response] object
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// optionally a [includeOneShots] bool can be passed to include one-shots as
  /// well along with series.
  Future<http.Response> getLatestSeriesResponse(
      {int page = 0, bool includeOneShots = false}) async {
    Uri seriesUrl =
        Uri.parse('$url/api/v1/series/new').replace(queryParameters: {
      'oneshot': '$includeOneShots',
      'page': '$page',
    });

    http.Response response = await getUrl(seriesUrl);
    return response;
  }

  /// Handles the request for the latest series, returning a [Future] object of
  /// type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getLatestSeries({int? page}) async {
    return handleRequestForData(getLatestSeriesResponse, page: page);
  }

  // ***************************************************************
  // Latest Books
  // ***************************************************************

  /// Creates a request to the /books/latest endpoint of the Komga server,
  /// returning a [Future] object of type [http.Response] object
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// optionally a [includeOneShots] bool can be passed to include one-shots as
  /// well along with books belonging to a series.
  Future<http.Response> getLatestBooksResponse(
      {int page = 0, bool includeOneShots = false}) async {
    Uri baseUrl =
        Uri.parse('$url/api/v1/books/latest').replace(queryParameters: {
      'oneshot': '$includeOneShots',
      'page': '$page',
    });

    http.Response response = await getUrl(baseUrl);
    return response;
  }

  /// Handles the request for the latest books, returning a [Future] object of
  /// type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getLatestBooks({int? page}) async {
    return handleRequestForData(getLatestBooksResponse, page: page);
  }

  // ***************************************************************
  // Recently Updated Series
  // ***************************************************************

  /// Creates a request to the /series/updated endpoint of the Komga server,
  /// returning a [Future] object of type [http.Response] object
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// optionally a [includeOneShots] bool can be passed to include one-shots as
  /// well along with series.
  Future<http.Response> getRecentlyUpdatedSeriesResponse(
      {int page = 0, bool includeOneShots = false}) async {
    Uri updatedSeriesUrl =
        Uri.parse('$url/api/v1/series/updated').replace(queryParameters: {
      'oneshot': '$includeOneShots',
      'page': '$page',
    });

    http.Response response = await getUrl(updatedSeriesUrl);
    return response;
  }

  /// Handles the request for the recently updated series, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getRecentlyUpdatedSeries({int? page}) async {
    return handleRequestForData(getRecentlyUpdatedSeriesResponse, page: page);
  }

  // ***************************************************************
  // Recently Read Books
  // ***************************************************************

  /// Creates a request to the /books endpoint of the Komga server, returning a
  /// [Future] object of type [http.Response] object
  ///
  /// Optionally a [page] number can be passed to get a specific page of results,
  /// optionally a [sort] string can be passed to sort the results by a specific
  /// field, by default the results are sorted by the readDate property of the
  /// readProgress object of a book in descending order.
  Future<http.Response> getRecentlyReadBooksResponse(
      {int page = 0, String sort = 'readDate'}) async {
    // Needs to set a sort property to sort books data by a specific field,
    // additionally the read_status parameter needs to be set to READ in order
    // to get books that have been read
    Uri historyUrl = Uri.parse('$url/api/v1/books').replace(queryParameters: {
      'sort': 'readProgress.$sort,desc',
      'read_status': 'READ',
      'page': '$page',
    });

    http.Response response = await getUrl(historyUrl);
    return response;
  }

  /// Handles the request for the recently read books, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getRecentlyReadBooks({int? page}) async {
    return handleRequestForData(getRecentlyReadBooksResponse, page: page);
  }

  // ***************************************************************
  // Libraries
  // ***************************************************************

  /// Creates a request to the /books endpoint of the Komga server, returning a
  /// [Future] object of type [http.Response] object
  ///
  /// Optionally a [page] number can be passed to get a specific page of results.
  Future<http.Response> getLibrariesResponse({page = 0}) async {
    Uri librariesUrl = Uri.parse('$url/api/v1/libraries').replace(
      queryParameters: {
        'page': '$page',
      },
    );

    http.Response response = await getUrl(librariesUrl);
    return response;
  }

  /// Handles the request for the libraries, returning a [Future] object of type
  /// [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getLibraries({int? page}) async {
    return handleRequestForData(getLibrariesResponse, page: page);
  }

  // ***************************************************************
  // Collections
  // ***************************************************************

  /// Creates a request to the /collections endpoint of the Komga server,
  /// returning a [Future] object of type [http.Response] object
  ///
  /// Optionally a [page] number can be passed to get a specific page of results.
  Future<http.Response> getCollectionsResponse({int page = 0}) async {
    Uri collectionsUrl = Uri.parse('$url/api/v1/collections').replace(
      queryParameters: {
        'page': '$page',
      },
    );

    http.Response response = await getUrl(collectionsUrl);
    return response;
  }

  /// Handles the request for the collections, returning a [Future] object of
  /// type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getCollections({int? page}) async {
    return handleRequestForData(getCollectionsResponse, page: page);
  }

  // ***************************************************************
  // Read Lists
  // ***************************************************************

  /// Creates a request to the /readlists endpoint of the Komga server, returning
  /// a [Future] object of type [http.Response] object
  ///
  /// Optionally a [page] number can be passed to get a specific page of results.
  Future<http.Response> getReadListsResponse({int page = 0}) async {
    Uri readListsUrl = Uri.parse('$url/api/v1/readlists').replace(
      queryParameters: {
        'page': '$page',
      },
    );

    http.Response response = await getUrl(readListsUrl);
    return response;
  }

  /// Handles the request for the read lists, returning a [Future] object of
  /// type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getReadLists({int? page}) async {
    return handleRequestForData(getReadListsResponse, page: page);
  }

  // ***************************************************************
  // Publishers
  // ***************************************************************

  /// Creates a request to the /publishers endpoint of the Komga server,
  /// returning a [Future] object of type [http.Response] object
  ///
  /// Optionally a [page] number can be passed to get a specific page of results.
  Future<http.Response> getPublishersResults({int page = 0}) async {
    Uri publishersUrl = Uri.parse('$url/api/v1/publishers').replace(
      queryParameters: {
        'page': '$page',
      },
    );

    http.Response response = await getUrl(publishersUrl);
    return response;
  }

  /// Handles the request for the publishers, returning a [Future] object of
  /// type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getPublishers({int? page}) async {
    return handleRequestForData(getPublishersResults, page: page);
  }

  // ***************************************************************
  // Search Results
  // ***************************************************************

  /// Creates a request to the /books endpoint of the Komga server, returning a
  /// [Future] object of type [http.Response] object
  ///
  /// A [query] string is required to search for books, optionally a [page]
  /// number can be passed to get a specific page of results.
  Future<http.Response> getSearchResultsResponse(String query,
      {int page = 0}) async {
    Uri searchUrl = Uri.parse('$url/api/v1/books').replace(queryParameters: {
      'search': query,
      'page': '$page',
    });

    http.Response response = await getUrl(searchUrl);
    return response;
  }

  /// Handles the request for the search results, returning a [Future] object of
  /// type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getSearchResults(String query,
      {int? page}) async {
    return handleRequestForDataWithSearch(getSearchResultsResponse, query,
        page: page);
  }

  // ***************************************************************
  // Search Results by Series
  // ***************************************************************

  /// Creates a request to the /series endpoint of the Komga server, returning a
  /// [Future] object of type [http.Response] object
  ///
  /// A [query] string is required to search for series, optionally a [page]
  /// number can be passed to get a specific page of results.
  Future<http.Response> getSearchSeriesQueryResults(String query,
      {int page = 0}) async {
    Uri searchUrl = Uri.parse('$url/api/v1/series').replace(queryParameters: {
      'search': query,
      'page': '$page',
    });

    http.Response response = await getUrl(searchUrl);
    return response;
  }

  /// Handles the request for the search results by series, returning a [Future]
  /// object of type [Map<String, dynamic>]
  @override
  Future<Map<String, dynamic>> getSearchResultsBySeries(String query,
      {int? page}) async {
    return handleRequestForDataWithSearch(getSearchSeriesQueryResults, query,
        page: page);
  }
}
