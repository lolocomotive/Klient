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

import 'package:flutter/material.dart';
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/color_provider.dart';
import 'package:kosmos_client/api/exercise.dart';
import 'package:kosmos_client/api/exercise_attachment.dart';
import 'package:kosmos_client/database_provider.dart';

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
  bool shouldNotify;
  String? modificationMessage;

  bool isCanceled;

  ///1 = 1 hour
  late double length;
  late double startDouble;
  late MaterialColor color;

  Lesson(this.id, this.date, this.startTime, this.endTime, this.room, this.title, this.exercises,
      this.isModified, this.isCanceled, this.shouldNotify, bool headless,
      [this.modificationMessage]) {
    startDouble = int.parse(startTime.substring(0, 2)) + int.parse(startTime.substring(3)) / 60;
    final e = int.parse(endTime.substring(0, 2)) + int.parse(endTime.substring(3)) / 60;

    length = e - startDouble;
    if (headless) {
      color = Colors.blue;
    } else {
      color = ColorProvider.getColor(title);
    }
  }

  static Lesson _parse(result, bool headless) {
    return Lesson(
      result['ID'] as int? ?? result['LessonID'] as int,
      DateTime.fromMillisecondsSinceEpoch((result['LessonDate'] as int)),
      result['StartTime'] as String,
      result['EndTime'] as String,
      result['Room'] as String,
      result['Subject'] as String,
      [],
      result['IsModified'] as int == 1,
      result['IsCanceled'] as int == 1,
      result['ShouldNotify'] as int == 1,
      headless,
      result['ModificationMessage'] as String?,
    );
  }

  static Future<List<Lesson>> fetchAll([headless = false]) async {
    final List<Lesson> lessons = [];
    final results = await (await DatabaseProvider.getDB()).rawQuery('''SELECT 
          Lessons.ID as LessonID,
          Exercises.ID as ExerciseID,
          ExerciseAttachments.ID AS ExerciseAttachmentID,
          * FROM Lessons 
          LEFT JOIN Exercises ON Lessons.ID = Exercises.ParentLesson OR Lessons.ID = Exercises.LessonFor
          LEFT JOIN ExerciseAttachments ON Exercises.ID = ExerciseAttachments.ParentID
          WHERE Lessons.StudentUID = ${Client.currentlySelected!.uid} 
          AND (Exercises.StudentUID = ${Client.currentlySelected!.uid} OR  Exercises.StudentUID IS Null)
          AND (ExerciseAttachments.StudentUID = ${Client.currentlySelected!.uid} OR ExerciseAttachments.StudentUID IS Null)
          ORDER BY LessonDate;''');
    Lesson? lesson;
    Exercise? exercise;
    for (final result in results) {
      if (lesson == null || result['LessonID'] != lesson.id) {
        lesson = _parse(result, headless);
        lessons.add(lesson);
      }
      if (result['ExerciseID'] != null) {
        if (exercise == null || result['ExerciseID'] != exercise.uid) {
          exercise = Exercise.parse(result);
        }
        if (result['ExerciseAttachmentID'] != null) {
          exercise.attachments.add(ExerciseAttachment.parse(result));
        }
        lesson.exercises.add(exercise);
      }
    }

    return lessons;
  }

  @Deprecated('Use joins instead')
  static Future<Lesson?> byID(int id, [headless = false]) async {
    final results =
        await (await DatabaseProvider.getDB()).query('Lessons', where: 'ID = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return _parse(results[0], headless);
  }
}
