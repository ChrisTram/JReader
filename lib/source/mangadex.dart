import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:jreader/source/source.dart';
import 'package:sprintf/sprintf.dart';

class MangaDexSource extends Source {
  static const String _LOGIN_PAGE = "https://mangadex.org/login";
  static const String _LOGIN_ENDPOINT = "https://mangadex.org/ajax/actions.ajax.php?function=login";
  static const String _LOGOUT_PAGE = "https://mangadex.org";
  static const String _LOGOUT_ENDPOINT = "https://mangadex.org/ajax/actions.ajax.php?function=logout";
  static const String _POPULAR_MANGA_URL = "https://mangadex.org/titles/7/%d";
  static const String _SEARCH_URL = "https://mangadex.org/search?%s";
  static const String _LATEST_UPDATES_URL = "https://mangadex.org/updates";
  static const String _GET_MANGA_ENDPOINT = "https://mangadex.org/api/manga/%s";
  static const String _GET_CHAPTER_ENDPOINT = "https://mangadex.org/api/chapter/%s";

  static const String _COVER_URL = "https://mangadex.org%s";
  static const _DEFAULT_PAGE_SERVER = "https://mangadex.org/";

  static const String _SESSION_COOKIE_NAME = "mangadex_session";
  static const String _TOKEN_COOKIE_NAME = "mangadex_rememberme_token";

  static const Map<String, int> DEMOGRAPHICS = {
    "Shounen": 1,
    "Shoujo": 2,
    "Seinen": 3,
    "Josei": 4
  };

  static const Map<String, int> PUBLICATION_STATUS = {
    "Ongoing": 1,
    "Completed": 2,
    "Cancelled": 3,
    "Hiatus": 4
  };

  static const Map<String, int> TAGS = {
    "4-Koma": 1,
    "Action": 2,
    "Adventure": 3,
    "Award Winning": 4,
    "Comedy": 5,
    "Cooking": 6,
    "Doujinshi": 7,
    "Drama": 8,
    "Ecchi": 9,
    "Fantasy": 10,
    "Gyaru": 11,
    "Harem": 12,
    "Historical": 13,
    "Horror": 14,
    "Martial Arts": 16,
    "Mecha": 17,
    "Medical": 18,
    "Music": 19,
    "Mystery": 20,
    "Oneshot": 21,
    "Psychological": 22,
    "Romance": 23,
    "School Life": 24,
    "Sci-Fi": 25,
    "Shoujo Ai": 28,
    "Shounen Ai": 30,
    "Slice of Life": 31,
    "Smut": 32,
    "Sports": 33,
    "Supernatural": 34,
    "Tragedy": 35,
    "Long Strip": 36,
    "Yaoi": 37,
    "Yuri": 38,
    "Video Games": 40,
    "Isekai": 41,
    "Adaptation": 42,
    "Anthology": 43,
    "Web Comic": 44,
    "Full Color": 45,
    "User Created": 46,
    "Official Colored": 47,
    "Fan Colored": 48,
    "Gore": 49,
    "Sexual Violence": 50,
    "Crime": 51,
    "Magical Girls": 52,
    "Philosophical": 53,
    "Superhero": 54,
    "Thriller": 55,
    "Wuxia": 56,
    "Aliens": 57,
    "Animals": 58,
    "Crossdressing": 59,
    "Demons": 60,
    "Delinquents": 61,
    "Genderswap": 62,
    "Ghosts": 63,
    "Monster Girls": 64,
    "Loli": 65,
    "Magic": 66,
    "Military": 67,
    "Monsters": 68,
    "Ninja": 69,
    "Office Workers": 70,
    "Police": 71,
    "Post-Apocalyptic": 72,
    "Reincarnation": 73,
    "Reverse Harem": 74,
    "Samurai": 75,
    "Shota": 76,
    "Survival": 77,
    "Time Travel": 78,
    "Vampires": 79,
    "Traditional Games": 80,
    "Virtual Reality": 81,
    "Zombies": 82,
    "Incest": 83,
    "Mafia": 84
  };

  static const Map<String, String> TAG_MODES = {
    "All": "all",
    "Any": "any"
  };

  MangaDexSource() : super("MangaDex", SearchDefinition(
      fields: [
        "Title",
        "Author",
        "Artist"
      ],
      filters: [
        SearchFilter(
            name: "Demographics",
            multiChoice: true,
            choices: DEMOGRAPHICS.keys.toList(),
            defaultOn: DEMOGRAPHICS.keys.toList()
        ),
        SearchFilter(
            name: "Publication Status",
            multiChoice: true,
            choices: PUBLICATION_STATUS.keys.toList(),
            defaultOn: PUBLICATION_STATUS.keys.toList()
        ),
        SearchFilter(
            name: "Include Tags",
            multiChoice: true,
            choices: TAGS.keys.toList(),
            defaultOn: []
        ),
        SearchFilter(
            name: "Exclude Tags",
            multiChoice: true,
            choices: TAGS.keys.toList(),
            defaultOn: []
        ),
        SearchFilter(
            name: "Tag Inclusion Mode",
            multiChoice: false,
            choices: TAG_MODES.keys.toList(),
            defaultOn: ["All"]
        ),
        SearchFilter(
            name: "Tag Exclusion Mode",
            multiChoice: false,
            choices: TAG_MODES.keys.toList(),
            defaultOn: ["Any"]
        )
      ]
  ));

  @override
  Future<void> login(String username, String password) async {
    var request = http.MultipartRequest('POST', Uri.parse(_LOGIN_ENDPOINT))
      ..fields['login_username'] = username
      ..fields['login_password'] = password
      ..fields['remember_me'] = '1';
    request.headers['referer'] = _LOGIN_PAGE;
    request.headers['Access-Control-Allow-Origin'] = '*';
    request.headers['User-Agent'] = 'J-Reader';
    request.headers['X-Requested-With'] = 'XMLHttpRequest';

    return post(request).then((_) {
      setAuthField("username", username);
    });
  }

  @override
  Future<void> logout() async {
    if(isLoggedIn()) {
      var request = http.Request('POST', Uri.parse(_LOGOUT_ENDPOINT));
      request.headers['referer'] = _LOGOUT_PAGE;
      request.headers['Access-Control-Allow-Origin'] = '*';
      request.headers['User-Agent'] = 'J-Reader';
      request.headers['X-Requested-With'] = 'XMLHttpRequest';

      return post(request).then((_) {
        clearAuthFields();
      });
    }
  }

  @override
  bool isLoggedIn() {
    return getAuthField("username") != null
        && getAuthField("session") != null
        && getAuthField("token") != null;
  }

  @override
  String getUsername() {
    return getAuthField("username");
  }

  @override
  Future<List<String>> getUserInfo() async {
    return [];
  }

  @override
  Future<List<Content>> listSeries({int page = 0}) async {
    return get(sprintf(_POPULAR_MANGA_URL, [page + 1])).then((value) {
      return parseSeriesList(value);
    });
  }

  @override
  Future<Content> getSeries(String id) async {
    return get(sprintf(_GET_MANGA_ENDPOINT, [id])).then((value) {
      return MangaDexSeries(this, id, json.decode(value));
    });
  }

  @override
  Future<List<Content>> searchSeries(Map<String, String> fields, Map<String, Map<String, bool>> filters, {int page = 0}) async {
    String tags = compileFilterParam(filters["Include Tags"], TAGS);
    String negativeTags = compileFilterParam(filters["Exclude Tags"], TAGS, negate: true);
    if(tags.isNotEmpty && negativeTags.isNotEmpty) {
      tags += ",";
    }

    tags += negativeTags;

    final params = {
      "p": (page + 1).toString(),
      "title": fields["Title"],
      "author": fields["Author"],
      "artist": fields["Artist"],
      "demos": filters["Demographics"].length != 4 ? compileFilterParam(filters["Demographics"], DEMOGRAPHICS) : "",
      "statuses": filters["Publication Status"].length != 4 ? compileFilterParam(filters["Publication Status"], PUBLICATION_STATUS) : "",
      "tag_mode_exc": tags.isNotEmpty ? compileFilterParam(filters["Tag Exclusion Mode"], TAG_MODES) : "",
      "tag_mode_inc": tags.isNotEmpty ? compileFilterParam(filters["Tag Inclusion Mode"], TAG_MODES) : "",
      "tags": tags
    };

    StringBuffer paramString = new StringBuffer();
    for(final param in params.entries) {
      if(param.value.isNotEmpty) {
        if(paramString.isNotEmpty) {
          paramString.write("&");
        }

        paramString.write("${param.key}=${param.value}");
      }
    }

    return get(sprintf(_SEARCH_URL, [paramString.toString()])).then((value) {
      return parseSeriesList(value);
    });
  }

  String compileFilterParam(Map<String, bool> filter, Map<String, dynamic> ids, {bool negate = false}) {
    StringBuffer result = new StringBuffer();
    for(final entry in filter.entries) {
      if(entry.value) {
        if(result.isNotEmpty) {
          result.write(",");
        }

        if(negate) {
          result.write("-");
        }

        result.write(ids[entry.key].toString());
      }
    }

    return result.toString();
  }

  List<Content> parseSeriesList(String body) {
    final result = new List<Content>();

    final doc = parse(body);
    for(final entry in doc.getElementsByClassName("manga-entry")) {
      final id = entry.attributes["data-id"];

      final coverUrl = sprintf(_COVER_URL, [entry.getElementsByClassName("large_logo")[0]
          .getElementsByTagName("img")[0]
          .attributes["src"]]);
      final title = entry.getElementsByClassName("manga_title")[0].text;

      String description = "";
      for(final child in entry.getElementsByTagName("div")) {
        if(child.attributes["style"] == "height: 210px; overflow: hidden;") {
          description = child.text;
          break;
        }
      }

      result.add(MangaDexSeries.fromDetails(this, id, title, description, coverUrl));
    }

    return result;
  }

  @override
  Future<List<Event>> listEvents() async {
    // TODO: Implement listEvents.
    throw UnimplementedError();
  }

  Future<String> get(String url) async {
    return http.get(Uri.encodeFull(url), headers: {"Cookie": getCookies()}).then((response) {
      if(response.statusCode == 200) {
        handleCookies(response);
        return response.body;
      } else {
        throw new Exception("Failed to fetch data: Request returned status code ${response.statusCode}");
      }
    });
  }

  Future<http.StreamedResponse> post(http.BaseRequest request) async {
    request.headers["Cookie"] = getCookies();

    return request.send().then((response) {
      if(response.statusCode == 200) {
        handleCookies(response);
        return response;
      } else {
        throw new Exception("Failed to fetch data: Request returned status code ${response.statusCode}");
      }
    });
  }

  String getCookies() {
    return isLoggedIn() ? "$_SESSION_COOKIE_NAME=${getAuthField("session")}; $_TOKEN_COOKIE_NAME=${getAuthField("token")}" : "";
  }
  
  void handleCookies(http.BaseResponse response) {
    if(response.statusCode == 200) {
      final cookies = response.headers["set-cookie"];
      if(cookies != null) {
        if(cookies.contains(_SESSION_COOKIE_NAME)) {
          final sessionPos = cookies.indexOf(_SESSION_COOKIE_NAME) + _SESSION_COOKIE_NAME.length + 1;
          setAuthField("session", cookies.substring(sessionPos, cookies.indexOf(";", sessionPos)));
        }

        if(cookies.contains(_TOKEN_COOKIE_NAME)) {
          final tokenPos = cookies.indexOf(_TOKEN_COOKIE_NAME) + _TOKEN_COOKIE_NAME.length + 1;
          setAuthField("token", cookies.substring(tokenPos, cookies.indexOf(";", tokenPos)));
        }
      }
    }
  }

  static String _cleanString(String s) {
    return new HtmlUnescape().convert(s).replaceAll(new RegExp(r"\[[^\]]+\]"), "");
  }
}

class MangaDexSeries extends Content<Content> {
  Map<String, dynamic> _json;

  MangaDexSeries(Source source, String id, this._json) : super(source, _createMeta(id, _json));

  MangaDexSeries.fromDetails(Source source, String id, String title, String description, String coverUrl) : super(source, Metadata(
      type: ContentType.SERIES,
      id: id,
      title: MangaDexSource._cleanString(title),
      author: "",
      description: MangaDexSource._cleanString(description),
      date: DateTime.fromMillisecondsSinceEpoch(0),
      coverUrl: coverUrl,
      leafs: {}
  ));

  @override
  bool isFilled() {
    return _json != null && children != null;
  }

  @override
  Future<void> fill() async {
    Future<void> jsonFuture = Future.value();
    bool refreshJson = _json == null || !_json.containsKey("chapter");
    if(refreshJson) {
      jsonFuture = (source as MangaDexSource).get(sprintf(MangaDexSource._GET_MANGA_ENDPOINT, [meta.id])).then((value) {
        _json = json.decode(value);
        meta = _createMeta(meta.id, _json);
      });
    }

    if(children == null || refreshJson) {
      return jsonFuture.then((_) {
        final built = new List<Content>();
        for(final entry in _json["chapter"].entries) {
          if(entry.value["lang_code"] == "gb") {
            built.add(MangaDexChapter(source, entry.key, entry.value));
          }
        }

        children = built;
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

  static Metadata _createMeta(String id, Map<String, dynamic> json) {
    final leafs = new Map<String, DateTime>();
    if(json.containsKey("chapter")) {
      for(final entry in json["chapter"].entries) {
        if(entry.value["lang_code"] == "gb") {
          leafs[entry.key] = entry.value.containsKey("timestamp")
              ? DateTime.fromMillisecondsSinceEpoch(entry.value["timestamp"] * 1000)
              : DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
    }

    return Metadata(
        type: ContentType.SERIES,
        id: id,
        title: MangaDexSource._cleanString(json["manga"]['title']),
        author: MangaDexSource._cleanString(json["manga"]['author']),
        description: MangaDexSource._cleanString(json["manga"]['description']),
        date: DateTime.fromMillisecondsSinceEpoch(0),
        coverUrl: sprintf(MangaDexSource._COVER_URL, [json["manga"]['cover_url']]),
        leafs: leafs
    );
  }
}

class MangaDexChapter extends Content<String> {
  Map<String, dynamic> _json;

  MangaDexChapter(Source source, String id, this._json) : super(source, _createMeta(id, _json));

  @override
  bool isFilled() {
    return _json != null && children != null;
  }

  @override
  Future<void> fill() async {
    Future<void> jsonFuture = Future.value();
    bool refreshJson = _json == null || !_json.containsKey("page_array");
    if(refreshJson) {
      jsonFuture = (source as MangaDexSource).get(sprintf(MangaDexSource._GET_CHAPTER_ENDPOINT, [meta.id])).then((value) {
        _json = json.decode(value);
        meta = _createMeta(meta.id, _json);
      });
    }

    if(children == null || refreshJson) {
      return jsonFuture.then((_) {
        String base = _json["server"];
        if(base == "/") {
          base = MangaDexSource._DEFAULT_PAGE_SERVER;
        }

        final built = new List<String>();
        String hash = _json["hash"];
        for(final pageFile in _json["page_array"]) {
          built.add("$base$hash/$pageFile");
        }

        children = built;
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

  static Metadata _createMeta(String id, Map<String, dynamic> json) {
    return Metadata(
        type: _isLongStrip(json) ? ContentType.MANGA_PART_LONGSTRIP : ContentType.MANGA_PART,
        id: id,
        title: MangaDexSource._cleanString(_getTitle(json)),
        author: MangaDexSource._cleanString(json["group_name"]),
        description: "",
        date: json.containsKey("timestamp")
            ? DateTime.fromMillisecondsSinceEpoch(json["timestamp"] * 1000)
            : DateTime.fromMillisecondsSinceEpoch(0),
        coverUrl: null,
        leafs: {id: json.containsKey("timestamp")
            ? DateTime.fromMillisecondsSinceEpoch(json["timestamp"] * 1000)
            : DateTime.fromMillisecondsSinceEpoch(0)}
    );
  }

  static bool _isLongStrip(Map<String, dynamic> json) {
    return json.containsKey("long_strip") && (json["long_strip"] == 1 || json["long_strip"] == true);
  }

  static String _getTitle(Map<String, dynamic> json) {
    var buffer = new StringBuffer();
    if(json.containsKey("volume") && (json["volume"] as String).isNotEmpty) {
      buffer.write("Volume ${json["volume"]}");
    }

    if(json.containsKey("chapter") && (json["chapter"] as String).isNotEmpty) {
      if(buffer.isNotEmpty) {
        buffer.write(" ");
      }

      buffer.write("Chapter ${json["chapter"]}");
    }

    if(json.containsKey("title") && (json["title"] as String).isNotEmpty) {
      if(buffer.isNotEmpty) {
        buffer.write(": ");
      }

      buffer.write(json["title"]);
    }

    return buffer.toString();
  }
}