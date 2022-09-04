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

import '../global.dart';

class Grade {
  String subject;
  num grade;
  num of;
  DateTime date;

  Grade(
    this.subject,
    this.grade,
    this.of,
    this.date,
  );

  static Future<List<Grade>> fetchAll() async {
    final List<Grade> grades = [];
    final results = await Global.db!.query('Grades');
    for (final result in results) {
      grades.add(Grade(
        result['Subject'] as String,
        result['Grade'] as num,
        result['Of'] as num,
        DateTime.fromMillisecondsSinceEpoch(result['Date'] as int),
      ));
    }
    return grades;
  }
}
