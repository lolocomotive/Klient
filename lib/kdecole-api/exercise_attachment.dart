import 'package:sqflite/sqflite.dart';

class ExerciseAttachment {
  int id;
  int parentID;
  String url;
  String name;

  ExerciseAttachment(this.id, this.parentID, this.url, this.name);

  static Future<List<ExerciseAttachment>> fromMessageID(
      int messageID, Database db) async {
    final List<ExerciseAttachment> attachments = [];
    final results = await db.query('MessageAttachments',
        where: 'ParentID = ?', whereArgs: [messageID]);
    for (final result in results) {
      attachments.add(ExerciseAttachment(result['ID'] as int, messageID,
          result['URL'] as String, result['Name'] as String));
    }
    return attachments;
  }
}
