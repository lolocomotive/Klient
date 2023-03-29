/*
 * This file is part of the Klient (https://github.com/lolocomotive/klient)
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

import 'package:klient/api/conversation.dart';

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

  Message(this.id, this.parentID, this.htmlContent, this.author, this.date, this.attachments);

  static Message parse(Map<String, dynamic> result) {
    return Message(
      result['MessageID'] as int? ?? result['ID'] as int,
      result['MessageParentID'] as int? ?? result['ParentID'] as int,
      result['HTMLContent'] as String,
      result['Author'] as String,
      DateTime.fromMillisecondsSinceEpoch(result['DateSent'] as int),
      [],
    );
  }
}
