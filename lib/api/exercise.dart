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
import 'package:kosmos_client/api/exercise_attachment.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:kosmos_client/database_provider.dart';

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

  late MaterialColor color;
  String subject;
  String title;
  String htmlContent;
  bool done;
  List<ExerciseAttachment> attachments;

  Exercise(
    this.uid,
    this.parentLesson,
    this.type,
    this.date,
    this.title,
    this.htmlContent,
    this.done,
    this.attachments,
    this.subject, [
    this.lessonFor,
    this.dateFor,
  ]) {
    color = ColorProvider.getColor(subject);
  }

  /// Construct an [Exercise] from the result of a database query
  static Future<Exercise> parse(Map<String, Object?> result) async {
    return Exercise(
        result['ExerciseID'] as int? ?? result['ID'] as int,
        result['ParentLesson'] as int?,
        result['Type'] as String == 'Cours' ? ExerciseType.lessonContent : ExerciseType.exercise,
        DateTime.fromMillisecondsSinceEpoch(result['ParentDate'] as int),
        result['Title'] as String,
        result['HTMLContent'] as String,
        result['Done'] == 1,
        [],
        result['ExerciseSubject'] as String? ??
            result['Subject'] as String? ??
            //This should never be called, it just exists as a backup solution in case the migration goes wrong.
            (await Lesson.byID(result['ParentLesson'] as int? ?? result['LessonFor'] as int))
                ?.title ??
            'Erreur',
        result['LessonFor'] as int?,
        (result['DateFor'] as int?) == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(result['DateFor'] as int));
  }

  /// Get all [Exercise]s

  static Future<List<Exercise>> fetchAll() async {
    final List<Exercise> exercises = [];
    final results = await (await DatabaseProvider.getDB()).rawQuery('''SELECT 
          Exercises.ID as ExerciseID,
          ExerciseAttachments.ID AS ExerciseAttachmentID,
          * FROM Exercises 
          LEFT JOIN ExerciseAttachments ON Exercises.ID = ExerciseAttachments.ParentID
          WHERE Exercises.StudentUID = '${Client.currentlySelected!.uid}'
          AND (ExerciseAttachments.StudentUID = '${Client.currentlySelected!.uid}' OR ExerciseAttachments.StudentUID IS Null);''');
    Exercise? exercise;
    for (final result in results) {
      if (exercise == null || result['ExerciseID'] != exercise.uid) {
        exercise = await parse(result);
        exercises.add(exercise);
      }
      if (result['ExerciseAttachmentID'] != null) {
        exercise.attachments.add(ExerciseAttachment.parse(result));
      }
    }
    return exercises;
  }
}
