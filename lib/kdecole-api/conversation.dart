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
