import 'package:kosmos_client/kdecole-api/exercise.dart';
import 'package:sqflite/sqflite.dart';

class Lesson {
  int id;
  DateTime date;
  String startTime;
  String endTime;
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
