import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jreader/source/source.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class Persistence {
  static Map<String, Map<String, MyListEntry>> _myList = new HashMap<String, Map<String, MyListEntry>>();
  static Map<String, Map<String, Progress>> _progress = new HashMap<String, Map<String, Progress>>();
  static Map<String, Map<String, String>> _authFields = new HashMap<String, Map<String, String>>();
  static Map<String, Map<String, int>> _sortingModes = new HashMap<String, Map<String, int>>();
  static Map<String, Map<String, int>> _sortingDirs = new HashMap<String, Map<String, int>>();

  static FlutterSecureStorage _secureStorage = new FlutterSecureStorage();

  static Future<void> load() async {
    if(kIsWeb) {
      if(html.window.localStorage.containsKey('persist')) {
        loadData(html.window.localStorage['persist']);
      }

      if(html.window.localStorage.containsKey('auth')) {
        loadAuth(html.window.localStorage['auth']);
      }

      return;
    }

    return _getDirectory().then((directory) {
      final file = File('${directory.path}/persistence.json');
      return file.exists().then((exists) {
        if(exists) {
          return file.readAsString().then((contents) {
            loadData(contents);

            return _secureStorage.read(key: "jreader.authFields").then((value) {
              if(value != null) {
                loadAuth(value);
              }
            });
          });
        } else {
          return null;
        }
      });
    });
  }

  static void loadData(String contents) {
    final data = json.decode(contents) as Map;

    if(data.containsKey('myList')) {
      _myList = (data['myList'] as Map)?.map((key, value) =>
          MapEntry(key, (value as Map)?.map((key, value) =>
              MapEntry(key, MyListEntry.fromJson(value)))));
    }


    if(data.containsKey('progress')) {
      _progress = (data['progress'] as Map)?.map((key, value) =>
          MapEntry(key, (value as Map)?.map((key, value) =>
              MapEntry(key, Progress.fromJson(value)))));
    }

    if(data.containsKey('sortingModes')) {
      _sortingModes = (data['sortingModes'] as Map).map((key, value) =>
          MapEntry(key, (value as Map)?.map((key, value) =>
              MapEntry(key, value as int))));
    }

    if(data.containsKey('sortingDirs')) {
      _sortingDirs = (data['sortingDirs'] as Map).map((key, value) =>
          MapEntry(key, (value as Map)?.map((key, value) =>
              MapEntry(key, value as int))));
    }
  }

  static void loadAuth(String contents) {
    _authFields = ((json.decode(contents) as Map)?.map((key, value) =>
        MapEntry(key, (value as Map)?.map((key, value) =>
            MapEntry(key, value as String)))));
  }

  static Future<void> save() async {
    if(kIsWeb) {
      html.window.localStorage['persist'] = saveData();
      html.window.localStorage['auth'] = saveAuth();
      return;
    }

    return _getDirectory().then((directory) {
      final file = File('${directory.path}/persistence.json');
      return file.writeAsString(saveData()).then((_) {
        return _secureStorage.write(key: "jreader.authFields", value: saveAuth());
      });
    });
  }

  static String saveData() {
    return json.encode({
      'myList': _myList?.map((key, value) =>
          MapEntry(key, value.map((key, value) =>
              MapEntry(key, value.toJson())))),
      'progress': _progress?.map((key, value) =>
          MapEntry(key, value.map((key, value) =>
              MapEntry(key, value.toJson())))),
      'sortingModes': _sortingModes,
      'sortingDirs': _sortingDirs
    });
  }

  static String saveAuth() {
    return json.encode(_authFields);
  }

  static Future<Directory> _getDirectory() {
    return getExternalStorageDirectory().catchError((e) {
      return getApplicationDocumentsDirectory();
    });
  }

  static Map<String, MyListEntry> getMyList(String source) {
    if(!_myList.containsKey(source)) {
      _myList[source] = new HashMap<String, MyListEntry>();
    }

    return _myList[source];
  }

  static Map<String, Progress> getProgress(String source) {
    if(!_progress.containsKey(source)) {
      _progress[source] = new HashMap<String, Progress>();
    }

    return _progress[source];
  }

  static int getUnreadParts(String source, Metadata meta) {
    final progress = getProgress(source);

    int unread = 0;
    meta.leafs.keys.forEach((element) {
      if(!progress.containsKey(element) || !progress[element].read) {
        unread++;
      }
    });

    return unread;
  }

  static Map<String, String> getAuthFields(String source) {
    if(!_authFields.containsKey(source)) {
      _authFields[source] = new HashMap<String, String>();
    }

    return _authFields[source];
  }

  static Map<String, int> getSortingModes(String source) {
    if(!_sortingModes.containsKey(source)) {
      _sortingModes[source] = new HashMap<String, int>();
    }

    return _sortingModes[source];
  }

  static Map<String, int> getSortingDirs(String source) {
    if(!_sortingDirs.containsKey(source)) {
      _sortingDirs[source] = new HashMap<String, int>();
    }

    return _sortingDirs[source];
  }

  static void sortMeta(String source, String page, List entries, Function getMeta) {
    final sortingMode = getSortingModes(source)["myList"] ?? 0;
    final sortingDir = getSortingDirs(source)["myList"] ?? 0;

    entries.sort((a, b) {
      final metaA = getMeta(a);
      final metaB = getMeta(b);

      int result = 0;
      switch(sortingMode) {
        case 0:
          result = metaA.title.compareTo(metaB.title);
          break;
        case 1:
          result = _getLatestDate(metaA).compareTo(_getLatestDate(metaB));
          break;
        case 2:
          result = getUnreadParts(source, metaA).compareTo(getUnreadParts(source, metaB));
          break;
      }

      if(sortingDir == 1) {
        result = -result;
      }

      return result;
    });
  }

  static DateTime _getLatestDate(Metadata meta) {
    DateTime latest = meta.date;
    for(final leafDate in meta.leafs.values) {
      if(leafDate.isAfter(latest)) {
        latest = leafDate;
      }
    }

    return latest;
  }
}

class MyListEntry {
  Metadata meta;

  MyListEntry({this.meta});

  factory MyListEntry.fromJson(Map<String, dynamic> json) {
    if(json == null) {
      return null;
    }

    return MyListEntry(
        meta: Metadata.fromJson(json['meta'])
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'meta': meta.toJson()
      };
}

class Progress {
  double offset;
  bool read;

  Progress({this.offset, this.read});

  factory Progress.fromJson(Map<String, dynamic> json) {
    if(json == null) {
      return null;
    }

    return Progress(
      offset: json['offset'],
      read: json['read']
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'offset': offset,
        'read': read
      };
}