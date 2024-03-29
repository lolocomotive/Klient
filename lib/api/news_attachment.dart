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

import 'package:klient/api/attachment.dart';
import 'package:klient/api/news_article.dart';

/// An attachment that is linked to a [NewsArticle] (only it's uid to avoid circular references though)
class NewsAttachment extends Attachment {
  /// The UID of the corresponding [NewsArticle]
  String parentUID;
  @override
  String name;

  NewsAttachment(this.parentUID, this.name);

  /// Get the attachments of a specific [NewsArticle]
  static NewsAttachment parse(Map<String, dynamic> result) {
    return (NewsAttachment(result['ParentUID'], result['Name'] as String));
  }
}
