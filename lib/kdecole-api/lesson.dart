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

import 'package:kosmos_client/kdecole-api/exercise.dart';
import 'package:sqflite/sqflite.dart';

class Lesson {
  int id;
  DateTime date;
  /// Start time of the lesson formatted  HH:MM
  String startTime;
  /// End time of the lesson formatted HH:MM
  String endTime;
  /// Contains the room and also the group (304 - 1ALLG1 for example)
  String room;
  String title;
  List<Exercise> exercises;
  bool isModified;
  String? modificationMessage;

  Lesson(this.id, this.date, this.startTime, this.endTime, this.room,
      this.title, this.exercises, this.isModified,
      [this.modificationMessage]);

  static Future<List<Lesson>> fetchAll(Database db) async {
    final List<Lesson> lessons = [];
    final results = await db.query('Lessons');
    for (final result in results) {
      lessons.add(Lesson(
          result['ID'] as int,
          DateTime.fromMillisecondsSinceEpoch((result['date'] as int)),
          result['startTime'] as String,
          result['EndTime'] as String,
          result['Room'] as String,
          result['Title'] as String,
          await Exercise.fromParentLesson(result['ID'] as int, db),
          result['IsModified'] as bool,
          result['ModificationMessage'] as String?));
    }
    return lessons;
  }
}
