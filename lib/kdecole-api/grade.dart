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

import 'package:sqflite/sqflite.dart';

class Grade {
  String subject;
  String prof;
  String grade;
  String description;

  Grade(this.subject, this.prof, this.grade, this.description);

  static Future<List<Grade>> fetchAll(Database db) async {
    final List<Grade> grades = [];
    final results = await db.query('Grades');
    for (final result in results) {
      grades.add(Grade(result['Subject'] as String, result['Prof'] as String,
          result['Grade'] as String, result['Description'] as String));
    }
    return grades;
  }
}
