import 'dart:collection';

import 'package:jreader/support/persist.dart';
import 'package:jreader/source/jnovelclub.dart';
import 'package:jreader/source/mangadex.dart';

class Sources {
  static final Map<String, Source> _REGISTERED = {
    "J-Novel Club": new JNovelClubSource(),
    "MangaDex": new MangaDexSource()
  };

  static List<Source> all() {
    return _REGISTERED.values.toList();
  }

  static Source get(String name) {
    return _REGISTERED[name];
  }
}

abstract class Source {
  final String name;
  final SearchDefinition searchDefinition;

  Source(this.name, this.searchDefinition);

  String getAuthField(String key) {
    return Persistence.getAuthFields(name)[key];
  }

  void setAuthField(String key, String value) {
    Persistence.getAuthFields(name)[key] = value;
    Persistence.save();
  }

  void clearAuthFields() {
    Persistence.getAuthFields(name).clear();
    Persistence.save();
  }

  bool isLoggedIn();

  String getUsername();

  Future<List<String>> getUserInfo();

  Future<void> login(String username, String password);

  Future<void> logout();

  Future<List<Content>> listSeries({int page = 0});

  Future<Content> getSeries(String id);

  Future<List<Content>> searchSeries(Map<String, String> fields, Map<String, Map<String, bool>> filters, {int page = 0});

  Future<List<Event>> listEvents();
}

abstract class Content<T> {
  final Source source;

  Metadata meta;
  List<T> children;

  Content(this.source, this.meta);

  bool isFilled();

  Future<void> fill();

  Future<PurchaseStatus> getPurchaseStatus();

  Future<void> purchase();
}

class Metadata {
  final ContentType type;
  final String id;
  final String title;
  final String author;
  final String description;
  final DateTime date;
  final String coverUrl;
  final Map<String, DateTime> leafs;

  Metadata({this.type, this.id, this.title, this.author, this.description, this.date, this.coverUrl, this.leafs});

  factory Metadata.fromJson(Map<String, dynamic> json) {
    if(json == null) {
      return null;
    }

    ContentType type;
    for(final t in ContentType.values) {
      if(json['type'] == t.toString()) {
        type = t;
        break;
      }
    }

    Map<String, DateTime> leafs;
    if(json.containsKey('leafIds')) {
      leafs = new HashMap<String, DateTime>();
      for(final leafId in json['leafIds']) {
        leafs[leafId] = DateTime.fromMillisecondsSinceEpoch(0);
      }
    } else {
      leafs = (json['leafs'] as Map).map((key, value) => MapEntry(key as String, DateTime.parse(value as String)));
    }

    return Metadata(
        type: type,
        id: json['id'],
        title: json['title'],
        author: json['author'],
        description: json['description'],
        date: DateTime.parse(json['date']),
        coverUrl: json['coverUrl'],
        leafs: leafs
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'type': type.toString(),
        'id': id,
        'title': title,
        'author': author,
        'description': description,
        'date': date.toIso8601String(),
        'coverUrl': coverUrl,
        'leafs': leafs.map((key, value) => MapEntry(key, value.toIso8601String()))
      };
}

enum ContentType {
  SERIES,
  VOLUME,
  NOVEL_PART,
  MANGA_PART,
  MANGA_PART_LONGSTRIP
}

enum PurchaseStatus {
  NOT_SUPPORTED,
  NOT_LOGGED_IN,
  PURCHASED,
  NOT_AVAILABLE,
  NOT_ENOUGH_CREDITS,
  CAN_PURCHASE
}

const Map<PurchaseStatus, String> PURCHASE_STATUS_TEXT = {
  PurchaseStatus.NOT_SUPPORTED: "Not supported",
  PurchaseStatus.NOT_LOGGED_IN: "Not logged in",
  PurchaseStatus.PURCHASED: "Purchased",
  PurchaseStatus.NOT_AVAILABLE: "Not available for purchase",
  PurchaseStatus.NOT_ENOUGH_CREDITS: "Not enough credits",
  PurchaseStatus.CAN_PURCHASE: "Purchase"
};

abstract class Event {
  final String name;
  final String details;
  final DateTime date;
  final String coverUrl;

  Event({this.name, this.details, this.date, this.coverUrl});

  Future<Content> getContent();
}

class SearchDefinition {
  final List<String> fields;
  final List<SearchFilter> filters;

  SearchDefinition({this.fields, this.filters});
}

class SearchFilter {
  final String name;
  final bool multiChoice;
  final List<String> choices;
  final List<String> defaultOn;

  SearchFilter({this.name, this.multiChoice, this.choices, this.defaultOn});
}
