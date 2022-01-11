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
