import 'package:http/http.dart' as http;
import 'dart:convert';

class LibraryCard {
  String url = '';
  String? username;
  String? password;

  bool isSetUp = false;

  LibraryCard(this.url, {this.username, this.password});

  /// This should be the first method called after instantiating a LibraryCard
  /// class object. It should set a the bool value isSetUp to true if the combination
  /// of url, username, and password are valid. If not, it should set isSetUp to false.
  Future<void> validateServer() async {
    try {
      int statusCode = await getRootUrlStatusCode();
      if (statusCode == 200) {
        isSetUp = true;
      } else {
        isSetUp = false;
      }
    } catch (error) {
      isSetUp = false;
    }
  }

  /// Return a bool value that is true if the passed [url] is a valid URL,
  /// otherwise return false
  bool isValidUrl(String url) {
    // Use Uri.tryParse to check if the string is a valid URL
    Uri? uri = Uri.tryParse(url);

    // If uri is not null, and the scheme is not null or empty, consider it a valid URL
    return uri != null && uri.hasScheme;
  }

  /// Return a Future int value that is the status code of the GET request
  /// to the root url of the library server with the appropriate headers,
  /// if the class url is not valid it should return 0
  Future<int> getRootUrlStatusCode() async {
    Uri baseURL;

    bool urlIsValid = isValidUrl(url);
    if (urlIsValid) {
      baseURL = Uri.parse(url);
    } else {
      return 0;
    }

    Map<String, String> headers = generateHeaders();

    try {
      http.Response rootResponse = await http.get(baseURL, headers: headers);
      return rootResponse.statusCode;
    } catch (error) {
      return 500;
    }
  }

  /// Return a http.Response object that is the response of the GET request
  /// to the passed [url] with the generated headers
  Future<http.Response> getUrl(Uri url) async {
    Map<String, String> headers = generateHeaders();

    http.Response response = await http.get(url, headers: headers);
    return response;
  }

  /// Creates a GET request to the root server url from the and returns the content type
  /// header value on success, otherwise returns an empty string
  Future<String> getRootContentType() async {
    Uri rootURL;

    bool urlIsValid = isValidUrl(url);
    if (urlIsValid) {
      rootURL = Uri.parse(url);
    } else {
      return '';
    }

    Map<String, String> headers = generateHeaders();

    try {
      var response = await http.get(rootURL, headers: headers);
      return response.headers['content-type'] ?? '';
    } catch (error) {
      return '';
    }
  }

  /// Creates a GET request to the root server url from the and returns the header
  /// content value of the passed [type] on success, otherwise returns an empty list
  Future<List<String>> getRootUrlHeaders({String type = ''}) async {
    Uri rootURL;

    bool urlIsValid = isValidUrl(url);
    if (urlIsValid) {
      rootURL = Uri.parse(url);
    } else {
      return [];
    }

    Map<String, String> headers = generateHeaders();

    try {
      http.Response response = await http.get(rootURL, headers: headers);

      if (type.isNotEmpty) {
        List<String> values = [];
        for (String header in response.headers.keys) {
          if (header.contains(type)) {
            values = response.headers[header]!.split(';');
            break;
          }
        }
        return values;
      }

      return response.headers.values.toList();
    } catch (error) {
      return [];
    }
  }

  /// Creates a GET request to the root server url from the and returns the body
  /// of the response on success, otherwise returns an empty string
  Future<String> getRootUrlContents() async {
    Uri rootURL;

    bool urlIsValid = isValidUrl(url);
    if (urlIsValid) {
      rootURL = Uri.parse(url);
    } else {
      return '';
    }

    Map<String, String> headers = generateHeaders();

    http.Response response = await http.get(rootURL, headers: headers);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return ''; // Handle non-200 status codes here
    }
  }

  /// Generates the headers for the http requests, such as the Authorization if
  /// the username and password are provided
  Map<String, String> generateHeaders() {
    Map<String, String> headers = {};
    if (username != null &&
        password != null &&
        username?.isNotEmpty == true &&
        password?.isNotEmpty == true) {
      headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    }

    return headers;
  }

  /// Creates a [Future] object of type [Map<String, dynamic>] object to return
  /// when the card has not been set up yet.
  ///
  /// Optionally requires a String variable [errorMessage] to be set as an error
  /// message in the map, by default it is set to be an empty string.
  ///
  /// Returns a Map with the properties
  ///   status_code: 0 (int)
  ///   data; [] (empty array)
  ///   total_pages: 0 (int)
  ///   error; [errorMessage] ?? '' (String)
  Future<Map<String, dynamic>> cardHasNotBeenSetUp({String errorMessage = ''}) {
    return Future(() => {
          'status_code': 0,
          'data': [],
          'total_pages': 0,
          'error': errorMessage
        });
  }

  /// Creates a [Future] object of type [Map<String, dynamic>] object to return
  /// when data has been attempted to be fetched and the response is not valid.
  ///
  /// Optionally requires a string variable [errorMessage] to be set as an error
  /// message in the map, by default it is set to be an empty string, optionally
  /// also requires an int [statusCode] to be set as the status code, by default
  /// it is 400.
  ///
  /// Returns a Map with the properties
  ///   status_code: [statusCode] ?? 400
  ///   data: [] (empty array)
  ///   total_pages: 0 (int)
  ///   error: [errorMessage] ?? '' (string)
  Future<Map<String, dynamic>> responseIsNotValid(
      {int statusCode = 400, String errorMessage = ''}) {
    return Future(() => {
          'status_code': statusCode,
          'data': [],
          'total_pages': 0,
          'error': errorMessage
        });
  }

  /// Creates a [Future] object of type [Map<String, dynamic>] object to return
  /// when data has been attempted to be fetched and the response is valid.
  ///
  /// Optionally requires an int [statusCode] to be set as the status code, by default
  /// it is 200, optionally also requires a List [data] to be set as the data, by
  /// default it is an empty array, and optionally requires an int [totalPages] to
  /// be set as the total pages, by default it is 0.
  Future<Map<String, dynamic>> formattedDataMap(
      {int statusCode = 200, List data = const [], int totalPages = 0}) {
    return Future(() =>
        {'status_code': statusCode, 'data': data, 'totalPages': totalPages});
  }

  /*
    Method to get a user's Keep Reading list i.e. books that are in progress
    of being read
  */
  Future<Map<String, dynamic>> getKeepReading({int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Keep Reading not set up for this library card'
    });
  }

  Future<Map<String, dynamic>> getNextReadyToRead({int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Next Ready to Read not set up for this library card'
    });
  }

  Future<Map<String, dynamic>> getLatestSeries({int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Latest Series not set up for this library card'
    });
  }

  Future<Map<String, dynamic>> getLatestBooks({int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Latest Books not set up for this library card'
    });
  }

  Future<Map<String, dynamic>> getRecentlyUpdatedSeries({int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Series by Updated not set up for this library card'
    });
  }

  Future<Map<String, dynamic>> getRecentlyReadBooks({int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Recently Read Books not set up for this library'
    });
  }

  Future<Map<String, dynamic>> getLibraries({int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Libraries not set up for this library'
    });
  }

  Future<Map<String, dynamic>> getCollections({int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Collections not set up for this library'
    });
  }

  // At the moment getSearchResults should fetch search results from the library
  // related to books i.e. thier titles.
  Future<Map<String, dynamic>> getSearchResults(String query, {int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Search not set up for this library'
    });
  }

  Future<Map<String, dynamic>> getReadLists({int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Read Lists not set up for this library'
    });
  }

  Future<Map<String, dynamic>> getPublishers({int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Publishers not set up for this library'
    });
  }

  Future<Map<String, dynamic>> getSearchResultsBySeries(String query,
      {int? page}) {
    return Future.value({
      'data': [],
      'success': false,
      'responseCode': '-1',
      'responseMessage': 'Search by Series not set up for this library'
    });
  }
}
