import 'package:sqflite/sqflite.dart';

import 'message.dart';

class Conversation {
  int id;
  String subject;
  String preview;
  bool hasAttachment;
  DateTime lastDate;
  List<Message> messages;

  Conversation(this.id, this.subject, this.preview, this.hasAttachment,
      this.lastDate, this.messages);

  static Future<List<Conversation>> fetchAll(Database db,
      {int? offset, int? limit, getMessages = false}) async {
    final List<Conversation> conversations = [];
    final results =
        await db.query('Conversation', limit: limit, offset: offset);
    for (final result in results) {
      List<Message> messages = [];
      if (getMessages) {
        messages = await Message.fromConversationID(result['ID'] as int, db);
      }
      conversations.add(Conversation(
          result['ID'] as int,
          result['Subject'] as String,
          result['Preview'] as String,
          result['HasAttachment'] as bool,
          DateTime.fromMillisecondsSinceEpoch(
              (result['LastDate'] as int)),
          messages));
    }
    return conversations;
  }
}
