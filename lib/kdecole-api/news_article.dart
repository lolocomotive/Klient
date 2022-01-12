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

import 'dart:io';

import 'package:sqflite/sqflite.dart';

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

  NewsArticle(this.uid, this.type, this.author, this.title, this.date,
      this.htmlContent, this.url, this.attachments);

  static Future<List<NewsArticle>> fetchAll(Database db) async {
    final List<NewsArticle> articles = [];
    final results = await db.query('NewsArticles');
    for (final result in results) {
      articles.add(NewsArticle(
        result['UID'] as String,
        result['Type'] as String,
        result['Author'] as String,
        result['Title'] as String,
        DateTime.fromMillisecondsSinceEpoch(
            (result['PublishingDate'] as int)),
        result['HTMLContent'] as String,
        result['URL'] as String,
        await NewsAttachment.fromParentUID(result['UID'] as String, db),
      ));
    }
    return articles;
  }
}
