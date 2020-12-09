import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jreader/source/source.dart';
import 'package:sprintf/sprintf.dart';

class JNovelClubSource extends Source {
  static const String _LOGIN_ENDPOINT = "https://api.j-novel.club/api/users/login?include=user";
  static const String _LOGOUT_ENDPOINT = "https://api.j-novel.club/api/users/logout";
  static const String _GET_USER_ENDPOINT = "https://api.j-novel.club/api/users/%s?filter={\"include\": [\"ownedBooks\"]}";
  static const String _PURCHASE_CREDIT_ENDPOINT = "https://api.j-novel.club/api/users/%s/purchasecredit?number=%d";
  static const String _REDEEM_CREDIT_ENDPOINT = "https://api.j-novel.club/api/users/%s/redeemcredit?titleslug=%s";
  static const String _LIST_EVENTS_ENDPOINT = "https://api.j-novel.club/api/events?filter[limit]=500";
  static const String _LIST_SERIES_ENDPOINT = "https://api.j-novel.club/api/series";
  static const String _LIST_MANGA_SERIES_ENDPOINT = "https://api.j-novel.club/api/mangaSeries";
  static const String _GET_SERIES_ENDPOINT = "https://api.j-novel.club/api/series/findOne?filter=";
  static const String _GET_SERIES_ENDPOINT_BY_ID = "$_GET_SERIES_ENDPOINT{\"where\":{\"id\":\"%s\"},\"include\":{\"volumes\": [\"publishInfos\", \"parts\"]}}";
  static const String _GET_SERIES_ENDPOINT_BY_TITLESLUG = "$_GET_SERIES_ENDPOINT{\"where\":{\"titleslug\":\"%s\"},\"include\":{\"volumes\": [\"publishInfos\", \"parts\"]}}";
  static const String _GET_MANGA_SERIES_ENDPOINT = "https://api.j-novel.club/api/mangaSeries/findOne?filter=";
  static const String _GET_MANGA_SERIES_ENDPOINT_BY_ID = "$_GET_MANGA_SERIES_ENDPOINT{\"where\":{\"id\":\"%s\"},\"include\":{\"mangaVolumes\": [\"mangaPublishInfos\", \"mangaParts\"]}}";
  static const String _GET_MANGA_SERIES_ENDPOINT_BY_TITLESLUG = "$_GET_MANGA_SERIES_ENDPOINT{\"where\":{\"titleslug\":\"%s\"},\"include\":{\"mangaVolumes\": [\"mangaPublishInfos\", \"mangaParts\"]}}";
  static const String _SEARCH_SERIES_ENDPOINT = "https://api.j-novel.club/api/series?filter={\"order\":\"%s %s\",\"where\":{\"or\":[{\"title\":{\"regexp\":\"/%s/i\"}},{\"titleShort\":{\"regexp\":\"/%s/i\"}},{\"tags\":{\"regexp\":\"/%s/i\"}},{\"author\":{\"regexp\":\"/%s/i\"}}]}}";
  static const String _SEARCH_MANGA_SERIES_ENDPOINT = "https://api.j-novel.club/api/mangaSeries?filter={\"order\":\"%s %s\",\"where\":{\"or\":[{\"title\":{\"regexp\":\"/%s/i\"}},{\"titleShort\":{\"regexp\":\"/%s/i\"}},{\"tags\":{\"regexp\":\"/%s/i\"}},{\"author\":{\"regexp\":\"/%s/i\"}}]}}";
  static const String _GET_VOLUME_ENDPOINT = "https://api.j-novel.club/api/volumes/findOne?filter=";
  static const String _GET_VOLUME_ENDPOINT_BY_ID = "$_GET_VOLUME_ENDPOINT{\"where\":{\"id\":\"%s\"},\"include\":[\"publishInfos\", \"parts\"]}";
  static const String _GET_VOLUME_ENDPOINT_BY_TITLESLUG = "$_GET_VOLUME_ENDPOINT{\"where\":{\"titleslug\":\"%s\"},\"include\":[\"publishInfos\", \"parts\"]}";
  static const String _GET_MANGA_VOLUME_ENDPOINT = "https://api.j-novel.club/api/mangaVolumes/findOne?filter=";
  static const String _GET_MANGA_VOLUME_ENDPOINT_BY_ID = "$_GET_MANGA_VOLUME_ENDPOINT{\"where\":{\"id\":\"%s\"},\"include\":[\"mangaPublishInfos\", \"mangaParts\"]}";
  static const String _GET_MANGA_VOLUME_ENDPOINT_BY_TITLESLUG = "$_GET_VOLUME_ENDPOINT{\"where\":{\"titleslug\":\"%s\"},\"include\":[\"mangaPublishInfos\", \"mangaParts\"]}";
  static const String _DOWNLOAD_VOLUME_ENDPOINT = "https://api.j-novel.club/api/volumes/%s/getpremiumebook?userId=%s&userName=%s&access_token=%s";
  static const String _GET_PART_ENDPOINT = "https://api.j-novel.club/api/parts/findOne?filter=";
  static const String _GET_PART_ENDPOINT_BY_TITLESLUG = "$_GET_PART_ENDPOINT{\"where\":{\"titleslug\":\"%s\"}}";
  static const String _GET_MANGA_PART_ENDPOINT = "https://api.j-novel.club/api/mangaParts/findOne?filter=";
  static const String _GET_MANGA_PART_ENDPOINT_BY_TITLESLUG = "$_GET_MANGA_PART_ENDPOINT{\"where\":{\"titleslug\":\"%s\"}}";
  static const String _GET_PART_DATA_ENDPOINT = "https://api.j-novel.club/api/parts/%s/partData";
  static const String _GET_ATTACHMENT_ENDPOINT = "https://d2dq7ifhe7bu0f.cloudfront.net/%s";
  static const String _GET_MANGA_PART_DRM_ENDPOINT = "https://api.j-novel.club/api/mangaParts/%s/token";
  static const String _GET_MANGA_PART_DATA_ENDPOINT = "https://m11.j-novel.club/nebel/wp/%s";

  static const Map<String, String> ORDER_BY = {
    "Title": "title",
    "Author": "author"
  };

  static const Map<String, String> ORDER_DIRECTION = {
    "Ascending": "ASC",
    "Descending": "DESC"
  };

  JNovelClubSource() : super("J-Novel Club", SearchDefinition(
    fields: [
      "Keywords"
    ],
    filters: [
      SearchFilter(
          name: "Order By",
          multiChoice: false,
          choices: ORDER_BY.keys.toList(),
          defaultOn: ["Title"]
      ),
      SearchFilter(
          name: "Order Direction",
          multiChoice: false,
          choices: ORDER_DIRECTION.keys.toList(),
          defaultOn: ["Ascending"]
      )
    ]
  ));

  @override
  bool isLoggedIn() {
    return getAuthField("username") != null
        && getAuthField("userId") != null
        && getAuthField("authToken") != null;
  }

  @override
  String getUsername() {
    return getAuthField("username");
  }

  @override
  Future<List<String>> getUserInfo() async {
    if (!isLoggedIn()) {
      throw Exception('Not logged in');
    }

    return getSingle(sprintf(_GET_USER_ENDPOINT, [getAuthField("userId")]), (json) => [
      "Credits: ${json['earnedCredits'] - json['usedCredits']}"
    ]);
  }

  @override
  Future<void> login(String username, String password) async {
    return post(_LOGIN_ENDPOINT, {"email": username, "password": password}, (json) => json).then((json) {
      setAuthField("username", username);
      setAuthField("userId", json['userId']);
      setAuthField("authToken", json['id']);
    });
  }

  @override
  Future<void> logout() async {
    return post(_LOGOUT_ENDPOINT, {}, (json) => null).then((_) {
      clearAuthFields();
    }).catchError((e) {
      clearAuthFields();
    });
  }

  @override
  Future<List<Content>> listSeries({int page = 0}) async {
    if(page != 0) {
      return [];
    }

    return getList(_LIST_SERIES_ENDPOINT, (json) => JNovelClubSeries(this, json, false)).then((novels) {
      return getList(_LIST_MANGA_SERIES_ENDPOINT, (json) => JNovelClubSeries(this, json, true)).then((manga) {
        novels.addAll(manga);
        novels.sort((a, b) => -a.meta.date.compareTo(b.meta.date));
        return novels;
      });
    });
  }

  @override
  Future<Content> getSeries(String id) async {
    return getSingle(sprintf(_GET_SERIES_ENDPOINT_BY_ID, [id]), (json) => JNovelClubSeries(this, json, false)).catchError((e) {
      return getSingle(sprintf(_GET_MANGA_SERIES_ENDPOINT_BY_ID, [id]), (json) => JNovelClubSeries(this, json, true));
    });
  }

  @override
  Future<List<Content>> searchSeries(Map<String, String> fields, Map<String, Map<String, bool>> filters, {int page = 0}) async {
    if(page != 0) {
      return [];
    }

    String orderBy;
    for(final entry in filters["Order By"].entries) {
      if(entry.value) {
        orderBy = entry.key;
        break;
      }
    }

    String orderDirection;
    for(final entry in filters["Order Direction"].entries) {
      if(entry.value) {
        orderDirection = entry.key;
        break;
      }
    }

    return getList(sprintf(_SEARCH_SERIES_ENDPOINT, [
      ORDER_BY[orderBy],
      ORDER_DIRECTION[orderDirection],
      fields["Keywords"], fields["Keywords"], fields["Keywords"], fields["Keywords"]
    ]), (json) => JNovelClubSeries(this, json, false)).then((novels) {
      return getList(sprintf(_SEARCH_MANGA_SERIES_ENDPOINT, [
        ORDER_BY[orderBy],
        ORDER_DIRECTION[orderDirection],
        fields["Keywords"], fields["Keywords"], fields["Keywords"], fields["Keywords"]
      ]), (json) => JNovelClubSeries(this, json, true)).then((manga) {
        novels.addAll(manga);
        novels.sort((a, b) {
          String keyA = "";
          String keyB = "";
          if(orderBy == "Title") {
            keyA = a.meta.title;
            keyB = b.meta.title;
          } else if(orderBy == "Author") {
            keyA = a.meta.author;
            keyB = b.meta.author;
          }

          if(orderDirection == "Ascending") {
            return keyA.compareTo(keyB);
          } else if(orderDirection == "Descending") {
            return -keyA.compareTo(keyB);
          } else {
            return 0;
          }
        });
        return novels;
      });
    });
  }

  @override
  Future<List<Event>> listEvents() {
    return getList(_LIST_EVENTS_ENDPOINT, (json) => JNovelClubEvent(this, json));
  }

  /*Future<void> purchaseCredits(int count) async {
    if(!isLoggedIn()) {
      throw Exception('Not logged in');
    }

    post(sprintf(_PURCHASE_CREDIT_ENDPOINT, [getAuthField("userId"), count]), {}, (json) => null);
  }

  String getVolumeEpubUrl(String id) {
    if(!isLoggedIn()) {
      throw Exception('Not logged in');
    }

    return sprintf(_DOWNLOAD_VOLUME_ENDPOINT, [id, getAuthField("userId"), getAuthField("username"), getAuthField("authToken")]);
  }*/

  Future<T> getSingle<T>(String endpoint, T factoryFunc(Map<String, dynamic> json)) async {
    return http.get(Uri.encodeFull(endpoint), headers: _getHeaders()).then((response) {
      if (response.statusCode == 200) {
        return factoryFunc(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch data: Request returned status code ${response.statusCode}: ${response.body}');
      }
    });
  }

  Future<List<T>> getList<T>(String endpoint, T factoryFunc(Map<String, dynamic> json)) async {
    return http.get(Uri.encodeFull(endpoint), headers: _getHeaders()).then((response) {
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List)?.map((e) => factoryFunc(e))?.toList();
      } else {
        throw Exception('Failed to fetch list: Request returned status code ${response.statusCode}: ${response.body}');
      }
    });
  }

  Future<T> post<T>(String endpoint, Map<String, dynamic> body, T factoryFunc(Map<String, dynamic> json)) async {
    return postRaw<T>(endpoint, json.encode(body), factoryFunc);
  }

  Future<T> postRaw<T>(String endpoint, String body, T factoryFunc(Map<String, dynamic> json)) async {
    Map<String, String> headers = _getHeaders();
    headers["Content-Type"] = "application/json; charset=utf-8";

    return http.post(Uri.encodeFull(endpoint), headers: headers, body: body).then((response) {
      if (response.statusCode == 200) {
        return factoryFunc(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch data: Request returned status code ${response.statusCode}: ${response.body}');
      }
    });
  }

  Map<String, String> _getHeaders() {
    if(isLoggedIn()) {
      return {"Authorization": getAuthField("authToken")};
    } else {
      return {};
    }
  }
}

class JNovelClubSeries extends Content<Content> {
  Map<String, dynamic> _json;
  bool _manga;

  JNovelClubSeries(JNovelClubSource source, this._json, this._manga) : super(source, _createMeta(_json, _manga));

  @override
  bool isFilled() {
    return _json != null && children != null;
  }

  @override
  Future<void> fill() async {
    final key = _manga ? 'mangaVolumes' : 'volumes';
    Future<void> jsonFuture = Future.value();
    bool refreshJson = _json == null || !_json.containsKey(key);
    if(refreshJson) {
      jsonFuture = (source as JNovelClubSource).getSingle(sprintf(_manga ? JNovelClubSource._GET_MANGA_SERIES_ENDPOINT_BY_ID : JNovelClubSource._GET_SERIES_ENDPOINT_BY_ID, [_json['id']]), (json) => json).then((json) {
        _json = json;
        meta = _createMeta(json, _manga);
      });
    }

    if(children == null || refreshJson) {
      return jsonFuture.then((_) {
        final contents = (_json[key] as List)?.map((e) => JNovelClubVolume(source as JNovelClubSource, e, _manga))?.toList();
        contents.sort((a, b) => a.meta.date.compareTo(b.meta.date));
        children = contents;
      });
    } else {
      return jsonFuture;
    }
  }

  @override
  Future<PurchaseStatus> getPurchaseStatus() async {
    return PurchaseStatus.NOT_SUPPORTED;
  }

  @override
  Future<void> purchase() {
  }

  static Metadata _createMeta(Map<String, dynamic> json, bool manga) {
    final volumesKey = manga ? 'mangaVolumes' : 'volumes';
    final partsKey = manga ? 'mangaParts' : 'parts';

    final leafs = new Map<String, DateTime>();
    if(json.containsKey(volumesKey)) {
      for(final volume in json[volumesKey]) {
        if(volume.containsKey(partsKey)) {
          for(final part in volume[partsKey]) {
            if(!part['expired']) {
              leafs[part['id']] = DateTime.parse(part['created']);
            }
          }
        }
      }
    }

    return Metadata(
        type: ContentType.SERIES,
        id: json['id'],
        title: json['title'],
        author: json['author'],
        description: json['description'],
        date: DateTime.parse(json['created']),
        coverUrl: sprintf(JNovelClubSource._GET_ATTACHMENT_ENDPOINT, [json['attachments'][0]['fullpath']]),
        leafs: leafs
    );
  }
}

class JNovelClubVolume extends Content<Content> {
  Map<String, dynamic> _json;
  bool _manga;

  JNovelClubVolume(JNovelClubSource source, this._json, this._manga) : super(source, _createMeta(_json, _manga));

  @override
  bool isFilled() {
    return _json != null && children != null;
  }

  @override
  Future<void> fill() async {
    final key = _manga ? 'mangaParts' : 'parts';
    Future<void> jsonFuture = Future.value();
    bool refreshJson = _json == null || !_json.containsKey(key);
    if(refreshJson) {
      jsonFuture = (source as JNovelClubSource).getSingle(sprintf(_manga ? JNovelClubSource._GET_MANGA_VOLUME_ENDPOINT_BY_ID : JNovelClubSource._GET_VOLUME_ENDPOINT_BY_ID, [_json['id']]), (json) => json).then((json) {
        _json = json;
        meta = _createMeta(json, _manga);
      });
    }

    if(children == null || refreshJson) {
      return jsonFuture.then((json) {
        final built = new List<Content>();
        for(final entry in _json[key]) {
          if(!entry['expired']) {
            built.add(_manga
                ? JNovelClubMangaPart(source as JNovelClubSource, entry)
                : JNovelClubNovelPart(source as JNovelClubSource, entry));
          }
        }

        built.sort((a, b) => -a.meta.date.compareTo(b.meta.date));
        children = built;
      });
    } else {
      return jsonFuture;
    }
  }

  @override
  Future<PurchaseStatus> getPurchaseStatus() async {
    final src = source as JNovelClubSource;
    if (!src.isLoggedIn()) {
      return PurchaseStatus.NOT_LOGGED_IN;
    }

    return src.getSingle(sprintf(JNovelClubSource._GET_USER_ENDPOINT, [src.getAuthField("userId")]), (json) => {
      "credits": json['earnedCredits'] - json['usedCredits'],
      "ownedBookIds": (json['ownedBooks'] as List)?.map((o) => o['id'])?.toList()
    }).then((userInfo) {
      final publishInfosKey = _manga ? "mangaPublishInfos" : "publishInfos";
      if(userInfo["ownedBookIds"].contains(meta.id)) {
        return PurchaseStatus.PURCHASED;
      } else if(_json["nopremium"] || _json[publishInfosKey] == null || _json[publishInfosKey].length == 0) {
        return PurchaseStatus.NOT_AVAILABLE;
      } else if(userInfo["credits"] <= 0) {
        return PurchaseStatus.NOT_ENOUGH_CREDITS;
      } else {
        return PurchaseStatus.CAN_PURCHASE;
      }
    });
  }

  @override
  Future<void> purchase() {
    final src = source as JNovelClubSource;
    if(!src.isLoggedIn()) {
      throw Exception('Not logged in');
    }

    return src.post(sprintf(JNovelClubSource._REDEEM_CREDIT_ENDPOINT, [src.getAuthField("userId"), _json['titleslug']]), {}, (json) => null);
  }

  static Metadata _createMeta(Map<String, dynamic> json, bool manga) {
    final leafs = new Map<String, DateTime>();
    final key = manga ? 'mangaParts' : 'parts';
    if(json.containsKey(key)) {
      for(final entry in json[key]) {
        if(!entry['expired']) {
          leafs[entry['id']] = DateTime.parse(entry['created']);
        }
      }
    }

    return Metadata(
        type: ContentType.VOLUME,
        id: json['id'],
        title: json['title'],
        author: json['author'],
        description: json['description'],
        date: DateTime.parse(json['created']),
        coverUrl: sprintf(JNovelClubSource._GET_ATTACHMENT_ENDPOINT, [json['attachments'][0]['fullpath']]),
        leafs: leafs
    );
  }
}

class JNovelClubNovelPart extends Content<String> {
  Map<String, dynamic> _json;

  JNovelClubNovelPart(JNovelClubSource source, this._json) : super(source, Metadata(
      type: ContentType.NOVEL_PART,
      id: _json['id'],
      title: _json['title'],
      author: _json['author'],
      description: _json['description'],
      date: DateTime.parse(_json['created']),
      coverUrl: null,
      leafs: {_json['id']: DateTime.parse(_json['created'])}
  ));

  @override
  bool isFilled() {
    return children != null;
  }

  @override
  Future<void> fill() async {
    if(children == null) {
      return (source as JNovelClubSource).getSingle(sprintf(JNovelClubSource._GET_PART_DATA_ENDPOINT, [_json['id']]), (json) => json['dataHTML']).then((value) {
        children = [value];
      });
    }
  }

  @override
  Future<PurchaseStatus> getPurchaseStatus() async {
    return PurchaseStatus.NOT_SUPPORTED;
  }

  @override
  Future<void> purchase() {
  }
}

class JNovelClubMangaPart extends Content<String> {
  Map<String, dynamic> _json;

  JNovelClubMangaPart(JNovelClubSource source, this._json) : super(source, Metadata(
      type: ContentType.MANGA_PART,
      id: _json['id'],
      title: _json['title'],
      author: _json['author'],
      description: _json['description'],
      date: DateTime.parse(_json['created']),
      coverUrl: null,
      leafs: {_json['id']: DateTime.parse(_json['created'])}
  ));

  @override
  bool isFilled() {
    return children != null;
  }

  @override
  Future<void> fill() async {
    if(children == null) {
      return (source as JNovelClubSource).getSingle(sprintf(JNovelClubSource._GET_MANGA_PART_DRM_ENDPOINT, [_json['id']]), (json) => json).then((drmInfo) {
        return (source as JNovelClubSource).postRaw(sprintf(JNovelClubSource._GET_MANGA_PART_DATA_ENDPOINT, [drmInfo['uuid']]), drmInfo['ngtoken'], (json) => json);
      }).then((partData) {
        final built = new List<String>();
        (partData["readingOrder"] as List).forEach((page) {
          built.add(page["href"]);
        });

        children = built;
      });
    }
  }

  @override
  Future<PurchaseStatus> getPurchaseStatus() async {
    return PurchaseStatus.NOT_SUPPORTED;
  }

  @override
  Future<void> purchase() {
  }
}

class JNovelClubEvent extends Event {
  JNovelClubSource _source;
  Map<String, dynamic> _json;

  JNovelClubEvent(this._source, this._json) : super(
      name: _json['name'],
      details: _json['details'],
      date: DateTime.parse(_json['date']),
      coverUrl: _json['attachments'].isNotEmpty ? sprintf(JNovelClubSource._GET_ATTACHMENT_ENDPOINT, [_json['attachments'][0]['fullpath']]) : null
  );

  @override
  Future<Content> getContent() async {
    final type = _json['seriesType'];
    final linkFragment = _json['linkFragment'];
    final titleslug = linkFragment
        .replaceFirst("/c/", "")
        .replaceFirst("/v/", "")
        .replaceFirst("/s/", "")
        .replaceAll("/", "");
    if(linkFragment.startsWith("/s/")) {
      if(type == "Novel") {
        return _source.getSingle(sprintf(JNovelClubSource._GET_SERIES_ENDPOINT_BY_TITLESLUG, [titleslug]),
                (json) => JNovelClubSeries(_source, json, false));
      } else {
        return _source.getSingle(sprintf(JNovelClubSource._GET_MANGA_SERIES_ENDPOINT_BY_TITLESLUG, [titleslug]),
                (json) => JNovelClubSeries(_source, json, true));
      }
    } else if(linkFragment.startsWith("/v/")) {
    if(type == "Novel") {
        return _source.getSingle(sprintf(JNovelClubSource._GET_VOLUME_ENDPOINT_BY_TITLESLUG, [titleslug]),
                (json) => JNovelClubVolume(_source, json, false));
      } else {
        return _source.getSingle(sprintf(JNovelClubSource._GET_MANGA_VOLUME_ENDPOINT_BY_TITLESLUG, [titleslug]),
                (json) => JNovelClubVolume(_source, json, true));
      }
    } else if(linkFragment.startsWith("/c/")) {
    if(type == "Novel") {
        return _source.getSingle(sprintf(JNovelClubSource._GET_PART_ENDPOINT_BY_TITLESLUG, [titleslug]),
                (json) => JNovelClubNovelPart(_source, json));
      } else {
        return _source.getSingle(sprintf(JNovelClubSource._GET_MANGA_PART_ENDPOINT_BY_TITLESLUG, [titleslug]),
                (json) => JNovelClubMangaPart(_source, json));
      }
    } else {
      throw new Exception("Unknown link fragment \"$linkFragment\".");
    }
  }
}

class User {
  final String email;
  final int credits;
  final List<String> ownedBookIds;

  User({this.email, this.credits, this.ownedBookIds});
}