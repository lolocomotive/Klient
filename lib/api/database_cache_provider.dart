import 'package:flutter/foundation.dart';
import 'package:klient/database_provider.dart';
import 'package:scolengo_api/scolengo_api.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseCacheProvider extends CacheProvider {
  bool ready = false;
  late Map<String, String> _index;
  late Database _db;

  init() async {
    final stopwatch = Stopwatch()..start();
    _db = await DatabaseProvider.getDB();
    final results = await _db.query('Cache', columns: ['Uri', 'DateTime']);
    _index = {};
    for (final result in results) {
      _index[result['Uri'] as String] = result['DateTime'] as String;
    }
    ready = true;
    if (kDebugMode) {
      print('Database cache provider init done in ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  @override
  Future<String> get(String key) async {
    if (!ready) throw Exception('Database not ready!');
    final results = await _db.query('Cache', columns: ['Data'], where: 'Uri = ?', whereArgs: [key]);
    if (results.isEmpty) throw Exception('Key not found!');
    if (kDebugMode) print('CACHE GET $key');
    return results.first['Data'] as String;
  }

  @override
  bool raw() => false;

  @override
  void set(String key, String value) {
    if (!ready) throw Exception('Database not ready!');
    final stopwatch = Stopwatch()..start();
    _db.insert(
      'Cache',
      {'Uri': key, 'Data': value, 'DateTime': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _index[key] = DateTime.now().toIso8601String();
    if (kDebugMode) print('CACHE SET $key took ${stopwatch.elapsedMilliseconds}ms');
  }

  @override
  Future<bool> shouldUseCache(String key) async {
    if (!ready) throw Exception('Database not ready!');
    if (_index.containsKey(key)) return true;
    return false;
  }
}
