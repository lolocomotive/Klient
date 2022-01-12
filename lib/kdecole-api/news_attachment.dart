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

import 'package:kosmos_client/kdecole-api/news_article.dart';
import 'package:sqflite/sqflite.dart';

/// An attachment that is linked to a [NewsArticle] (only it's uid to avoid circular references though)
class NewsAttachment {
  /// The UID of the corresponding [NewsArticle]
  String parentUID;
  String name;

  NewsAttachment(this.parentUID, this.name);

  /// Get the attachments of a specific [NewsArticle]
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
