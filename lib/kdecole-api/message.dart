import 'package:sqflite/sqflite.dart';

import 'message_attachment.dart';

class Message {
  int id;
  int parentID;
  String htmlContent;
  String author;
  List<MessageAttachment> attachments;

  Message(
      this.id, this.parentID, this.htmlContent, this.author, this.attachments);

  static Future<List<Message>> fromConversationID(
      int conversationID, Database db) async {
    final List<Message> messages = [];
    final results = await db
        .query('Messages', where: 'ParentID = ?', whereArgs: [conversationID]);
    for (final result in results) {
      messages.add(Message(
          result['ID'] as int,
          conversationID,
          result['HTMLContent'] as String,
          result['author'] as String,
          await MessageAttachment.fromMessageID(result['ID'] as int, db)));
    }
    return messages;
  }
}
