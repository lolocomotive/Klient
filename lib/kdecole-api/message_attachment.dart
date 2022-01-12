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

import 'package:kosmos_client/kdecole-api/message.dart';
import 'package:sqflite/sqflite.dart';
/// An attachment that is linked to a [Message] (only it's id to avoid circular
/// references though)
class MessageAttachment {
  int id;
  /// The ID of the [Message] this attachment belongs to
  int parentID;
  /// Normally the URL you would download the attachment app, but null is always
  /// provided by the API so we have to redirect the user to a web browser for
  /// him to be able to download the attachment
  String url;
  String name;

  MessageAttachment(this.id, this.parentID, this.url, this.name);

  /// Get the attachments of a specific [Message]
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
