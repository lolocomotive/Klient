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
