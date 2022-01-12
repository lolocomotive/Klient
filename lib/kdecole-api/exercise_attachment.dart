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

import 'package:kosmos_client/kdecole-api/exercise.dart';
import 'package:sqflite/sqflite.dart';
/// An attachment that is linked to a [Exercise] (only it's id to avoid circular
/// references though)
class ExerciseAttachment {
  int id;
  /// The ID of the [Exercise] this attachment belongs to
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
