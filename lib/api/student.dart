/*
 * This file is part of the Kosmos Client (https://github.com/lolocomotive/kosmos_client)
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

import 'package:kosmos_client/database_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class Student {
  String uid;
  String name;
  String permissions;

  Student(
    this.uid,
    this.name,
    this.permissions,
  );

  static Future<List<Student>> fetchAll({Database? db}) async {
    db = db ?? await DatabaseProvider.getDB();
    final List<Student> articles = [];
    final results = await db.query('Students');
    for (final result in results) {
      articles.add(Student(
        result['UID'] as String,
        result['Name'] as String,
        result['Permissions'] as String,
      ));
    }
    return articles;
  }
}
