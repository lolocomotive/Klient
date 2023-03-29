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
import 'package:flutter_html/flutter_html.dart';
import 'package:klient/api/news_article.dart';
import 'package:klient/widgets/attachments_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticlePage extends StatelessWidget {
  const ArticlePage(this._article, {Key? key}) : super(key: key);
  final NewsArticle _article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(_article.title),
              floating: true,
              forceElevated: innerBoxIsScrolled,
            )
          ];
        },
        body: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_article.attachments.isNotEmpty)
                  AttachmentsWidget(
                    attachments: _article.attachments,
                  ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse(_article.url), mode: LaunchMode.externalApplication);
                    },
                    child: Text(
                      'Consulter dans l\'ENT',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Html(
                    data: _article.htmlContent,
                    onLinkTap: (url, context, map, element) {
                      launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
