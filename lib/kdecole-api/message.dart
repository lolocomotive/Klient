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

import 'package:kosmos_client/global.dart';
import 'package:kosmos_client/kdecole-api/conversation.dart';

import 'message_attachment.dart';

/// An message that is linked to a [Conversation] (only it's id to avoid circular
/// references though)
class Message {
  int id;

  /// The ID of the corresponding conversation
  int parentID;
  String htmlContent;
  String author;
  DateTime date;
  List<MessageAttachment> attachments;

  Message(this.id, this.parentID, this.htmlContent, this.author, this.date,
      this.attachments);

  /// Get the messages of a specific [Conversation]
  static Future<List<Message>> fromConversationID(int conversationID) async {
    final List<Message> messages = [];
    final results =
        await Global.db!.query('Messages', where: 'ParentID = $conversationID');
    for (final result in results) {
      messages.add(
        Message(
          result['ID'] as int,
          conversationID,
          result['HTMLContent'] as String,
          result['Author'] as String,
          DateTime.fromMillisecondsSinceEpoch(result['DateSent'] as int),
          await MessageAttachment.fromMessageID(conversationID),
        ),
      );
    }
    return messages;
  }
}
