import 'package:sqflite/sqflite.dart';

class MessageAttachment {
  int id;
  int parentID;
  String url;
  String name;

  MessageAttachment(this.id, this.parentID, this.url, this.name);

  static Future<List<MessageAttachment>> fromMessageID(
      int messageID, Database db) async {
    final List<MessageAttachment> attachments = [];
    final results = await db.query('MessageAttachments',
        where: 'ParentID = ?', whereArgs: [messageID]);
    for (final result in results) {
      attachments.add(MessageAttachment(result['ID'] as int, messageID,
          result['URL'] as String, result['Name'] as String));
    }
    return attachments;
  }
}
