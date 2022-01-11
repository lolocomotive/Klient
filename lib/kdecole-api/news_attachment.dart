import 'package:sqflite/sqflite.dart';

class NewsAttachment {
  String parentUID;
  String name;

  NewsAttachment(this.parentUID, this.name);

  static Future<List<NewsAttachment>> fromParentUID(
      String parentUID, Database db) async {
    final List<NewsAttachment> attachments = [];
    final results = await db.query('NewsAttachments',
        where: 'ParentUID = ?', whereArgs: [parentUID]);
    for (final result in results) {
      attachments.add(NewsAttachment(parentUID, result['Name'] as String));
    }
    return attachments;
  }
}
