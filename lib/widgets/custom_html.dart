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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomHtml extends StatelessWidget {
  final String data;
  final Map<String, Style> style;
  final Map<String, Style> defaultStyle = {};

  CustomHtml({
    Key? key,
    required this.data,
    this.style = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Html(
      data: data.replaceAll(
          RegExp(r'<p[^>]*>\s*<\/p>|<head>[\s\S]*?<\/head>', caseSensitive: false, multiLine: true),
          ''),
      // Remove empty paragraphs and head tag
      // Empty paragraphs take up too much space.
      // Head tag is removed as a workaround for https://github.com/Sub6Resources/flutter_html/issues/1227
      style: defaultStyle..addAll(style),
      onLinkTap: (url, context, attributes, element) {
        launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
      },
      customRenders: {
        networkImageMatcher(): CustomRender.widget(
            widget: (context, buildChildren) => CachedNetworkImage(
                  imageUrl: context.tree.element!.attributes['src']!,
                  progressIndicatorBuilder: (context, url, progress) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator(value: progress.progress)),
                  ),
                ))
      },
    );
  }

  CustomRenderMatcher networkImageMatcher() => (context) =>
      context.tree.element?.localName == 'img' &&
      context.tree.element?.attributes.containsKey('src') == true;
}
