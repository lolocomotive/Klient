/*
 * This file is part of the Klient (https://github.com/lolocomotive/klient)
 *
 * Copyright (C) 2022 lolocomotive
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/foundation.dart';
import 'package:klient/database_provider.dart';
import 'package:scolengo_api/scolengo_api.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseCacheProvider extends CacheProvider {
  bool ready = false;
  late Map<String, String> _index;

  init() async {
    final stopwatch = Stopwatch()..start();
    final db = await DatabaseProvider.getDB();
    final results = await db.query('Cache', columns: ['Uri', 'DateTime']);
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
    final results = await (await DatabaseProvider.getDB())
        .query('Cache', columns: ['Data'], where: 'Uri = ?', whereArgs: [key]);
    if (results.isEmpty) throw Exception('Key not found!');
    if (kDebugMode) print('CACHE GET $key');
    return results.first['Data'] as String;
  }

  @override
  bool raw() => false;

  @override
  void set(String key, String value) async {
    if (!ready) throw Exception('Database not ready!');
    final stopwatch = Stopwatch()..start();
    (await DatabaseProvider.getDB()).insert(
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
