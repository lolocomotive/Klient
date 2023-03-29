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

import 'package:klient/api/client.dart';
import 'package:klient/database_provider.dart';

import 'news_attachment.dart';

class NewsArticle {
  String uid;
  String type;
  String author;
  String title;
  DateTime date;
  String htmlContent;
  String url;
  List<NewsAttachment> attachments;

  NewsArticle(this.uid, this.type, this.author, this.title, this.date, this.htmlContent, this.url,
      this.attachments);

  static Future<List<NewsArticle>> fetchAll() async {
    final List<NewsArticle> articles = [];
    final results = await (await DatabaseProvider.getDB()).rawQuery('''SELECT 
          NewsArticles.UID as NewsArticleUID,
          NewsAttachments.ID AS NewsAttachmentID,
          * FROM NewsArticles 
          LEFT JOIN NewsAttachments ON NewsArticles.UID = NewsAttachments.ParentUID
          Where NewsArticles.StudentUID = '${Client.currentlySelected!.uid}'
          AND (NewsAttachments.StudentUID = '${Client.currentlySelected!.uid}' OR NewsAttachments.StudentUID IS Null);''');
    NewsArticle? article;
    for (final result in results) {
      if (article == null || result['NewsArticleUID'] != article.uid) {
        article = NewsArticle(
          result['NewsArticleUID'] as String,
          result['Type'] as String,
          result['Author'] as String,
          result['Title'] as String,
          DateTime.fromMillisecondsSinceEpoch((result['PublishingDate'] as int)),
          result['HTMLContent'] as String,
          result['URL'] as String,
          [],
        );
        articles.add(article);
      }
      if (result['NewsAttachmentID'] != null) {
        article.attachments.add(NewsAttachment.parse(result));
      }
    }

    return articles;
  }
}
