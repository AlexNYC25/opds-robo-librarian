class LibraryBook {
  String _id = '';
  String _title = '';
  String _bookNumber = '';

  String _acquisitionUrl = '';
  String _streamUrl = '';

  String? _seriesId;
  String? _seriesTitle;

  String? _libraryId;

  DateTime? _dateCreated;
  DateTime? _dateLastModified;

  int _sizeInBytes = 0;
  String _mediaType = '';

  int _pageCount = 0;
  int _pageReadCount = 0;
  bool _isRead = false;

  String _serverUrl = '';
  String _serverType = '';

  LibraryBook(
      this._id,
      this._title,
      this._bookNumber,
      this._seriesId,
      this._seriesTitle,
      this._libraryId,
      this._dateCreated,
      this._dateLastModified,
      this._sizeInBytes,
      this._mediaType,
      this._pageCount,
      this._pageReadCount,
      this._isRead);

  LibraryBook.fromKomgaMap(Map<String, dynamic> map, String serverUrl) {
    _id = map['id'] ?? '';
    _title = map['name'] ?? '';
    _bookNumber = map['number'].toString();

    if (_bookNumber.isNotEmpty) {
      _acquisitionUrl = '$serverUrl/api/v1/books/$_id/file/';
    }

    if (_bookNumber.isNotEmpty) {
      _streamUrl = '$serverUrl/api/v1/books/$_id/pages/[pageNumber]';
    }

    _seriesId = map['seriesId'] ?? '';
    _seriesTitle = map['seriesTitle'] ?? '';

    _libraryId = map['libraryId'] ?? '';

    _dateCreated = DateTime.tryParse(map['created'] ?? '');
    _dateLastModified = DateTime.tryParse(map['lastModified'] ?? '');

    _sizeInBytes = map['sizeBytes'] ?? 0;
    _mediaType = map['media']['mediaType'] ?? '';

    _pageCount = map['media']['pagesCount'] ?? 0;
    _pageReadCount = map['readProgress']['page'] ?? 0;
    _isRead = map['readProgress']['completed'] ?? false;

    _serverUrl = serverUrl;
    _serverType = 'Komga';
  }

  LibraryBook.fromOpds2Map(Map<String, dynamic> map, String serverUrl) {
    List<dynamic> links = map['links'] ?? [];

    for (var link in links) {
      if (link['rel'] == 'self') {
        // given the url in link['href'], we can get the book id, from get second to last part of the url
        _id = link['href'].split('/')[link['href'].split('/').length - 2];
        break;
      }
    }

    if (map['metadata'] != null && map['metadata']['title'] != null) {
      _title = map['metadata']['title'];
    }

    if (map['metadata'] != null && map['metadata']['belongsTo'] != null) {
      var series = map['metadata']['belongsTo']['series'];
      if (series != null && series.isNotEmpty) {
        _bookNumber = series[0]['position'].toString();
      }
    }

    //print('id: $_id');
    //print('title: $_title');
    //print('bookNumber: $_bookNumber');

    for (var link in links) {
      if (link['rel'] == 'http://opds-spec.org/acquisition') {
        _acquisitionUrl = link['href'] ?? '';
        break;
      }
    }

    // Note: streamUrl is not available in OPDS 2.0

    if (map['metadata'] != null &&
        map['metadata']['belongsTo'] != null &&
        map['metadata']['belongsTo']['series'] != null &&
        map['metadata']['belongsTo']['series'].isNotEmpty &&
        map['metadata']['belongsTo']['series'][0]['links'] != null &&
        map['metadata']['belongsTo']['series'][0]['links'].isNotEmpty &&
        map['metadata']['belongsTo']['series'][0]['links'][0]['href'] != null &&
        map['metadata']['belongsTo']['series'][0]['links'][0]['href']
            .isNotEmpty) {
      _seriesId = map['metadata']['belongsTo']['series'][0]['links'][0]['href']
          .split('/')[map['metadata']['belongsTo']['series'][0]['links'][0]
                  ['href']
              .split('/')
              .length -
          1];
    }
    _seriesTitle = map['metadata']['title'] ?? '';

    // Note: libraryId is not available in OPDS 2.0
    // _libraryId = '';

    // Note: dateCreated is not available in OPDS 2.0
    _dateLastModified = DateTime.tryParse(map['metadata']['modified'] ?? '');

    // Note: sizeInBytes is not available in OPDS 2.0

    for (var link in links) {
      if (link['rel'] == 'http://opds-spec.org/acquisition') {
        _mediaType = link['type'] ?? '';
        break;
      }
    }

    _pageCount = map['metadata']['numberOfPages'] ?? 0;
    // Note: pageReadCount is not available in OPDS 2.0
    //_pageReadCount = 0;
    // Note: isRead is not available in OPDS 2.0
    //_isRead = false;

    _serverUrl = serverUrl;
    _serverType = 'OPDS 2.0';
  }

  String get id => _id;
  set id(String value) => _id = value;

  String get title => _title;
  set title(String value) => _title = value;

  String get bookNumber => _bookNumber;
  set bookNumber(String value) => _bookNumber = value;

  String get acquisitionUrl => _acquisitionUrl;
  set acquisitionUrl(String value) => _acquisitionUrl = value;

  String get streamUrl => _streamUrl;
  set streamUrl(String value) => _streamUrl = value;

  String? get seriesId => _seriesId;
  set seriesId(String? value) => _seriesId = value;

  String? get seriesTitle => _seriesTitle;
  set seriesTitle(String? value) => _seriesTitle = value;

  String? get libraryId => _libraryId;
  set libraryId(String? value) => _libraryId = value;

  DateTime? get dateCreated => _dateCreated;
  set dateCreated(DateTime? value) => _dateCreated = value;

  DateTime? get dateLastModified => _dateLastModified;
  set dateLastModified(DateTime? value) => _dateLastModified = value;

  int get sizeInBytes => _sizeInBytes;
  set sizeInBytes(int value) => _sizeInBytes = value;

  String get mediaType => _mediaType;
  set mediaType(String value) => _mediaType = value;

  int get pageCount => _pageCount;
  set pageCount(int value) => _pageCount = value;

  int get pageReadCount => _pageReadCount;
  set pageReadCount(int value) => _pageReadCount = value;

  bool get isRead => _isRead;
  set isRead(bool value) => _isRead = value;

  String get serverUrl => _serverUrl;
  set serverUrl(String value) => _serverUrl = value;

  String get serverType => _serverType;
  set serverType(String value) => _serverType = value;

  void printInfo() {
    print('id: $_id');
    print('title: $_title');
    print('bookNumber: $_bookNumber');
    print('acquisitionUrl: $_acquisitionUrl');
    print('streamUrl: $_streamUrl');
    print('seriesId: $_seriesId');
    print('seriesTitle: $_seriesTitle');
    print('libraryId: $_libraryId');
    print('dateCreated: $_dateCreated');
    print('dateLastModified: $_dateLastModified');
    print('sizeInBytes: $_sizeInBytes');
    print('mediaType: $_mediaType');
    print('pageCount: $_pageCount');
    print('pageReadCount: $_pageReadCount');
    print('isRead: $_isRead');
    print('serverUrl: $_serverUrl');
    print('serverType: $_serverType');
  }

  /*
  int getFileSize(String url) {
    var client = HttpClient();
    var request = client.getUrl(Uri.parse(url));
    var response = request.then((request) => request.close());
    var headers = response.then((response) => response.headers);

    if (headers.then((headers) => headers.value('content-length')) != null) {
      return int.parse(headers.then((headers) => headers.value('content-length'))!);
    } else {
      throw Exception('Size not found');
    }
  }
  */
}
