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

import 'package:flutter/material.dart';
import 'package:klient/api/news_article.dart';
import 'package:klient/screens/article.dart';
import 'package:klient/util.dart';
import 'package:morpheus/morpheus.dart';

class ArticleCard extends StatelessWidget {
  final NewsArticle _article;
  final GlobalKey _key = GlobalKey();
  ArticleCard(this._article, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: _key,
      margin: const EdgeInsets.all(8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (() {
          Navigator.of(context)
              .push(MorpheusPageRoute(builder: (_) => ArticlePage(_article), parentKey: _key));
        }),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _article.author,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(Util.dateToString(_article.date))
                ],
              ),
              Text(
                _article.title,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
