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

import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/exercise_attachment.dart';
import 'package:kosmos_client/database_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

enum ExerciseType {
  lessonContent,
  exercise,
}

/// What is called Exercise here can be either
///  - Exercises given for a lesson
///  - The content of a specific lesson
class Exercise {
  int uid;

  /// The ID of the [Lesson] that
  ///  - The exercise was given on (if type == [ExerciseType.exercise])
  ///  - The lesson content refers to (if type == [ExerciseType.lessonContent])
  ///     Is null if the lesson is outside of the range provided by the API
  ///     (+7 and -7 Days)
  int? parentLesson;

  /// The ID of the [Lesson] that the exercise is due for (if type == [ExerciseType.exercise])
  /// It is null if
  ///  - type == [ExerciseType.lessonContent]
  ///  - The lesson is outside of the range provided by the API (+7 and -7 Days)
  int? lessonFor;
  ExerciseType type;

  /// The Date that
  ///  - The exercise was given on (if type == [ExerciseType.exercise])
  ///  - The lesson content refers to (if type == [ExerciseType.lessonContent])
  /// It is useful if the lesson is outside of the range provided by the API
  /// (+7 and -7 Days)
  DateTime date;

  /// The Date that the exercise was is due for (if type == [ExerciseType.exercise])
  /// Is null if type == [ExerciseType.lessonContent]
  /// It is useful if the lesson is outside of the range provided by the API
  /// (+7 and -7 Days)
  DateTime? dateFor;
  String title;
  String htmlContent;
  bool done;
  List<ExerciseAttachment> attachments;

  Exercise(this.uid, this.parentLesson, this.type, this.date, this.title, this.htmlContent,
      this.done, this.attachments,
      [this.lessonFor, this.dateFor]);

  /// Construct an [Exercise] from the result of a database query
  static Future<Exercise> _parse(Map<String, Object?> result) async {
    return Exercise(
        result['ID'] as int,
        result['ParentLesson'] as int?,
        result['Type'] as String == 'Cours' ? ExerciseType.lessonContent : ExerciseType.exercise,
        DateTime.fromMillisecondsSinceEpoch(result['ParentDate'] as int),
        result['Title'] as String,
        result['HTMLContent'] as String,
        result['Done'] == 1,
        await ExerciseAttachment.fromParentID(result['ID'] as int),
        result['LessonFor'] as int?,
        (result['DateFor'] as int?) == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(result['DateFor'] as int));
  }

  /// Get the [Exercise]s by the parent [Lesson] ID
  static Future<List<Exercise>> fromParentLesson(int parentLesson, Database db) async {
    final List<Exercise> exercises = [];
    final results = await db.query('Exercises',
        where: 'ParentLesson = ? OR LessonFor = ?',
        whereArgs: [parentLesson.toString(), parentLesson.toString()]);
    for (final result in results) {
      exercises.add(await _parse(result));
    }
    return exercises;
  }

  /// Get all [Exercise]s
  static Future<List<Exercise>> fetchAll() async {
    final List<Exercise> exercises = [];
    final results = await (await DatabaseProvider.getDB())
        .query('Exercises', where: 'StudentUID = ?', whereArgs: [Client.currentlySelected!.uid]);
    for (final result in results) {
      exercises.add(await _parse(result));
    }
    return exercises;
  }
}
