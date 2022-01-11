import 'package:sqflite/sqflite.dart';

enum ExerciseType {
  lessonContent,
  workToDo,
}

class Exercise {
  int uid;
  int parentLesson;
  int? lessonFor;
  ExerciseType type;
  DateTime date;
  DateTime? dateFor;
  String title;
  String htmlContent;
  bool done;

  Exercise(this.uid, this.parentLesson, this.type, this.date, this.title,
      this.htmlContent, this.done,
      [this.lessonFor, this.dateFor]);

  static Exercise _parse(Map<String, Object?> result) {
    return Exercise(
        result['UID'] as int,
        result['ParentLesson'] as int,
        result['Type'] as String == 'Cours'
            ? ExerciseType.lessonContent
            : ExerciseType.workToDo,
        DateTime.fromMillisecondsSinceEpoch(result['ParentDate'] as int),
        result['Title'] as String,
        result['HTMLContent'] as String,
        result['Done'] == 1 ? true : false,
        result['LessonFor'] as int,
        DateTime.fromMillisecondsSinceEpoch(result['DateFor'] as int));
  }

  static Future<List<Exercise>> fromParentLesson(
      int parentLesson, Database db) async {
    final List<Exercise> exercises = [];
    final results = await db.query('Exercises',
        where: 'ParentLesson = ?', whereArgs: [parentLesson]);
    for (final result in results) {
      exercises.add(_parse(result));
    }
    return exercises;
  }

  static Future<List<Exercise>> fetchAll(Database db) async {
    final List<Exercise> exercises = [];
    final results = await db.query('Exercises');
    for (final result in results) {
      exercises.add(_parse(result));
    }
    return exercises;
  }
}
